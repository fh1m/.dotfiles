import { afterEach, describe, expect, test } from "bun:test";
import { spawn } from "node:child_process";
import { chmod, mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const roots: string[] = [];
afterEach(async () => {
  for (const root of roots.splice(0))
    await rm(root, { recursive: true, force: true });
});

describe("profile discovery independent of OMP", () => {
  test("list still returns the default Codex context with an OMP warning when native OMP is absent", async () => {
    const root = await mkdtemp(
      path.join(os.tmpdir(), "sensei-codex-discovery-"),
    );
    roots.push(root);
    const profile = path.join(root, ".codex"),
      fixture = path.join(root, "codex-fixture");
    await mkdir(profile, { recursive: true });
    await writeFile(path.join(profile, "auth.json"), "{}");
    await writeFile(
      fixture,
      `#!/usr/bin/env bun
let input="";for await(const chunk of process.stdin){input+=chunk;for(;;){const split=input.indexOf("\\n");if(split<0)break;const line=input.slice(0,split);input=input.slice(split+1);const request=JSON.parse(line);if(!request.id)continue;const result=request.method==="account/read"?{account:{type:"chatgpt",email:"cli@example.test",accountId:"cli-account",planType:"plus"}}:{};console.log(JSON.stringify({id:request.id,result}));}}
`,
    );
    await chmod(fixture, 0o700);
    const cli = path.resolve(
        import.meta.dir,
        "../home/.local/bin/sensei-codex-accounts",
      ),
      child = spawn(process.execPath, [cli, "list"], {
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
    const result = await new Promise<{ code: number | null }>((resolve) =>
      child.once("close", (code) => resolve({ code })),
    );
    expect(result.code).toBe(0);
    expect(errors).toBe("");
    const payload = JSON.parse(output);
    expect(
      payload.accounts.some(
        (account: { source: string; identity: string }) =>
          account.source === "profile" && account.identity === "cli-account",
      ),
    ).toBe(true);
    expect(
      payload.warnings.some(
        (warning: { source: string }) => warning.source === "omp",
      ),
    ).toBe(true);
  });
});
