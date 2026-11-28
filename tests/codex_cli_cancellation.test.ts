import { afterEach, describe, expect, test } from "bun:test";
import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import {
  chmod,
  mkdtemp,
  mkdir,
  readFile,
  rm,
  writeFile,
} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {
  monitorAccount,
  registerProfile,
} from "../home/.local/share/sensei/codex_account_state.ts";

const roots: string[] = [];
afterEach(async () => {
  for (const root of roots.splice(0))
    await rm(root, { recursive: true, force: true });
});

describe("CLI termination cleanup", () => {
  test("SIGTERM cancels the real CLI request, reaps its app-server, and emits no usage row", async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), "sensei-codex-cli-"));
    roots.push(root);
    const profileDir = path.join(root, ".codex"),
      statePath = path.join(root, ".config/sensei/codex-accounts.json"),
      fixture = path.join(root, "codex-fixture"),
      marker = path.join(root, "app-server.pid");
    await mkdir(profileDir, { recursive: true });
    await writeFile(path.join(profileDir, "auth.json"), "{}");
    await writeFile(
      fixture,
      `#!/usr/bin/env bun
let input="";for await(const chunk of process.stdin){input+=chunk;for(;;){const split=input.indexOf("\\n");if(split<0)break;const line=input.slice(0,split);input=input.slice(split+1);const request=JSON.parse(line);if(!request.id)continue;if(request.method==="account/read")console.log(JSON.stringify({id:request.id,result:{account:{type:"chatgpt",email:"cli@example.test",accountId:"cli-account",planType:"plus"}}}));else if(request.method==="account/rateLimits/read")await Bun.write(${JSON.stringify(marker)},String(process.pid));else console.log(JSON.stringify({id:request.id,result:{}}));}}
`,
    );
    await chmod(fixture, 0o700);
    const id = createHash("sha256")
      .update(`profile\0${profileDir}\0cli-account`)
      .digest("hex")
      .slice(0, 24);
    await registerProfile(statePath, {
      id,
      profileDir,
      identity: "cli-account",
      email: "cli@example.test",
      name: "CLI fixture",
    });
    await monitorAccount(statePath, id, {
      source: "profile",
      identity: "cli-account",
      name: "CLI fixture",
    });
    const cli = path.resolve(
        import.meta.dir,
        "../home/.local/bin/sensei-codex-accounts",
      ),
      child = spawn(process.execPath, [cli, "usage", "--account", id], {
        env: {
          ...process.env,
          HOME: root,
          OMP_AGENT_DIR: path.join(root, ".omp/agent"),
          CODEX_EXECUTABLE: fixture,
        },
        stdio: ["ignore", "pipe", "pipe"],
      });
    let output = "",
      errors = "";
    child.stdout.setEncoding("utf8").on("data", (chunk) => (output += chunk));
    child.stderr.setEncoding("utf8").on("data", (chunk) => (errors += chunk));
    const closed = new Promise<{
      code: number | null;
      signal: NodeJS.Signals | null;
    }>((resolve) =>
      child.once("close", (code, signal) => resolve({ code, signal })),
    );
    // Poll only for the real child protocol milestone; fake timers cannot drive a spawned process.
    let started = false;
    for (let attempt = 0; attempt < 200; attempt++) {
      try {
        await readFile(marker);
        started = true;
        break;
      } catch {}
      await Bun.sleep(25);
    }
    if (!started) {
      child.kill("SIGKILL");
      await closed;
      throw Error(`CLI fixture never received quota request: ${errors}`);
    }
    const appPid = Number(await readFile(marker, "utf8"));
    child.kill("SIGTERM");
    const result = await closed;
    expect(result.code).toBe(130);
    expect(output.trim()).toBe("");
    let appServerAlive = true;
    try {
      process.kill(appPid, 0);
    } catch {
      appServerAlive = false;
    }
    expect(appServerAlive).toBe(false);
  });
});
