import type {ExtensionAPI} from "@oh-my-pi/pi-coding-agent";
import {SessionManager} from "/home/fh1m/.bun/install/global/node_modules/@oh-my-pi/pi-coding-agent/src/session/session-manager.ts";
import fs from "node:fs";
import path from "node:path";
const H="/home/fh1m",R=H+"/Envs/dockers";
const host=process.env.HOME===H&&!fs.existsSync("/run/.containerenv");
const registry=JSON.parse(fs.readFileSync(H+"/.local/share/omp-den/projects.json","utf8"));
const labs=Object.entries(registry.projects).map(([id,p]:[string,any])=>({id,env:p.environment==="host"?"":p.environment,dir:p.cwd,ros:p.ros}));
const q=(s:string)=>"'"+s.replaceAll("'","'\\''")+"'";
function lab(cwd:string){
 const c=fs.existsSync(cwd)?fs.realpathSync.native(cwd):path.resolve(cwd);
 return labs.find(x=>c===x.dir||c.startsWith(x.dir+"/"))||
   labs.find(x=>x.env&&(c===R+"/"+x.env||c.startsWith(R+"/"+x.env+"/")));
}
const meta=(x:any)=>{
 const cwd=String(x.cwd||"");
 return {name:lab(cwd)?.id||path.basename(cwd)||"host",
 date:new Date(x.modified||Date.now()).toISOString().slice(0,16).replace("T"," "),
 title:String(x.title||x.firstMessage||"Untitled").replace(/\s+/g," ").slice(0,75),cwd};
};
export default function(pi:ExtensionAPI){
 pi.setLabel("Sensei | unified OMP");
 const setStatus=(ctx:any)=>{
  if(ctx.agent.kind==="main"){const x=lab(ctx.cwd);
   ctx.ui.setStatus("sensei","⌂ "+(x?x.id+" · "+(x.env||"host"):"arete · host")+" | /labs · /resume");}
 };
 pi.on("session_start",(_e,ctx)=>setStatus(ctx));
 pi.on("session_switch",(_e,ctx)=>setStatus(ctx));
 // Host OMP transparently executes ROS/CUDA shell calls inside the owning container.
 pi.on("tool_call",(event,ctx)=>{
  if(!host||event.toolName!=="bash")return;
  const a=event.input as Record<string,unknown>;
  if(typeof a.command!=="string"||!a.command.trim())return;
  const cwd=typeof a.cwd==="string"&&a.cwd?a.cwd:ctx.cwd;
  const x=lab(cwd);
  if(!x?.env||/^\s*(docker|distrobox|podman)\s/.test(a.command))return;
  const script="source /opt/ros/"+x.ros+"/setup.bash || exit; cd "+q(cwd)+" && bash -c "+q(a.command);
  const command="docker exec -u fh1m -w "+q(cwd)+" "+q(x.env)+" bash -c "+q(script);
  return {input:{...a,cwd:H,command}};
 });
 pi.registerTool({
  name:"lab_exec",label:"Robotics environment terminal",
  description:"Run commands explicitly in host, auv-ros2 (Mongla/Humble), drone-ros2 (Meghdhut/Humble), or rupsha_dev (Rupsha/Jazzy). Never falls back to another runtime. Output is bounded; nonzero exit remains an error.",
  parameters:pi.zod.object({
   environment:pi.zod.enum(["host","auv-ros2","drone-ros2","rupsha_dev"]),
   command:pi.zod.string(),cwd:pi.zod.string().optional()
  }),
  async execute(_id,p,signal){
   const cwd=p.cwd||labs.find(x=>x.env===p.environment)?.dir||H;
   const ros=labs.find(x=>x.env===p.environment)?.ros;
   const code=(p.environment==="host"?"":"source /opt/ros/"+ros+"/setup.bash || exit; ")+"cd "+q(cwd)+" && bash -c "+q(p.command);
   const args=p.environment==="host"?["bash","-c",code]:
    ["docker","exec","-u","fh1m","-w",cwd,p.environment,"bash","-c",code];
   const ps=Bun.spawn(args,{cwd:H,stdout:"pipe",stderr:"pipe",signal});
   const bounded=async(stream:ReadableStream<Uint8Array>,limit:number)=>{
    const reader=stream.getReader(),decoder=new TextDecoder();let out="",used=0,truncated=false;
    for(;;){const {done,value}=await reader.read();if(done)break;
     const take=Math.min(value.byteLength,Math.max(0,limit-used));
     if(take)out+=decoder.decode(value.subarray(0,take),{stream:true});
     used+=take;if(take<value.byteLength)truncated=true;
    }
    return out+decoder.decode()+(truncated?"\n[output truncated; redirect full evidence to a project log]":"");
   };
   const [out,err,exit]=await Promise.all([bounded(ps.stdout,35000),bounded(ps.stderr,10000),ps.exited]);
   return {content:[{type:"text",text:"ENV="+p.environment+" CWD="+cwd+" EXIT="+exit+"\n"+out+"\n"+err}],
    details:{exit},isError:exit!==0};
  }
 });
 const resumeInRuntime=async(selected:any,ctx:any)=>{
  const target=lab(selected.cwd)?.env||"host";
  const current=host?"host":labs.find(x=>x.env&&process.env.HOME===R+"/"+x.env)?.env;
  if(target===current){await ctx.switchSession(selected.path);return;}
  // A session switch cannot change this process's OS/container or LSP runtime.
  // Open the same native session in the correct runtime, preserving this one.
  const project=lab(selected.cwd);
  const launch=project?.env
   ?[H+"/.local/bin/omp-work",project.id,"--resume",selected.path]
   :[H+"/.bun/bin/omp","--resume",selected.path];
  const command=[...(!host?["/usr/bin/distrobox-host-exec"]:[]),"alacritty","-e",...launch];
  const child=Bun.spawn(command,{stdin:"ignore",stdout:"ignore",stderr:"ignore"});
  child.unref();
  ctx.ui.notify("Opening "+(project?.id||"host")+" in "+target+"; this session remains open.","info");
 };
 // Replace built-in /resume picker with an OMP-native all-project selector.
 // Native builtin slash commands dispatch before extension commands.
 // Intercept at the documented INPUT middleware step and rewrite to our
 // extension command, retaining native /resume @claude and @codex.
 pi.on("input",(event)=>{
   const txt=event.text.trim();
   if(!/^\/resume(?:\s|$)/.test(txt))return;
   if(/^\/resume\s+@(claude|codex)\s*$/.test(txt))return;
   return {text:"/allresume"+txt.slice(7)};
 });
 pi.registerCommand("allresume",{
  description:"Resume all project sessions, newest first. '/resume mongla' searches Mongla.",
  handler:async(args,ctx)=>{
   const list=await SessionManager.listAllForPicker();
   const search=args.trim().toLowerCase();
   const key=(x:any)=>{const a=meta(x);return (a.name+" "+a.date+" "+a.title+" "+a.cwd+" "+x.id+" "+x.path).toLowerCase()};
   let filtered=list.filter(x=>!search||key(x).includes(search));
   const pick=(xs:typeof list)=>xs.map((x,i)=>{
     const a=meta(x);
     return {value:String(i),label:a.date+" · "+a.name+" · "+a.title+" · #"+String(x.id).slice(-10),
       description:a.cwd.replace(H,"~")+" · "+String(x.id).slice(0,13)};
   });
   if(!filtered.length){ctx.ui.notify("No sessions matching "+args,"warning");return;}
   if(search&&filtered.length===1){
    await resumeInRuntime(filtered[0],ctx);
    return;
   }
   if(!search&&filtered.length>100){
    const latest=filtered.slice(0,100);
    const searchLabel="⌕ Search all sessions";
    const recentOptions=pick(latest);
    const choice=await ctx.ui.select("Sessions across ALL projects | newest first",[
     {label:searchLabel,description:"Filter by project, date, prompt, session ID"},
     ...recentOptions]);
    if(choice===undefined)return;
    if(choice!==searchLabel){
     const index=recentOptions.findIndex(x=>x.label===choice);
     const selected=latest[index];
     if(selected)await resumeInRuntime(selected,ctx);
     return;
    }
    const query=(await ctx.ui.input("Search all sessions","mongla, meghdhut, YYYY-MM-DD, ID, topic"))?.trim().toLowerCase();
    if(!query)return;
    filtered=list.filter(x=>key(x).includes(query));
   }
   if(!filtered.length){ctx.ui.notify("No matching sessions","warning");return;}
   const results=filtered.slice(0,200);
   const choices=pick(results);
   const chosen=await ctx.ui.select("Resume | "+filtered.length+" matching sessions | newest first",choices);
   const index=choices.findIndex(x=>x.label===chosen);
   if(index>=0&&results[index])await resumeInRuntime(results[index],ctx);
  }
 });
 pi.registerCommand("labs",{
  description:"Show ROS container context and transparent command routing",
  handler:async(_args,ctx)=>{
   const x=lab(ctx.cwd);
   ctx.ui.notify("Current: "+(x?.id||"host")+"; use omp-work mongla|rupsha|meghdhut|den for a new project runtime. /resume searches shared history. lab_exec explicitly selects all three containers; stopped containers fail instead of running locally.","info");
  }
 });
}