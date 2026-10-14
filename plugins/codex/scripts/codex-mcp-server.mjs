#!/usr/bin/env node
// MCP stdio server that exposes `codex` and `codex-reply` tools backed by
// `codex exec --json` and `codex exec resume`. Replaces `codex mcp-server`,
// which Codex CLI removed in 0.154.0. No dependencies; requires Node >= 18.

import { spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";
import { fileURLToPath } from "node:url";

const SERVER_NAME = "codex-exec-mcp";
const SERVER_VERSION = "1.7.0";
const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const NAMED_SCHEMAS = {
  review: path.join(SCRIPT_DIR, "..", "schemas", "review-output.schema.json"),
};
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const CONFIG_KEY_RE = /^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)*$/;
const UNSUPPORTED_PARAMS = ["base-instructions", "developer-instructions", "compact-prompt"];
const MAX_THREAD_RECORDS = 200;
const STDERR_TAIL_LINES = 20;
const KILL_GRACE_MS = 5000;
// Newest first. A client asking for an unlisted version gets the newest one.
const SUPPORTED_PROTOCOL_VERSIONS = ["2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05"];

export const TOOLS = [
  {
    name: "codex",
    description:
      "Start a new Codex thread (runs `codex exec` in a read-only sandbox). Returns Codex's final message and a threadId for codex-reply.",
    inputSchema: {
      type: "object",
      properties: {
        prompt: { type: "string", description: "The task or question for Codex." },
        model: {
          type: "string",
          description: "Model slug, e.g. gpt-6.1-sol or gpt-6-luna. Omit to use ~/.codex/config.toml.",
        },
        sandbox: {
          type: "string",
          enum: ["read-only"],
          description: "Sandbox mode. Only read-only is allowed.",
        },
        config: {
          type: "object",
          description:
            'Codex config overrides as dotted keys with string, number, or boolean values, e.g. {"model_reasoning_effort": "medium"}.',
          additionalProperties: { type: ["string", "number", "boolean"] },
        },
        cwd: { type: "string", description: "Working directory for Codex. Defaults to the project directory." },
        profile: { type: "string", description: "Codex config profile name (passed as -p)." },
        outputSchema: {
          description:
            'JSON Schema for the final response. Pass "review" for the bundled review-output schema, or an inline schema object.',
          anyOf: [{ type: "string", enum: Object.keys(NAMED_SCHEMAS) }, { type: "object" }],
        },
        "approval-policy": {
          type: "string",
          description: "Accepted for compatibility and ignored; codex exec never asks for approval.",
        },
      },
      required: ["prompt"],
    },
  },
  {
    name: "codex-reply",
    description:
      "Continue an existing Codex thread. Pass the threadId from a prior codex or codex-reply result as the threadId argument, not inside the prompt. Reuses that thread's model, reasoning effort, and working directory unless model/config are given; an override applies to this reply and later ones.",
    inputSchema: {
      type: "object",
      properties: {
        threadId: { type: "string", description: "Thread id (UUID) returned by a prior call." },
        prompt: { type: "string", description: "Follow-up prompt. Do not include the thread id here." },
        model: {
          type: "string",
          description:
            "Optional. Switch the thread to this model for this and later replies, e.g. escalate to gpt-6-astra. The thread keeps its history.",
        },
        config: {
          type: "object",
          description:
            'Optional config overrides merged over the thread\'s stored config, e.g. {"model_reasoning_effort": "medium"}. Kept for later replies.',
          additionalProperties: { type: ["string", "number", "boolean"] },
        },
        conversationId: { type: "string", description: "Deprecated alias for threadId." },
      },
      required: ["prompt"],
    },
  },
];

// ---------- pure helpers (exported for tests) ----------

export function encodeTomlValue(key, value) {
  if (typeof value === "string") return JSON.stringify(value);
  if (typeof value === "boolean") return String(value);
  if (typeof value === "number" && Number.isFinite(value)) return String(value);
  throw new ToolError(`config.${key}: only string, number, and boolean values are supported`);
}

export function configArgs(config) {
  if (config == null) return [];
  if (typeof config !== "object" || Array.isArray(config)) {
    throw new ToolError("config must be an object of dotted keys to values");
  }
  const args = [];
  for (const [key, value] of Object.entries(config)) {
    if (!CONFIG_KEY_RE.test(key)) throw new ToolError(`config key is not a valid dotted path: ${key}`);
    args.push("-c", `${key}=${encodeTomlValue(key, value)}`);
  }
  return args;
}

