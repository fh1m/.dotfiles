import { open, mkdir, readFile, rename, rm, stat } from "node:fs/promises";
import path from "node:path";
import { randomUUID } from "node:crypto";

export type Measurement=Record<string,unknown>;
export type CachedUsage={source:string;identity:string;measurement?:Measurement;attemptedAt:number;lastError?:string};
export type AccountState={schema:1;monitored:Record<string,{source:string;identity:string;name:string}>;profiles:Record<string,{id:string;profileDir:string;identity:string;email?:string;name:string}>;cache:Record<string,CachedUsage>;generation:Record<string,number>};
export type CacheView={measurement?:Measurement;stale:boolean;cooldown:boolean;error?:string};
const blank=():AccountState=>({schema:1,monitored:{},profiles:{},cache:{},generation:{}});
function record(value:unknown):value is Record<string,unknown>{return value!==null&&typeof value==="object"&&!Array.isArray(value);}
function parse(raw:string):AccountState{
 const value:unknown=JSON.parse(raw);
 if(!record(value)||value.schema!==1||!record(value.monitored)||!record(value.cache))throw Error("Account state is invalid");
 if(value.profiles===undefined)value.profiles={};if(!record(value.profiles))throw Error("Account state is invalid");
 if(value.generation===undefined)value.generation={};if(!record(value.generation))throw Error("Account state is invalid");
 return value as AccountState;
}
async function read(pathname:string):Promise<AccountState>{try{return parse(await readFile(pathname,"utf8"));}catch(error){if((error as NodeJS.ErrnoException).code==="ENOENT")return blank();throw error;}}
async function withLock<T>(pathname:string,action:(state:AccountState)=>T):Promise<T>{
 const lockPath=`${pathname}.lock`;await mkdir(path.dirname(pathname),{recursive:true});let lock;
 const deadline=Date.now()+5000;
 while(!lock){try{lock=await open(lockPath,"wx",0o600);}catch(error){if((error as NodeJS.ErrnoException).code!=="EEXIST")throw error;try{if(Date.now()-(await stat(lockPath)).mtimeMs>30000){await rm(lockPath,{force:true});continue;}}catch{}if(Date.now()>=deadline)throw Error("Account monitor state is busy");await Bun.sleep(25);}}
 try{const state=await read(pathname),result=action(state),temp=`${pathname}.${randomUUID()}.tmp`;let file;
  try{file=await open(temp,"wx",0o600);await file.writeFile(JSON.stringify(state));await file.sync();await file.close();file=undefined;await rename(temp,pathname);}
  catch(error){await file?.close().catch(()=>{});await rm(temp,{force:true}).catch(()=>{});throw error;}
  return result;
}
export async function registerProfile(pathname:string,profile:AccountState["profiles"][string]):Promise<void>{await withLock(pathname,state=>{state.profiles[profile.id]=profile;});}
export async function readAccountState(pathname:string):Promise<AccountState>{return read(pathname);}
export async function monitorAccount(pathname:string,id:string,account:{source:string;identity:string;name:string}):Promise<boolean>{return withLock(pathname,state=>{if(state.monitored[id]?.identity===account.identity&&state.monitored[id]?.source===account.source)return false;state.monitored[id]=account;state.generation[id]=(state.generation[id]||0)+1;return true;});}
export async function removeAccount(pathname:string,id:string):Promise<void>{await withLock(pathname,state=>{delete state.monitored[id];delete state.cache[id];state.generation[id]=(state.generation[id]||0)+1;});}
export async function generation(pathname:string,id:string):Promise<number>{return (await read(pathname)).generation[id]||0;}
export async function cacheUsage(pathname:string,id:string,source:string,identity:string,expectedGeneration:number,measurement:Measurement,now=Date.now()/1000):Promise<boolean>{return withLock(pathname,state=>{if(!state.monitored[id]||state.monitored[id].source!==source||state.monitored[id].identity!==identity||(state.generation[id]||0)!==expectedGeneration)return false;state.cache[id]={source,identity,measurement,attemptedAt:now};return true;});}
export async function recordFailure(pathname:string,id:string,source:string,identity:string,expectedGeneration:number,error:string,now=Date.now()/1000):Promise<CachedUsage|undefined>{return withLock(pathname,state=>{if(!state.monitored[id]||state.monitored[id].source!==source||state.monitored[id].identity!==identity||(state.generation[id]||0)!==expectedGeneration)return undefined;const cached=state.cache[id];if(cached?.source===source&&cached.identity===identity){cached.attemptedAt=now;cached.lastError=error;return cached;}state.cache[id]={source,identity,attemptedAt:now,lastError:error};return undefined;});}
export async function getCachedUsage(pathname:string,id:string,source:string,identity:string,now=Date.now()/1000,maxAge=60):Promise<CacheView|undefined>{
 const entry=(await read(pathname)).cache[id];if(entry?.source!==source||entry.identity!==identity)return;
 const measurement=entry.measurement;let stale=true;
 if(measurement){const time=measurement.measurementAt;stale=typeof time!=="number"||now-time>maxAge;const windows=measurement.rateLimits;if(record(windows))for(const item of Object.values(windows)){if(!record(item))continue;const reset=item.resetsAt,epoch=typeof reset==="number"?(reset>1e12?reset/1000:reset):typeof reset==="string"?Date.parse(reset)/1000:NaN;if(Number.isFinite(epoch)&&epoch<=now)stale=true;}}
 return {measurement,stale,cooldown:now-entry.attemptedAt<15,error:entry.lastError};
}
