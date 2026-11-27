#!/usr/bin/env bun
/**
 * Unified session browser + non-destructive native OMP importer.
 * Reads snapshot hardlinks to BACKUPS; creates new OMP sessions in the shared store.
 * Does not touch original Codex/Claude Code rollouts or repositories.
 * Pinned to the installed OMP package API, tested against omp/18.13.3.
 */
import { ClaudeSessionStore } from "/home/fh1m/.bun/install/global/node_modules/@oh-my-pi/pi-coding-agent/src/session/claude-session-store.ts";
import { CodexSessionStore } from "/home/fh1m/.bun/install/global/node_modules/@oh-my-pi/pi-coding-agent/src/session/codex-session-store.ts";
import { persistForeignSession } from "/home/fh1m/.bun/install/global/node_modules/@oh-my-pi/pi-coding-agent/src/session/foreign-session-import.ts";
import type { ForeignSessionInfo, ForeignSessionStore } from "/home/fh1m/.bun/install/global/node_modules/@oh-my-pi/pi-coding-agent/src/session/foreign-session-store.ts";
import * as fs from "node:fs";
import { createHash } from "node:crypto";
import * as path from "node:path";
import os from "node:os";
const H=process.env.OMP_UNIFIED_HOST_HOME??"/home/fh1m", STATE=path.join(H,".local/share/omp-unified");
const ROOT=path.join(STATE,"sources"), REGISTRY=path.join(STATE,"imports.json");
const OMP="/home/fh1m/.bun/bin/omp";
type Spec={key:string;env:"host"|"auv"|"drone"|"devenv"|"rupsha";source:"codex"|"claude";root:string;store:ForeignSessionStore;live:boolean};
const specs:Spec[]=[
 ["host-codex","host","codex"], ["host-claude","host","claude"],
 ["auv-codex","auv","codex"], ["auv-claude","auv","claude"],
 ["drone-codex","drone","codex"], ["drone-claude","drone","claude"],
 ["devenv-claude","devenv","claude"], ["rupsha-claude","rupsha","claude"], ["rupsha-codex","rupsha","codex"],
].map(([key,env,source])=>{
 const root=path.join(ROOT,key);
 return {key,env:env as Spec["env"],source:source as Spec["source"],root,live:false,
   store:source==="codex"?new CodexSessionStore(root):new ClaudeSessionStore(root)};
});
const LIVE_ROOTS:Record<string,string>={
 "host-codex":path.join(H,".codex"),"host-claude":path.join(H,".claude"),
 "auv-codex":path.join(H,"Envs/dockers/auv-ros2/.codex"),
 "auv-claude":path.join(H,"Envs/dockers/auv-ros2/.claude"),
 "drone-codex":path.join(H,"Envs/dockers/drone-ros2/.codex"),
 "drone-claude":path.join(H,"Envs/dockers/drone-ros2/.claude"),
 "rupsha-codex":path.join(H,"Envs/dockers/rupsha_dev/.codex"),
 "devenv-claude":path.join(H,"Envs/dockers/DevEnv_v1/.claude"),
 "rupsha-claude":path.join(H,"Envs/dockers/rupsha_dev/.claude"),
};
const liveSpecs:Spec[]=specs.map(spec=>{
 const root=LIVE_ROOTS[spec.key];
 return {...spec,root,live:true,store:spec.source==="codex"?new CodexSessionStore(root):new ClaudeSessionStore(root)};
});
type Entry={key:string;spec:Spec;info:ForeignSessionInfo;preview:string;modified:string;bytes:number;mtimeMs:number};
const help=`omp-unified: one safe selector for host, auv-ros2, and drone-ros2 session history
  omp-unified                  Open normal OMP; all previously imported sessions are shared
  omp-unified list [query]     Search saved originals + newly created live sessions (read-only)
  omp-unified browse [query]   FZF picker → import selected transcript → resume in correct environment
  omp-unified import ID [--no-open] [--new-revision]   Preserve and import an exact source revision
  omp-unified imports          List sessions already converted to native OMP
  omp-unified native           Open OMP's native resume picker (Tab = all projects)
  omp-unified refresh          Rebuild zero-copy discovery mirror from backup snapshots
  omp-unified extras           Show separately archived subordinate Claude-agent transcripts
  omp-unified help
Examples: omp-unified browse mongla | omp-unified list meghdhut | omp-unified import <id>
Source originals are NEVER modified. New live sessions are discovered automatically.
Active sessions may change during import: retry after they are idle.`;
async function sha256(file:string):Promise<string>{
 const hash=createHash("sha256");
 for await (const block of fs.createReadStream(file)) hash.update(block);
 return hash.digest("hex");
}
function desiredCwd(entry:Entry):string {
 if(fs.existsSync(entry.info.cwd))return entry.info.cwd;
 // A few very old Claude transcripts lack recorded cwd; the encoded path cannot
 // distinguish literal hyphens/underscores. Prefer our verified actual workspace roots.
 const folder=entry.spec.env==="auv"
   ?"/home/fh1m/Envs/dockers/auv-ros2/Ros_workspaces/mongla_ws"
   :entry.spec.env==="drone"
   ?"/home/fh1m/Envs/dockers/drone-ros2/meghdhut_ws"
   :H;
 const inMongla=entry.info.path.includes("mongla-ws")||entry.info.path.includes("mongla_ws");
 return inMongla && entry.spec.env==="auv" ?folder:
        entry.spec.env==="drone" ?folder:process.cwd();
}
type ImportRecord={native:string;imported:string;sourcePath:string;env:string;sourceSha256?:string};
type ImportRegistry=Record<string,ImportRecord>;
function loadRegistry():ImportRegistry{
 try{return JSON.parse(fs.readFileSync(REGISTRY,"utf8"));}catch(e){
  if((e as NodeJS.ErrnoException).code==="ENOENT")return {};
  throw new Error("Import registry is unreadable; refusing to replace it: "+String(e));
 }
}
function saveRegistry(a:ImportRegistry){
 const tmp=REGISTRY+".tmp."+process.pid;
 fs.writeFileSync(tmp,JSON.stringify(a,null,2)+"\n",{mode:0o600});
 fs.renameSync(tmp,REGISTRY);fs.chmodSync(REGISTRY,0o600);
}
function excerpt(content:unknown):string{
 const getText=(x:any):string=>{
  if(typeof x==="string")return x;
  if(Array.isArray(x))return x.filter(y=>y&&y.type==="text").map(y=>y.text).join(" ");
  return "";
 };
 return getText(content).replace(/[\u0000-\u001f\u007f]+/g," ").replace(/\s+/g," ").trim().slice(0,125);
}
async function preview(info:ForeignSessionInfo,source:"claude"|"codex"):Promise<string>{
 if(info.firstMessage)return excerpt(info.firstMessage);
 if(info.title)return excerpt(info.title);
 try{
  const chunk=await Bun.file(info.path).slice(0,384000).text();
  for(const line of chunk.split("\n")){
   try{
    const x=JSON.parse(line);
    if(source==="claude" && x.type==="user"){
     const s=excerpt(x.message?.content);
     if(s&&!s.includes("<local-command"))return s;
    }
    if(source==="codex"){
     if(x.type==="event_msg" && x.payload?.type==="user_message"){
      const s=excerpt(x.payload.message);if(s)return s;
     }
     if(x.type==="response_item" && x.payload?.role==="user"){
      const s=excerpt(x.payload.content);if(s)return s;
     }
    }
   }catch{}
  }
 }catch{}
 return "(no preview)";
}
async function scan():Promise<Entry[]>{
 const found=new Map<string,Entry>();
 // Snapshots are authoritative if the original has not changed. Live files
 // discovered later are selectable immediately; importing never writes to them.
 for(const spec of [...specs,...liveSpecs]){
  let infos:ForeignSessionInfo[];
  try{infos=await spec.store.list();}catch(e){console.error("Skipping",spec.key,spec.live?"live":"snapshot",String(e));continue;}
  const duplicates=new Map<string,number>();
  for(const x of infos)duplicates.set(x.id,(duplicates.get(x.id)??0)+1);
  for(const info of infos){
   try{fs.accessSync(info.path,fs.constants.R_OK);}catch{continue;}
   const stat=fs.statSync(info.path);
   const bareKey=spec.key+"/"+info.id;
   let key=bareKey;
   if((duplicates.get(info.id)??0)>1){
    // Codex may record several historical rollout files for one logical
    // thread ID. Do not collapse them: each is a distinct importable file.
    key=bareKey+"~"+path.basename(info.path,".jsonl").slice(0,30);
   }
   if(spec.live && !found.has(key) && (duplicates.get(info.id)??0)===1){
     for(const [priorKey,prior] of found){
       if(prior.spec.key!==spec.key||prior.info.id!==info.id)continue;
       const fromBackup=path.relative(prior.spec.root,prior.info.path);
       const fromLive=path.relative(spec.root,info.path);
       if(fromBackup===fromLive){key=priorKey;break;}
     }
   }
   const previous=found.get(key);
   if(previous && !(spec.live && stat.mtimeMs>previous.mtimeMs+2))continue;
   found.set(key,{key,spec,info,preview:await preview(info,spec.source),
     modified:info.modified.toISOString().slice(0,19).replace("T"," "),bytes:stat.size,mtimeMs:stat.mtimeMs});
  }
 }
 const entries=[...found.values()];
 entries.sort((a,b)=>b.info.modified.getTime()-a.info.modified.getTime());
 return entries;
}
function line(item:Entry,registry:ImportRegistry):string{
 const been=registry[item.key]?"✓":" ";
 const where=item.info.cwd?.replace(H+"/","~/")||"?";
 let title=item.info.title||item.preview;
 const imported=registry[item.key];
 if(imported&&fs.existsSync(imported.native)){
  const fd=fs.openSync(imported.native,"r");
  try{const bytes=Buffer.alloc(256);const count=fs.readSync(fd,bytes,0,bytes.length,0);
   const slot=JSON.parse(bytes.subarray(0,count).toString().split("\n")[0]);if(slot.title)title=slot.title;
  }catch{}finally{fs.closeSync(fd);}
 }
 return `${been}  ${item.modified.slice(0,10)}  ${item.spec.key.padEnd(13)} ${item.info.id.slice(0,13)}  ${where.slice(0,55)}  ${item.spec.live?"[live]":"[snapshot]"} :: ${excerpt(title).slice(0,95)}`;
}
function launchOMP(args:string[],cwd:string,env:Spec["env"]){
 // Never fall back to a different execution environment after failure.
 const project=env==="auv"?"mongla":env==="drone"?"meghdhut":env==="rupsha"?"rupsha":undefined;
 const command=project
  ?[path.join(H,".local/bin/omp-work"),project,...args]
  :[OMP,"--cwd",cwd,...args];
 if(env==="devenv")throw new Error("Archived DevEnv has no active project route. Select its replacement explicitly with omp-work.");
 console.log("Starting",env,"OMP; original Codex/Claude transcripts remain unchanged.");
 const result=Bun.spawnSync(command,{cwd:fs.existsSync(cwd)?cwd:H,stdin:"inherit",stdout:"inherit",stderr:"inherit"});
 process.exit(result.exitCode??1);
}
async function run(){
 const args=process.argv.slice(2); const cmd=args[0]??"";
 if(["help","-h","--help"].includes(cmd)){console.log(help);return;}
 if(!cmd){launchOMP([],process.cwd(),"host");return;}
 if(cmd==="refresh"){
  const p=Bun.spawnSync(["python3",path.join(STATE,"sync_sources.py")],{stdout:"inherit",stderr:"inherit"});
  if(p.exitCode)process.exit(p.exitCode??1);return;
 }
 if(cmd==="native"){launchOMP(["--resume"],process.cwd(),"host");return;}
 if(cmd==="extras"){
  const p=path.join(STATE,"nested-subagents.json");const a=JSON.parse(fs.readFileSync(p,"utf8"));
  console.log("Archived subsidiary Claude agent transcripts:",a.length,"(not independently resumable conversations)");
  console.log("All are preserved under",path.join(H,"Envs/backups/agent-history-2026-10-30"));return;
 }
 const registry=loadRegistry();
 if(cmd==="imports"){
  const vals=Object.entries(registry);
  console.log("Converted OMP conversations:",vals.length);
  for(const [k,v] of vals)console.log(k,v.native,fs.existsSync(v.native)?"OK":"MISSING");
  return;
 }
 if(!["list","browse","import"].includes(cmd)){console.error(help);process.exit(2);}
 const all=await scan();
 if(cmd==="list"){
  const q=args.slice(1).filter(x=>!x.startsWith("--")).join(" ").toLowerCase();
  const filtered=all.filter(x=>(x.key+" "+line(x,registry)).toLowerCase().includes(q));
  console.log("Importable foreign conversations",all.length,"match",filtered.length,
              "· snapshots + read-only live · ✓ already converted");
  for(const item of filtered.slice(0,q?150:55))console.log(item.key+" | "+line(item,registry));
  if(filtered.length>(q?150:55))console.log("…",filtered.length-(q?150:55),"more; narrow with a search phrase.");
  return;
 }
 let chosen:Entry|undefined;
 if(cmd==="import"){
  const q=args[1]?.toLowerCase();
  if(!q){console.error("Specify a session ID, ID prefix or full key; use 'list' first.");process.exit(2);}
  const options=all.filter(x=>x.key.toLowerCase()===q||x.info.id.toLowerCase()===q||x.info.id.toLowerCase().startsWith(q)||x.key.toLowerCase().endsWith("/"+q));
  if(options.length!==1){console.error("Matches:",options.length,"— choose an unambiguous ID",options.slice(0,20).map(x=>x.key));process.exit(2);}
  chosen=options[0];
 }else{
  const q=args.slice(1).filter(x=>!x.startsWith("--")).join(" ").toLowerCase();
  const filtered=all.filter(x=>(x.key+" "+line(x,registry)).toLowerCase().includes(q));
  if(!filtered.length){console.error("No matching session");process.exit(2);}
  const items=filtered.map((x,i)=>String(i).padStart(4,"0")+"  "+line(x,registry)).join("\n")+"\n";
  const p=Bun.spawn(["fzf","--ansi","--no-sort","--prompt=Session > ","--height=90%","--layout=reverse","--border","--header=Enter: import/resume · Esc: cancel · originals never modified"],{stdin:"pipe",stdout:"pipe",stderr:"inherit"});
  p.stdin.write(items);p.stdin.end();
  const selection=await new Response(p.stdout).text();
  if((await p.exited)!==0)return;
  const idx=Number(selection.slice(0,4));
  chosen=filtered[idx];
 }
 if(!chosen)throw new Error("No session selected");
 const lock=path.join(STATE,"import.lock");
 try{fs.mkdirSync(lock,{mode:0o700});}catch{throw new Error("Another import holds "+lock+"; retry after it finishes. Inspect before clearing a stale lock.");}
 let locked=true;
 const unlock=()=>{if(locked){fs.rmdirSync(lock);locked=false;}};
 process.on("exit",unlock);
 Object.assign(registry,loadRegistry());
 const src=chosen.info.path;
 const inputHash=await sha256(src);
 const previous=registry[chosen.key];
 // Older registrations may lack a digest; establish it from their preserved source.
 const previousHash=previous?.sourceSha256??(previous&&fs.existsSync(previous.sourcePath)?await sha256(previous.sourcePath):undefined);
 const changed=previous&&previousHash!==inputHash;
 if(changed&&!args.includes("--new-revision"))throw new Error("Source changed since import. Existing OMP work is preserved. Use --new-revision to import a separate continuation; never merge transcripts blindly.");
 const revisionKey=changed?chosen.key+"@"+inputHash.slice(0,16):chosen.key;
 const existing=registry[revisionKey];
 if(existing&&fs.existsSync(existing.native)){
  console.log("Already imported:",revisionKey,"native",existing.native);
  unlock();
  if(!args.includes("--no-open"))launchOMP(["--resume",existing.native],desiredCwd(chosen),chosen.spec.env);
  return;
 }
 // Freeze new live history before conversion; never write to its original.
 const snapshotDir=path.join(STATE,"revisions",chosen.spec.key,inputHash);
 fs.mkdirSync(snapshotDir,{recursive:true,mode:0o700});
 const snapshot=path.join(snapshotDir,path.basename(src));
 if(!fs.existsSync(snapshot)){fs.copyFileSync(src,snapshot,fs.constants.COPYFILE_EXCL);fs.chmodSync(snapshot,0o600);}
 if(await sha256(snapshot)!==inputHash||await sha256(src)!==inputHash)throw new Error("Source changed while snapshotting; retry once the original session is idle.");
 console.log("IMPORTING",revisionKey,"from preserved snapshot",chosen.bytes,"bytes");
 const imported=await persistForeignSession(chosen.spec.store,{...chosen.info,path:snapshot},{
  fallbackCwd:fs.existsSync(chosen.info.cwd)?undefined:desiredCwd(chosen),
  suppressBreadcrumb:true,
 });
 // The source's old model may be unavailable in OMP (e.g. historical Opus).
 // Keep historical model events intact, then append an explicit current default
 // so a normal 'omp --resume' works without a special CLI override.
 imported.appendModelChange("openai-codex/gpt-6.1-sol","default");
 await imported.flush();
 const native=imported.getSessionFile();
 await imported.close();
 if(!native||!fs.existsSync(native))throw new Error("No native OMP session after conversion.");
 const outputHash=await sha256(snapshot);
 if(inputHash!==outputHash)throw new Error("SOURCE SNAPSHOT HASH MISMATCH: STOP. Native session is "+native);
 registry[revisionKey]={native,imported:new Date().toISOString(),sourcePath:snapshot,sourceSha256:inputHash,env:chosen.spec.env};
 saveRegistry(registry);
 unlock();
 console.log("NATIVE_IMPORT_OK",chosen.key,"source_sha256",inputHash.slice(0,16),"native_file",native);
 console.log("Use 'omp-unified native' from host to see imported sessions across projects.");
 if(!args.includes("--no-open"))launchOMP(["--resume",native],desiredCwd(chosen),chosen.spec.env);
}
await run().catch(e=>{console.error("unified OMP failed:",e);process.exit(1)});
