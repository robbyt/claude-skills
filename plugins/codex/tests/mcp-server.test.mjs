// Tests for scripts/codex-mcp-server.mjs. Run: node --test tests/
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import readline from "node:readline";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { applyEvent, buildExecArgs, configArgs, encodeTomlValue, newRunState } from "../scripts/codex-mcp-server.mjs";

const TESTS_DIR = path.dirname(fileURLToPath(import.meta.url));
const SERVER = path.join(TESTS_DIR, "..", "scripts", "codex-mcp-server.mjs");
const FAKE_CODEX = path.join(TESTS_DIR, "fake-codex.mjs");
const SCHEMA = path.resolve(TESTS_DIR, "..", "schemas", "review-output.schema.json");
const THREAD_ID = "11111111-2222-3333-4444-555555555555";

// Starts the server with the fake codex and returns a small JSON-RPC client.
function startServer(env = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "codex-mcp-test-"));
  const log = path.join(dir, "codex.log");
  const child = spawn(process.execPath, [SERVER], {
    cwd: dir,
    env: { ...process.env, CODEX_BIN: FAKE_CODEX, FAKE_CODEX_LOG: log, CLAUDE_PLUGIN_DATA: dir, ...env },
    stdio: ["pipe", "pipe", "inherit"],
  });
  const waiters = new Map();
  const notifications = [];
  readline.createInterface({ input: child.stdout }).on("line", (line) => {
    const msg = JSON.parse(line);
    if (msg.id != null && waiters.has(msg.id)) {
      waiters.get(msg.id)(msg);
      waiters.delete(msg.id);
    } else {
      notifications.push(msg);
    }
  });
  let nextId = 1;
  const write = (message) => child.stdin.write(`${JSON.stringify({ jsonrpc: "2.0", ...message })}\n`);
  const request = (method, params, id = nextId++) =>
    new Promise((resolve) => {
      waiters.set(id, resolve);
      write({ id, method, params });
    });
  const call = async (name, args, meta) =>
    (await request("tools/call", { name, arguments: args, ...(meta ? { _meta: meta } : {}) })).result;
  const calls = () =>
    fs.existsSync(log)
      ? fs.readFileSync(log, "utf8").trim().split("\n").map((l) => JSON.parse(l))
      : [];
  const doneTimes = () => {
    const file = log.replace(/\.log$/, ".done.log");
    return fs.existsSync(file) ? fs.readFileSync(file, "utf8").trim().split("\n").map(Number) : [];
  };
  const stop = () => {
    child.stdin.end();
    fs.rmSync(dir, { recursive: true, force: true });
  };
  return { dir, write, request, call, calls, doneTimes, notifications, waiters, stop };
}

test("encodeTomlValue quotes strings and passes scalars", () => {
  assert.equal(encodeTomlValue("k", "medium"), '"medium"');
  assert.equal(encodeTomlValue("k", 'a"b\nc'), '"a\\"b\\nc"');
  assert.equal(encodeTomlValue("k", true), "true");
  assert.equal(encodeTomlValue("k", 3), "3");
  assert.throws(() => encodeTomlValue("k", [1]), /only string, number, and boolean/);
  assert.throws(() => encodeTomlValue("k", Infinity), /only string/);
});

test("configArgs validates keys", () => {
  assert.deepEqual(configArgs({ model_reasoning_effort: "low", "a.b": 1 }), [
    "-c",
    'model_reasoning_effort="low"',
    "-c",
    "a.b=1",
  ]);
  assert.throws(() => configArgs({ "bad key": 1 }), /not a valid dotted path/);
  assert.throws(() => configArgs([1]), /must be an object/);
});

test("buildExecArgs puts exec options before resume and reads the prompt from stdin", () => {
  const args = buildExecArgs({ cwd: "/repo", model: "m", config: { x: "y" }, resumeThreadId: THREAD_ID });
  assert.deepEqual(args, [
    "exec", "--json", "--skip-git-repo-check", "-s", "read-only", "-C", "/repo",
    "-m", "m", "-c", 'x="y"', "resume", THREAD_ID, "-",
  ]);
});