// Builds argv for `codex exec`. `-s` and `-C` are exec-level options, so they
// must come before `resume`. The prompt is read from stdin (`-`).
export function buildExecArgs({ cwd, model, config, profile, outputSchemaFile, resumeThreadId }) {
  const args = ["exec", "--json", "--skip-git-repo-check", "-s", "read-only", "-C", cwd];
  if (model) args.push("-m", model);
  if (profile) args.push("-p", profile);
  args.push(...configArgs(config));
  if (outputSchemaFile) args.push("--output-schema", outputSchemaFile);
  if (resumeThreadId) args.push("resume", resumeThreadId);
  args.push("-");
  return args;
}

// Folds `codex exec --json` events into a result. Returns a progress message
// for events worth reporting, or null.
export function applyEvent(state, event) {
  switch (event?.type) {
    case "thread.started":
      state.threadId = event.thread_id ?? state.threadId;
      return "thread started";
    case "item.started":
      if (event.item?.type === "command_execution") return `running: ${event.item.command}`;
      return null;
    case "item.completed": {
      const item = event.item ?? {};
      if (item.type === "agent_message" && typeof item.text === "string") {
        state.finalMessage = item.text;
        return "message received";
      }
      if (item.type === "error" && item.message) state.warnings.push(item.message);
      return null;
    }
    case "turn.completed":
      state.completed = true;
      state.usage = event.usage ?? null;
      return null;
    case "turn.failed":
      state.errors.push(event.error?.message ?? "turn failed");
      state.finalMessage = null;
      return null;
    case "error":
      state.errors.push(event.message ?? "error");
      return null;
    default:
      return null;
  }
}

export function newRunState() {
  return { threadId: null, finalMessage: null, completed: false, usage: null, errors: [], warnings: [] };
}

class ToolError extends Error {}

// ---------- thread records ----------

// One file per thread, so concurrent sessions never overwrite each other's
// records. Files are written to a temp path and renamed into place.
class ThreadStore {
  constructor(dir) {
    this.dir = dir;
  }

  fileFor(threadId) {
    return path.join(this.dir, `${threadId}.json`);
  }

  get(threadId) {
    try {
      return JSON.parse(fs.readFileSync(this.fileFor(threadId), "utf8"));
    } catch {
      return null;
    }
  }

  set(threadId, record) {
    const file = this.fileFor(threadId);
    const tmp = `${file}.${process.pid}.${randomUUID()}.tmp`;
    try {
      fs.mkdirSync(this.dir, { recursive: true });
      fs.writeFileSync(tmp, JSON.stringify(record));
      fs.renameSync(tmp, file);
      this.prune();
    } catch (err) {
      fs.rmSync(tmp, { force: true });
      log(`could not save thread record: ${err.message}`);
    }
  }

  // Keep the newest MAX_THREAD_RECORDS records.
  prune() {
    const entries = fs
      .readdirSync(this.dir)
      .filter((name) => name.endsWith(".json"))
      .map((name) => ({ name, mtime: fs.statSync(path.join(this.dir, name)).mtimeMs }));
    if (entries.length <= MAX_THREAD_RECORDS) return;
    entries
      .sort((a, b) => a.mtime - b.mtime)
      .slice(0, entries.length - MAX_THREAD_RECORDS)
      .forEach(({ name }) => fs.rmSync(path.join(this.dir, name), { force: true }));
  }
}

// ---------- server ----------

function log(message) {
  process.stderr.write(`[${SERVER_NAME}] ${message}\n`);
}

function send(message) {
  process.stdout.write(`${JSON.stringify({ jsonrpc: "2.0", ...message })}\n`);
}

function textResult(text, { isError = false } = {}) {
  const result = { content: [{ type: "text", text }] };
  if (isError) result.isError = true;
  return result;
}

function resolveOutputSchema(outputSchema) {
  if (outputSchema == null) return { file: null, cleanup: () => {} };
  if (typeof outputSchema === "string") {
    const file = NAMED_SCHEMAS[outputSchema];
    if (!file) throw new ToolError(`unknown outputSchema name: ${outputSchema}`);
    return { file, cleanup: () => {} };
  }
  if (typeof outputSchema !== "object" || Array.isArray(outputSchema)) {
    throw new ToolError("outputSchema must be a schema name or a JSON Schema object");
  }
  const file = path.join(os.tmpdir(), `codex-output-schema-${randomUUID()}.json`);
  fs.writeFileSync(file, JSON.stringify(outputSchema));
  return { file, cleanup: () => fs.rmSync(file, { force: true }) };
}

