import { spawn } from "node:child_process";


export type ProfileMeasurement = { identity: string; account: { type?: string; email?: string; planType?: string }; rateLimits?: unknown; limits?: Record<string, unknown>; fetchedAt: number; measurementAt: number; source: string };
export async function readProfileUsage(options: { executable: string; profileDir: string; expectedIdentity?: string; identityOnly?: boolean; timeoutMs?: number; signal?: AbortSignal }): Promise<ProfileMeasurement> {
 const child=spawn(options.executable,["app-server","--listen","stdio://"],{cwd:options.profileDir,env:{...process.env,CODEX_HOME:options.profileDir},stdio:["pipe","pipe","ignore"]});
 const pending=new Map<number,{resolve:(v:any)=>void;reject:(e:Error)=>void}>();
 let buffer="", nextId=0, closed=false;
 const finish=(error?:Error)=>{if(closed)return;closed=true;for(const p of pending.values())p.reject(error||new Error("Codex app-server closed"));pending.clear();};
 child.stdout.setEncoding("utf8");
 child.stdout.on("data",(chunk:string)=>{buffer+=chunk;if(buffer.length>1024*1024){finish(new Error("Codex app-server response too large"));child.kill("SIGTERM");return;}for(;;){const at=buffer.indexOf("\n");if(at<0)break;const line=buffer.slice(0,at);buffer=buffer.slice(at+1);let msg:any;try{msg=JSON.parse(line);}catch{finish(new Error("Malformed Codex app-server response"));child.kill("SIGTERM");return;}if(Number.isInteger(msg.id)&&pending.has(msg.id)){const p=pending.get(msg.id)!;pending.delete(msg.id);if(msg.error)p.reject(new Error("Codex app-server request failed"));else p.resolve(msg.result);}}});
 child.once("error",()=>finish(new Error("Codex app-server unavailable")));
 child.once("close",()=>finish());
 const send=(method:string,params:object={})=>new Promise<any>((resolve,reject)=>{if(closed){reject(new Error("Codex app-server closed"));return;}const id=++nextId;pending.set(id,{resolve,reject});child.stdin.write(JSON.stringify({id,method,params})+"\n",e=>{if(e){pending.delete(id);reject(new Error("Codex app-server write failed"));}});});
 let timeout:any;
 const abort=()=>{child.kill("SIGTERM");setTimeout(()=>{if(!closed)child.kill("SIGKILL");},500).unref();};
 const aborted=new Promise<never>((_,reject)=>{if(options.signal?.aborted){abort();reject(new Error("Codex app-server request cancelled"));return;}options.signal?.addEventListener("abort",()=>{abort();reject(new Error("Codex app-server request cancelled"));},{once:true});});
 try {
  timeout=setTimeout(abort,timeoutMs);timeout.unref();
  await Promise.race([send("initialize",{clientInfo:{name:"sensei-codex-accounts",version:"1.0"}}),aborted]);
  child.stdin.write('{"method":"initialized"}\n');
  const accountPromise=send("account/read",{refreshToken:false});
  const usagePromise=options.identityOnly?Promise.resolve(undefined):send("account/rateLimits/read");
  const [accountResult,usageResult]=await Promise.race([Promise.all([accountPromise,usagePromise]),aborted]);
  const account=accountResult?.account;
  if(!account||typeof account!=="object")throw new Error("Codex profile is not authenticated");
  const identity=account.accountId||account.email;
  if(typeof identity!=="string"||(options.expectedIdentity&&identity!==options.expectedIdentity))throw new Error("Codex profile identity changed");
  const limits=usageResult?.rateLimitsByLimitId;
  const rateLimits=usageResult?.rateLimits;
  if(!options.identityOnly&&(!usageResult||!rateLimits||(typeof rateLimits!=="object")))throw new Error("Codex profile usage unavailable");
  return {identity,account:{type:account.type,email:account.email,planType:account.planType},rateLimits,limits:limits&&typeof limits==="object"?limits:{},fetchedAt:Date.now()/1000,measurementAt:Date.now()/1000,source:"Codex app-server account/rateLimits/read"};
 } finally {clearTimeout(timeout);if(!closed){child.kill("SIGTERM");await Promise.race([new Promise(resolve=>child.once("close",resolve)),new Promise(resolve=>setTimeout(resolve,750))]);if(!closed)child.kill("SIGKILL");} }
}