test("applyEvent keeps the last agent message and clears it on turn.failed", () => {
  const state = newRunState();
  applyEvent(state, { type: "thread.started", thread_id: "t" });
  applyEvent(state, { type: "item.completed", item: { type: "agent_message", text: "a" } });
  applyEvent(state, { type: "item.completed", item: { type: "agent_message", text: "b" } });
  assert.equal(state.threadId, "t");
  assert.equal(state.finalMessage, "b");
  applyEvent(state, { type: "turn.failed", error: { message: "boom" } });
  assert.equal(state.finalMessage, null);
  assert.deepEqual(state.errors, ["boom"]);
});

test("initialize and tools/list", async (t) => {
  const s = startServer();
  t.after(s.stop);
  const init = await s.request("initialize", { protocolVersion: "2025-06-18", capabilities: {} });
  assert.equal(init.result.protocolVersion, "2025-06-18");
  const list = await s.request("tools/list", {});
  assert.deepEqual(list.result.tools.map((tool) => tool.name), ["codex", "codex-reply"]);
  const unknown = await s.request("resources/list", {});
  assert.equal(unknown.error.code, -32601);
});

test("initialize negotiates the protocol version", async (t) => {
  const s = startServer();
  t.after(s.stop);
  const known = await s.request("initialize", { protocolVersion: "2025-03-26", capabilities: {} });
  assert.equal(known.result.protocolVersion, "2025-03-26");
  const future = await s.request("initialize", { protocolVersion: "2099-01-01", capabilities: {} });
  assert.equal(future.result.protocolVersion, "2025-11-25");
});

test("a cancelled call interrupts codex and gets no response", async (t) => {
  const s = startServer({ FAKE_CODEX_MODE: "slow", FAKE_CODEX_DELAY_MS: "5000" });
  t.after(s.stop);
  s.waiters.set(7, () => assert.fail("cancelled request must not get a response"));
  s.write({ id: 7, method: "tools/call", params: { name: "codex", arguments: { prompt: "x" } } });
  await new Promise((r) => setTimeout(r, 300));
  s.write({ method: "notifications/cancelled", params: { requestId: 7 } });
  // The server still answers later requests, and never answers request 7.
  await new Promise((r) => setTimeout(r, 500));
  const ping = await s.request("ping", {});
  assert.deepEqual(ping.result, {});
  assert.equal(s.doneTimes().length, 0);
  assert.ok(fs.existsSync(path.join(s.dir, "codex.sigint")), "codex should receive SIGINT");
  s.waiters.delete(7);
});

test("concurrent replies to one thread run one after another", async (t) => {
  const s = startServer({ FAKE_CODEX_MODE: "slow", FAKE_CODEX_DELAY_MS: "300" });
  t.after(s.stop);
  const [a, b] = await Promise.all([
    s.call("codex-reply", { threadId: THREAD_ID, prompt: "first" }),
    s.call("codex-reply", { threadId: THREAD_ID, prompt: "second" }),
  ]);
  assert.equal(a.structuredContent.content, "echo: first");
  assert.equal(b.structuredContent.content, "echo: second");
  const [, second] = s.calls();
  const [firstDone] = s.doneTimes();
  assert.ok(second.startedAt >= firstDone, "second resume must start after the first finished");
});

test("codex runs exec read-only with model and effort, then codex-reply reuses them", async (t) => {
  const s = startServer();
  t.after(s.stop);
  const first = await s.call(
    "codex",
    { prompt: "review this", model: "gpt-6-sol", config: { model_reasoning_effort: "medium" } },
    { progressToken: "tok" },
  );
  assert.equal(first.isError, undefined);
  assert.equal(first.structuredContent.threadId, THREAD_ID);
  assert.equal(first.structuredContent.content, "echo: review this");
  assert.equal(first.content[0].text, `echo: review this\n\nthreadId: ${THREAD_ID}`);
  assert.ok(s.notifications.some((n) => n.method === "notifications/progress" && n.params.message === "running: ls"));

  const reply = await s.call("codex-reply", { threadId: THREAD_ID, prompt: "and now?" });
  assert.equal(reply.structuredContent.content, "echo: and now?");

  const [open, resume] = s.calls();
  assert.equal(open.stdin, "review this");
  assert.equal(open.cmuxHooksDisabled, "1");
  assert.deepEqual(open.argv.slice(0, 5), ["exec", "--json", "--skip-git-repo-check", "-s", "read-only"]);
  assert.equal(open.argv.at(-1), "-");
  assert.ok(open.argv.join(" ").includes('-m gpt-6-sol -c model_reasoning_effort="medium"'));
  assert.ok(resume.argv.join(" ").includes(`-m gpt-6-sol -c model_reasoning_effort="medium" resume ${THREAD_ID} -`));
  assert.equal(resume.stdin, "and now?");
});