function runCodex({ args, prompt, cwd, progress, registerCancel }) {
  return new Promise((resolve) => {
    const state = newRunState();
    const stderrTail = [];
    let child;
    try {
      child = spawn(process.env.CODEX_BIN || "codex", args, {
        cwd,
        env: { ...process.env, CMUX_CODEX_HOOKS_DISABLED: "1" },
        stdio: ["pipe", "pipe", "pipe"],
      });
    } catch (err) {
      resolve({ state, spawnError: err, stderrTail, exitCode: null });
      return;
    }

    let killTimer = null;
    registerCancel(() => {
      child.kill("SIGINT");
      killTimer = setTimeout(() => child.kill("SIGKILL"), KILL_GRACE_MS);
    });

    child.stdin.on("error", () => {});
    child.stdin.end(prompt);

    readline.createInterface({ input: child.stdout }).on("line", (line) => {
      if (!line.trim()) return;
      let event;
      try {
        event = JSON.parse(line);
      } catch {
        return;
      }
      const message = applyEvent(state, event);
      if (message) progress(message);
    });
    readline.createInterface({ input: child.stderr }).on("line", (line) => {
      stderrTail.push(line);
      if (stderrTail.length > STDERR_TAIL_LINES) stderrTail.shift();
    });

    let spawnError = null;
    child.on("error", (err) => {
      spawnError = err;
    });
    child.on("close", (exitCode, signal) => {
      clearTimeout(killTimer);
      resolve({ state, spawnError, stderrTail, exitCode, signal });
    });
  });
}

function formatFailure({ state, spawnError, stderrTail, exitCode, signal }) {
  if (spawnError?.code === "ENOENT") {
    return [
      "Codex CLI not found on PATH (set CODEX_BIN to override).",
      "Install: npm install -g @openai/codex   (or: brew install --cask codex)",
      "Then authenticate: codex login",
    ].join("\n");
  }
  const lines = ["Codex run failed."];
  if (spawnError) lines.push(`spawn error: ${spawnError.message}`);
  for (const err of state.errors) lines.push(`error: ${err}`);
  if (signal) lines.push(`terminated by ${signal}`);
  else if (exitCode !== 0 && exitCode != null) lines.push(`exit code: ${exitCode}`);
  if (!state.errors.length && exitCode === 0) lines.push("Codex returned no final message.");
  const tail = stderrTail.filter((l) => !l.includes("could not create PATH aliases"));
  if (tail.length) lines.push("", "stderr (last lines):", ...tail);
  if (state.threadId) lines.push("", `threadId: ${state.threadId}`);
  return lines.join("\n");
}

