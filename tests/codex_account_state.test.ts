import { afterEach, describe, expect, test } from "bun:test";
import { mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import {
  cacheUsage,
  claimUsage,
  generation,
  getCachedUsage,
  monitorAccount,
  readAccountState,
  recordFailure,
  registerProfile,
  removeAccount,
} from "../home/.local/share/sensei/codex_account_state.ts";

const roots: string[] = [];
afterEach(async () => {
  for (const root of roots.splice(0))
    await rm(root, { recursive: true, force: true });
});
async function stateFile() {
  const dir = await mkdtemp(path.join(os.tmpdir(), "sensei-codex-state-"));
  roots.push(dir);
  return path.join(dir, "state.json");
}
const identity = { source: "profile", identity: "account-a", name: "A" };
const measure = (measurementAt: number, resetsAt: number) => ({
  measurementAt,
  rateLimits: { primary: { usedPercent: 20, resetsAt } },
  source: "fixture",
});

describe("production account monitor state", () => {
  test("monitor removal cannot be undone by a usage request already in flight", async () => {
    const file = await stateFile();
    await monitorAccount(file, "a", identity);
    const started = await generation(file, "a");
    await removeAccount(file, "a");
    expect(
      await cacheUsage(
        file,
        "a",
        "profile",
        "account-a",
        started,
        measure(100, 5000),
        101,
      ),
    ).toBe(false);
    expect((await readAccountState(file)).monitored.a).toBeUndefined();
  });
  test("cache is isolated by source and identity and expires when its quota resets", async () => {
    const file = await stateFile();
    await monitorAccount(file, "a", identity);
    const gen = await generation(file, "a");
    await cacheUsage(
      file,
      "a",
      "profile",
      "account-a",
      gen,
      measure(199, 200),
      199,
    );
    expect(
      await getCachedUsage(file, "a", "omp", "account-a", 200),
    ).toBeUndefined();
    expect(
      await getCachedUsage(file, "a", "profile", "account-b", 200),
    ).toBeUndefined();
    const expired = await getCachedUsage(
      file,
      "a",
      "profile",
      "account-a",
      201,
    );
    expect(expired?.stale).toBe(true);
    expect(expired?.expired).toBe(true);
  });
  test("refresh failures preserve measurement age and activate cooldown", async () => {
    const file = await stateFile();
    await monitorAccount(file, "a", identity);
    const gen = await generation(file, "a");
    await cacheUsage(
      file,
      "a",
      "profile",
      "account-a",
      gen,
      measure(100, 5000),
      100,
    );
    const fresh = await getCachedUsage(file, "a", "profile", "account-a", 110);
    expect(fresh?.stale).toBe(false);
    expect(fresh?.cooldown).toBe(true);
    const failure = await recordFailure(
      file,
      "a",
      "profile",
      "account-a",
      gen,
      "offline",
      110,
    );
    expect(failure?.measurement?.measurementAt).toBe(100);
    expect(
      (await getCachedUsage(file, "a", "profile", "account-a", 111))
        ?.measurement?.measurementAt,
    ).toBe(100);
  });
  test("provider failures without a good snapshot cool down without inventing measurement", async () => {
    const file = await stateFile();
    await monitorAccount(file, "a", identity);
    const gen = await generation(file, "a");
    await recordFailure(file, "a", "profile", "account-a", gen, "offline", 100);
    const cached = await getCachedUsage(file, "a", "profile", "account-a", 105);
    expect(cached?.cooldown).toBe(true);
    expect(cached?.measurement).toBeUndefined();
  });
  test("one live request retains ownership beyond cooldown; a completed request releases it", async () => {
    const file = await stateFile();
    await monitorAccount(file, "a", identity);
    const gen = await generation(file, "a");
    const results = await Promise.all([
      claimUsage(file, "a", "profile", "account-a", gen, 100),
      claimUsage(file, "a", "profile", "account-a", gen, 100),
    ]);
    expect(results.filter(Boolean)).toHaveLength(1);
    expect(await claimUsage(file, "a", "profile", "account-a", gen, 116)).toBe(
      false,
    );
    await recordFailure(file, "a", "profile", "account-a", gen, "offline", 116);
    expect(await claimUsage(file, "a", "profile", "account-a", gen, 132)).toBe(
      true,
    );
  });
  test("removal hides monitoring but leaves existing profile registration reversible", async () => {
    const file = await stateFile();
    await registerProfile(file, {
      id: "a",
      profileDir: "/existing",
      identity: "account-a",
      email: "a@example.test",
      name: "A",
    });
    expect((await readAccountState(file)).monitored.a).toBeUndefined();
    await monitorAccount(file, "a", identity);
    await removeAccount(file, "a");
    const state = await readAccountState(file);
    expect(state.monitored.a).toBeUndefined();
    expect(state.profiles.a.identity).toBe("account-a");
    await monitorAccount(file, "a", identity);
    expect((await readAccountState(file)).monitored.a.identity).toBe(
      "account-a",
    );
  });
  test("a killed lock holder releases state updates without stale-lock cleanup", async () => {
    const file = await stateFile();
    const holder = Bun.spawn(
      [
        "flock",
        "--exclusive",
        "--no-fork",
        `${file}.lock`,
        "sh",
        "-c",
        "printf ready; read -r release",
      ],
      { stdin: "pipe", stdout: "pipe", stderr: "pipe" },
    );
    await holder.stdout.getReader().read();
    const pending = monitorAccount(file, "a", identity);
    try {
      holder.kill("SIGKILL");
      await holder.exited;
      await pending;
      expect((await readAccountState(file)).monitored.a.identity).toBe(
        "account-a",
      );
    } finally {
      try {
        holder.kill("SIGKILL");
      } catch {}
      await holder.exited;
      await pending.catch(() => {});
    }
  }, 8000);
  test("a killed usage owner does not permanently block a later request", async () => {
    const file = await stateFile();
    await monitorAccount(file, "a", identity);
    const module = path.resolve(
      import.meta.dir,
      "../home/.local/share/sensei/codex_account_state.ts",
    );
    const program = `import {claimUsage,generation} from ${JSON.stringify(module)};console.log(await claimUsage(${JSON.stringify(file)},"a","profile","account-a",await generation(${JSON.stringify(file)},"a"),100));await Bun.stdin.text();`;
    const holder = Bun.spawn([process.execPath, "-e", program], {
      stdin: "pipe",
      stdout: "pipe",
      stderr: "pipe",
    });
    try {
      const first = await holder.stdout.getReader().read();
      expect(new TextDecoder().decode(first.value).trim()).toBe("true");
      const gen = await generation(file, "a");
      expect(
        await claimUsage(file, "a", "profile", "account-a", gen, 116),
      ).toBe(false);
      holder.kill("SIGKILL");
      await holder.exited;
      expect(
        await claimUsage(file, "a", "profile", "account-a", gen, 116),
      ).toBe(true);
    } finally {
      try {
        holder.kill("SIGKILL");
      } catch {}
      await holder.exited;
    }
  });
  test("atomic private write and malformed-state failure preserve file contents", async () => {
    const file = await stateFile();
    await monitorAccount(file, "a", identity);
    expect((await stat(file)).mode & 0o777).toBe(0o600);
    const original = await readFile(file, "utf8");
    await writeFile(file, "not-json");
    await expect(monitorAccount(file, "b", identity)).rejects.toThrow();
    expect(await readFile(file, "utf8")).toBe("not-json");
    expect(original).not.toBe("not-json");
  });
});
