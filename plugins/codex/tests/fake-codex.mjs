#!/usr/bin/env node
// Stand-in for the codex CLI, used as CODEX_BIN in tests. Records argv, stdin,
// and selected env vars to $FAKE_CODEX_LOG, then prints `codex exec --json`
// events. FAKE_CODEX_MODE selects the scenario: ok (default), fail, silent,
// slow (waits FAKE_CODEX_DELAY_MS, default 400, before answering; exits 130 on SIGINT).

import fs from "node:fs";

const THREAD_ID = "11111111-2222-3333-4444-555555555555";
const mode = process.env.FAKE_CODEX_MODE || "ok";

let stdin = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (stdin += chunk));
process.stdin.on("end", () => {
  if (process.env.FAKE_CODEX_LOG) {
    const entry = {
      startedAt: Date.now(),
      argv: process.argv.slice(2),
      stdin,
      cwd: process.cwd(),
      cmuxHooksDisabled: process.env.CMUX_CODEX_HOOKS_DISABLED ?? null,
    };
    fs.appendFileSync(process.env.FAKE_CODEX_LOG, `${JSON.stringify(entry)}\n`);
  }

  if (mode === "slow") {
    process.on("SIGINT", () => {
      if (process.env.FAKE_CODEX_LOG) fs.writeFileSync(process.env.FAKE_CODEX_LOG.replace(/\.log$/, ".sigint"), "");
      process.exit(130);
    });
    setTimeout(respond, Number(process.env.FAKE_CODEX_DELAY_MS || 400));
  } else {
    respond();
  }
});

function respond() {
  const emit = (event) => process.stdout.write(`${JSON.stringify(event)}\n`);
  const resumeIndex = process.argv.indexOf("resume");
  const threadId = resumeIndex > 0 ? process.argv[resumeIndex + 1] : THREAD_ID;

  emit({ type: "thread.started", thread_id: threadId });
  emit({ type: "turn.started" });
  if (mode === "fail") {
    emit({ type: "turn.failed", error: { message: "model is not supported" } });
    process.stderr.write("fatal: something broke\n");
    process.exit(1);
  }
  if (mode === "silent") {
    emit({ type: "turn.completed", usage: {} });
    process.exit(0);
  }
  emit({ type: "item.started", item: { id: "c1", type: "command_execution", command: "ls" } });
  emit({ type: "item.completed", item: { id: "c1", type: "command_execution", command: "ls", exit_code: 0 } });
  emit({ type: "item.completed", item: { id: "m1", type: "agent_message", text: "draft" } });
  emit({ type: "item.completed", item: { id: "m2", type: "agent_message", text: `echo: ${stdin.trim()}` } });
  emit({ type: "turn.completed", usage: { input_tokens: 1, output_tokens: 1 } });
  if (process.env.FAKE_CODEX_LOG) {
    fs.appendFileSync(process.env.FAKE_CODEX_LOG.replace(/\.log$/, ".done.log"), `${Date.now()}\n`);
  }
}
