import { open, mkdir, readFile, rename, rm } from "node:fs/promises";
import path from "node:path";
import { randomUUID } from "node:crypto";
import { constants } from "node:fs";
import { dlopen } from "bun:ffi";

const {
  symbols: { flock },
} = dlopen("libc.so.6", {
  flock: { args: ["i32", "i32"], returns: "i32" },
});
type RequestOwner = { pid: number; start: string };
let bootIdentity: Promise<string> | undefined;

export type Measurement = Record<string, unknown>;
export type CachedUsage = {
  source: string;
  identity: string;
  measurement?: Measurement;
  attemptedAt: number;
  lastError?: string;
  inFlight?: RequestOwner;
};
export type AccountState = {
  schema: 1;
  monitored: Record<string, { source: string; identity: string; name: string }>;
  profiles: Record<
    string,
    {
      id: string;
      profileDir: string;
      identity: string;
      email?: string;
      name: string;
    }
  >;
  cache: Record<string, CachedUsage>;
  generation: Record<string, number>;
};
export type CacheView = {
  measurement?: Measurement;
  stale: boolean;
  expired: boolean;
  cooldown: boolean;
  error?: string;
};
const blank = (): AccountState => ({
  schema: 1,
  monitored: {},
  profiles: {},
  cache: {},
  generation: {},
});
function record(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
function parse(raw: string): AccountState {
  const value: unknown = JSON.parse(raw);
  if (
    !record(value) ||
    value.schema !== 1 ||
    !record(value.monitored) ||
    !record(value.cache)
  )
    throw Error("Account state is invalid");
  if (value.profiles === undefined) value.profiles = {};
  if (!record(value.profiles)) throw Error("Account state is invalid");
  if (value.generation === undefined) value.generation = {};
  if (!record(value.generation)) throw Error("Account state is invalid");
  return value as AccountState;
}
async function read(pathname: string): Promise<AccountState> {
  try {
    return parse(await readFile(pathname, "utf8"));
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return blank();
    throw error;
  }
}
async function processStart(pid: number): Promise<string> {
  const contents = await readFile(`/proc/${pid}/stat`, "utf8"),
    end = contents.lastIndexOf(")"),
    fields = contents
      .slice(end + 2)
      .trim()
      .split(/\s+/);
  if (end < 0 || !fields[19]) throw Error("Process identity unavailable");
  bootIdentity ??= readFile("/proc/sys/kernel/random/boot_id", "utf8").then(
    (value) => value.trim(),
  );
  return `${await bootIdentity}:${fields[19]}`;
}
async function ownerAlive(owner: RequestOwner): Promise<boolean> {
  if (
    !Number.isSafeInteger(owner.pid) ||
    owner.pid <= 0 ||
    typeof owner.start !== "string"
  )
    return false;
  try {
    return (await processStart(owner.pid)) === owner.start;
  } catch (error) {
    return (error as NodeJS.ErrnoException).code !== "ENOENT";
  }
}
async function withLock<T>(
  pathname: string,
  action: (state: AccountState) => T | Promise<T>,
): Promise<T> {
  await mkdir(path.dirname(pathname), { recursive: true });
  // Kernel ownership survives neither process death nor reboot. Keep the lock
  // inode: unlinking a flock file lets concurrent users lock different inodes.
  const lock = await open(
    `${pathname}.lock`,
    constants.O_RDWR | constants.O_CREAT | constants.O_NOFOLLOW,
    0o600,
  );
  let acquired = false;
  try {
    const deadline = Date.now() + 5000;
    while (flock(lock.fd, 2 | 4) !== 0) {
      if (Date.now() >= deadline) throw Error("Account monitor state is busy");
      await Bun.sleep(25);
    }
    acquired = true;
    const state = await read(pathname),
      result = await action(state),
      temp = `${pathname}.${randomUUID()}.tmp`;
    let file;
    try {
      file = await open(temp, "wx", 0o600);
      await file.writeFile(JSON.stringify(state));
      await file.sync();
      await file.close();
      file = undefined;
      await rename(temp, pathname);
    } catch (error) {
      await file?.close().catch(() => {});
      await rm(temp, { force: true }).catch(() => {});
      throw error;
    }
    return result;
  } finally {
    if (acquired) flock(lock.fd, 8);
    await lock.close();
  }
}
export async function registerProfile(
  pathname: string,
  profile: AccountState["profiles"][string],
  signal?: AbortSignal,
): Promise<void> {
  await withLock(pathname, (state) => {
    signal?.throwIfAborted();
    state.profiles[profile.id] = profile;
  });
}
export async function readAccountState(
  pathname: string,
): Promise<AccountState> {
  return read(pathname);
}
export async function monitorAccount(
  pathname: string,
  id: string,
  account: { source: string; identity: string; name: string },
  signal?: AbortSignal,
): Promise<boolean> {
  return withLock(pathname, (state) => {
    signal?.throwIfAborted();
    if (
      state.monitored[id]?.identity === account.identity &&
      state.monitored[id]?.source === account.source
    )
      return false;
    state.monitored[id] = account;
    state.generation[id] = (state.generation[id] || 0) + 1;
    return true;
  });
}
export async function removeAccount(
  pathname: string,
  id: string,
): Promise<void> {
  await withLock(pathname, (state) => {
    delete state.monitored[id];
    delete state.cache[id];
    state.generation[id] = (state.generation[id] || 0) + 1;
  });
}
export async function generation(
  pathname: string,
  id: string,
): Promise<number> {
  return (await read(pathname)).generation[id] || 0;
}
export async function cacheUsage(
  pathname: string,
  id: string,
  source: string,
  identity: string,
  expectedGeneration: number,
  measurement: Measurement,
  now = Date.now() / 1000,
  signal?: AbortSignal,
): Promise<boolean> {
  return withLock(pathname, (state) => {
    signal?.throwIfAborted();
    if (
      !state.monitored[id] ||
      state.monitored[id].source !== source ||
      state.monitored[id].identity !== identity ||
      (state.generation[id] || 0) !== expectedGeneration
    )
      return false;
    state.cache[id] = { source, identity, measurement, attemptedAt: now };
    return true;
  });
}
export async function claimUsage(
  pathname: string,
  id: string,
  source: string,
  identity: string,
  expectedGeneration: number,
  now = Date.now() / 1000,
  signal?: AbortSignal,
): Promise<boolean> {
  const owner = { pid: process.pid, start: await processStart(process.pid) };
  return withLock(pathname, async (state) => {
    signal?.throwIfAborted();
    if (
      !state.monitored[id] ||
      state.monitored[id].source !== source ||
      state.monitored[id].identity !== identity ||
      (state.generation[id] || 0) !== expectedGeneration
    )
      return false;
    const entry = state.cache[id];
    if (entry?.inFlight && (await ownerAlive(entry.inFlight))) return false;
    if (entry && now - entry.attemptedAt < 15) return false;
    state.cache[id] = {
      ...entry,
      source,
      identity,
      attemptedAt: now,
      inFlight: owner,
    };
    return true;
  });
}
export async function recordFailure(
  pathname: string,
  id: string,
  source: string,
  identity: string,
  expectedGeneration: number,
  error: string,
  now = Date.now() / 1000,
  signal?: AbortSignal,
): Promise<CachedUsage | undefined> {
  return withLock(pathname, (state) => {
    signal?.throwIfAborted();
    if (
      !state.monitored[id] ||
      state.monitored[id].source !== source ||
      state.monitored[id].identity !== identity ||
      (state.generation[id] || 0) !== expectedGeneration
    )
      return undefined;
    const cached = state.cache[id];
    if (cached?.source === source && cached.identity === identity) {
      cached.attemptedAt = now;
      cached.lastError = error;
      delete cached.inFlight;
      return cached;
    }
    state.cache[id] = { source, identity, attemptedAt: now, lastError: error };
    return undefined;
  });
}
export async function getCachedUsage(
  pathname: string,
  id: string,
  source: string,
  identity: string,
  now = Date.now() / 1000,
  maxAge = 60,
): Promise<CacheView | undefined> {
  return cachedUsageView(
    (await read(pathname)).cache[id],
    source,
    identity,
    now,
    maxAge,
  );
}
export function cachedUsageView(
  entry: CachedUsage | undefined,
  source: string,
  identity: string,
  now = Date.now() / 1000,
  maxAge = 60,
): CacheView | undefined {
  if (entry?.source !== source || entry.identity !== identity) return;
  const measurement = entry.measurement;
  let stale = true,
    expired = false;
  if (measurement) {
    const time = measurement.measurementAt;
    stale = typeof time !== "number" || now - time > maxAge;
    const windows = measurement.rateLimits;
    if (record(windows))
      for (const item of Object.values(windows)) {
        if (!record(item)) continue;
        const reset = item.resetsAt,
          epoch =
            typeof reset === "number"
              ? reset > 1e12
                ? reset / 1000
                : reset
              : typeof reset === "string"
                ? Date.parse(reset) / 1000
                : NaN;
        if (Number.isFinite(epoch) && epoch <= now) {
          expired = true;
          stale = true;
        }
      }
  }
  return {
    measurement,
    stale: stale || Boolean(entry.lastError),
    expired,
    cooldown: now - entry.attemptedAt < 15,
    error: entry.lastError,
  };
}
