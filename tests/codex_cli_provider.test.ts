import { afterEach, describe, expect, test } from "bun:test";
import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { monitorAccount } from "../home/.local/share/sensei/codex_account_state.ts";

const roots: string[] = [];
afterEach(async () => {
  for (const root of roots.splice(0))
    await rm(root, { recursive: true, force: true });
});

describe("native Codex provider absence", () => {
  test("fails explicitly before resolving credentials and never substitutes another provider", async () => {
    const home = await mkdtemp(
      path.join(os.tmpdir(), "sensei-codex-provider-"),
    );
    roots.push(home);
    const root = path.join(
        home,
        ".bun/install/global/node_modules/@oh-my-pi/pi-ai",
      ),
      auth = path.join(root, "src/auth-broker"),
      usage = path.join(root, "src/usage"),
      marker = path.join(home, "access-called");
    await mkdir(auth, { recursive: true });
    await mkdir(usage, { recursive: true });
    await writeFile(
      path.join(root, "package.json"),
      JSON.stringify({ version: "18.16.0" }),
    );
    await writeFile(
      path.join(auth, "discover.ts"),
      `export async function discoverAuthStorage(){return {oauth:{accounts:()=>[{accountId:"acct-a",email:"a@example.test",credentialId:42,position:0},{accountId:"acct-a",email:"a@example.test",credentialId:43,position:1}],accessById:async()=>{await Bun.write(${JSON.stringify(marker)},"called");return {ok:true,accessToken:"not-a-real-token",accountId:"acct-a",email:"a@example.test"}}},usage:{providerFor:()=>undefined},close(){}}}`,
    );
    await writeFile(
      path.join(usage, "openai-codex.ts"),
      "export const openaiCodexUsageProvider = {};\n",
    );
    const id = createHash("sha256")
      .update(`omp\0${42}\0acct-a\0`)
      .digest("hex")
      .slice(0, 24);
    await monitorAccount(
      path.join(home, ".config/sensei/codex-accounts.json"),
      id,
      { source: "omp", identity: "acct-a", name: "a@example.test" },
    );
    const cli = path.resolve(
        import.meta.dir,
        "../home/.local/bin/sensei-codex-accounts",
      ),
      child = spawn(process.execPath, [cli, "usage", "--account", id], {
        env: {
          ...process.env,
          HOME: home,
          OMP_AGENT_DIR: path.join(home, ".omp/agent"),
        },
        stdio: ["ignore", "pipe", "pipe"],
      });
    let output = "",
      stderr = "";
    child.stdout.setEncoding("utf8").on("data", (chunk) => (output += chunk));
    child.stderr.setEncoding("utf8").on("data", (chunk) => (stderr += chunk));
    const code = await new Promise<number | null>((resolve) =>
      child.once("close", resolve),
    );
    expect(code).toBe(1);
    expect(stderr).toBe("");
    expect(JSON.parse(output).error).toBe(
      "Native Codex usage provider unavailable",
    );
    expect(await Bun.file(marker).exists()).toBe(false);
    const listChild = spawn(process.execPath, [cli, "list"], {
      env: {
        ...process.env,
        HOME: home,
        OMP_AGENT_DIR: path.join(home, ".omp/agent"),
      },
      stdio: ["ignore", "pipe", "pipe"],
    });
    let listed = "";
    listChild.stdout
      .setEncoding("utf8")
      .on("data", (chunk) => (listed += chunk));
    const listCode = await new Promise<number | null>((resolve) =>
      listChild.once("close", resolve),
    );
    const accounts = JSON.parse(listed).accounts;
    expect(listCode).toBe(0);
    expect(accounts).toHaveLength(2);
    expect(
      new Set(accounts.map((account: { id: string }) => account.id)).size,
    ).toBe(2);
  });
});