export function createServer({ threadStoreDir, defaultCwd = process.cwd() } = {}) {
  const store = new ThreadStore(
    threadStoreDir ?? path.join(process.env.CLAUDE_PLUGIN_DATA || os.tmpdir(), "codex-threads"),
  );
  const cancelers = new Map();
  const inFlight = new Set();
  const cancelled = new Set();
  // threadId -> promise. Runs replies to one thread in order within this process;
  // replies from separate Claude sessions to the same thread are not ordered.
  const threadQueues = new Map();

  async function callTool(name, args, { requestId, progressToken }) {
    args = args ?? {};
    if (typeof args.prompt !== "string" || !args.prompt.trim()) throw new ToolError("prompt is required");

    let progressCount = 0;
    const progress = (message) => {
      if (progressToken === undefined) return;
      progressCount += 1;
      send({ method: "notifications/progress", params: { progressToken, progress: progressCount, message } });
    };

    let run;
    let schema = { file: null, cleanup: () => {} };
    if (name === "codex") {
      for (const param of UNSUPPORTED_PARAMS) {
        if (args[param] != null) throw new ToolError(`${param} is not supported by the codex exec backend`);
      }
      if (args.sandbox != null && args.sandbox !== "read-only") {
        throw new ToolError(`sandbox "${args.sandbox}" is not allowed; this plugin only runs Codex read-only`);
      }
      configArgs(args.config); // validate before spawning
      run = {
        cwd: args.cwd || defaultCwd,
        model: args.model || null,
        config: args.config ?? null,
        profile: args.profile || null,
      };
      schema = resolveOutputSchema(args.outputSchema);
    } else if (name === "codex-reply") {
      const threadId = args.threadId ?? args.conversationId;
      if (typeof threadId !== "string" || !UUID_RE.test(threadId)) {
        throw new ToolError(
          "threadId must be the UUID returned by a prior codex call, passed as the threadId argument (not inside the prompt)",
        );
      }
      configArgs(args.config); // validate before spawning
      const record = store.get(threadId) ?? {};
      const config = args.config != null ? { ...(record.config ?? {}), ...args.config } : record.config;
      run = {
        cwd: record.cwd || defaultCwd,
        model: args.model || record.model || null,
        config: config ?? null,
        profile: record.profile || null,
        resumeThreadId: threadId,
      };
    } else {
      throw new ToolError(`unknown tool: ${name}`);
    }

    const execute = () =>
      runCodex({
        args: buildExecArgs({ ...run, outputSchemaFile: schema.file }),
        prompt: args.prompt,
        cwd: run.cwd,
        progress,
        registerCancel: (fn) => cancelers.set(requestId, fn),
      });

    try {
      let outcome;
      if (run.resumeThreadId) {
        const previous = threadQueues.get(run.resumeThreadId) ?? Promise.resolve();
        const current = previous.then(() => (cancelled.has(requestId) ? null : execute()));
        const tail = current.catch(() => {});
        threadQueues.set(run.resumeThreadId, tail);
        outcome = await current;
        if (threadQueues.get(run.resumeThreadId) === tail) threadQueues.delete(run.resumeThreadId);
        if (!outcome) return null; // cancelled while waiting
      } else {
        outcome = await execute();
      }
      const threadId = outcome.state.threadId ?? run.resumeThreadId ?? null;
      if (threadId) {
        store.set(threadId, { cwd: run.cwd, model: run.model, config: run.config, profile: run.profile });
      }
      const ok = !outcome.spawnError && outcome.exitCode === 0 && !outcome.state.errors.length;
      if (!ok || outcome.state.finalMessage == null) {
        return textResult(formatFailure(outcome), { isError: true });
      }
      const message = outcome.state.finalMessage;
      if (!threadId) return textResult(message);
      // threadId goes in the text too, since not every client shows structuredContent.
      const result = textResult(`${message}\n\nthreadId: ${threadId}`);
      result.structuredContent = { threadId, content: message };
      return result;
    } finally {
      cancelers.delete(requestId);
      schema.cleanup();
    }
  }

  async function handle(message) {
    const { id, method, params } = message;
    const isRequest = id !== undefined && id !== null;

    if (method === "initialize") {
      const requested = params?.protocolVersion;
      send({
        id,
        result: {
          protocolVersion: SUPPORTED_PROTOCOL_VERSIONS.includes(requested)
            ? requested
            : SUPPORTED_PROTOCOL_VERSIONS[0],
          capabilities: { tools: {} },
          serverInfo: { name: SERVER_NAME, version: SERVER_VERSION },
        },
      });
      return;
    }
    if (method === "notifications/cancelled") {
      if (!inFlight.has(params?.requestId)) return;
      cancelled.add(params?.requestId);
      cancelers.get(params?.requestId)?.();
      return;
    }
    if (!isRequest) return; // other notifications, e.g. notifications/initialized
    if (method === "ping") {
      send({ id, result: {} });
      return;
    }
    if (method === "tools/list") {
      send({ id, result: { tools: TOOLS } });
      return;
    }
    if (method === "tools/call") {
      let result;
      inFlight.add(id);
      try {
        result = await callTool(params?.name, params?.arguments, {
          requestId: id,
          progressToken: params?._meta?.progressToken,
        });
      } catch (err) {
        if (!(err instanceof ToolError)) log(err.stack ?? String(err));
        result = textResult(err.message, { isError: true });
      } finally {
        inFlight.delete(id);
      }
      // The MCP spec says not to respond to a cancelled request.
      if (cancelled.delete(id) || result === null) return;
      send({ id, result });
      return;
    }
    send({ id, error: { code: -32601, message: `Method not found: ${method}` } });
  }

  return { handle };
}

function main() {
  const server = createServer();
  const rl = readline.createInterface({ input: process.stdin });
  const pending = new Set();
  rl.on("line", (line) => {
    if (!line.trim()) return;
    let message;
    try {
      message = JSON.parse(line);
    } catch {
      send({ id: null, error: { code: -32700, message: "Parse error" } });
      return;
    }
    const task = server.handle(message).catch((err) => log(err.stack ?? String(err)));
    pending.add(task);
    task.finally(() => pending.delete(task));
  });
  // Let in-flight tool calls finish after the client closes stdin.
  rl.on("close", () => Promise.allSettled([...pending]).then(() => process.exit(0)));
}

function isMainModule() {
  try {
    return fs.realpathSync(process.argv[1]) === fs.realpathSync(fileURLToPath(import.meta.url));
  } catch {
    return false;
  }
}

if (isMainModule()) {
  main();
}