test("codex-reply can switch the thread to a stronger model, and later replies keep it", async (t) => {
  const s = startServer();
  t.after(s.stop);
  await s.call("codex", { prompt: "a", model: "gpt-6-sol", config: { model_reasoning_effort: "medium", web_search: "live" } });
  await s.call("codex-reply", { threadId: THREAD_ID, prompt: "b", model: "gpt-6-astra", config: { model_reasoning_effort: "high" } });
  await s.call("codex-reply", { threadId: THREAD_ID, prompt: "c" });
  const [, escalated, later] = s.calls().map((c) => c.argv.join(" "));
  for (const argv of [escalated, later]) {
    assert.ok(argv.includes('-m gpt-6-astra -c model_reasoning_effort="high" -c web_search="live" resume'), argv);
  }
  const bad = await s.call("codex-reply", { threadId: THREAD_ID, prompt: "d", config: { x: [1] } });
  assert.equal(bad.isError, true);
});

test("codex-reply accepts the deprecated conversationId alias", async (t) => {
  const s = startServer();
  t.after(s.stop);
  const reply = await s.call("codex-reply", { conversationId: THREAD_ID, prompt: "hi" });
  assert.equal(reply.isError, undefined);
  assert.ok(s.calls()[0].argv.includes("resume"));
});

test("rejects write sandboxes, bad thread ids, and unsupported parameters without running codex", async (t) => {
  const s = startServer();
  t.after(s.stop);
  const sandbox = await s.call("codex", { prompt: "x", sandbox: "workspace-write" });
  assert.equal(sandbox.isError, true);
  assert.match(sandbox.content[0].text, /read-only/);
  const badThread = await s.call("codex-reply", { threadId: "continue thread abc", prompt: "x" });
  assert.equal(badThread.isError, true);
  assert.match(badThread.content[0].text, /threadId argument/);
  const unsupported = await s.call("codex", { prompt: "x", "base-instructions": "y" });
  assert.equal(unsupported.isError, true);
  const noPrompt = await s.call("codex", {});
  assert.equal(noPrompt.isError, true);
  assert.deepEqual(s.calls(), []);
});

test("outputSchema review passes the bundled schema file", async (t) => {
  const s = startServer();
  t.after(s.stop);
  await s.call("codex", { prompt: "x", outputSchema: "review" });
  const argv = s.calls()[0].argv;
  assert.equal(argv[argv.indexOf("--output-schema") + 1], SCHEMA);
  assert.ok(fs.existsSync(SCHEMA));
});

test("inline outputSchema is written to a temp file and removed", async (t) => {
  const s = startServer();
  t.after(s.stop);
  await s.call("codex", { prompt: "x", outputSchema: { type: "object" } });
  const argv = s.calls()[0].argv;
  const file = argv[argv.indexOf("--output-schema") + 1];
  assert.match(path.basename(file), /^codex-output-schema-/);
  assert.equal(fs.existsSync(file), false);
});

test("turn.failed returns isError with the message and stderr", async (t) => {
  const s = startServer({ FAKE_CODEX_MODE: "fail" });
  t.after(s.stop);
  const result = await s.call("codex", { prompt: "x" });
  assert.equal(result.isError, true);
  assert.match(result.content[0].text, /model is not supported/);
  assert.match(result.content[0].text, /something broke/);
});

test("a run with no agent message is an error", async (t) => {
  const s = startServer({ FAKE_CODEX_MODE: "silent" });
  t.after(s.stop);
  const result = await s.call("codex", { prompt: "x" });
  assert.equal(result.isError, true);
  assert.match(result.content[0].text, /no final message/);
});

test("missing codex binary returns an install hint", async (t) => {
  const s = startServer({ CODEX_BIN: "/nonexistent/codex" });
  t.after(s.stop);
  const result = await s.call("codex", { prompt: "x" });
  assert.equal(result.isError, true);
  assert.match(result.content[0].text, /npm install -g @openai\/codex/);
});
