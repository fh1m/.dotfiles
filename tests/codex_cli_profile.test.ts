import { afterEach, describe, expect, test } from "bun:test";
import { spawn } from "node:child_process";
import { chmod, mkdtemp, mkdir, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const roots:string[]=[];
afterEach(async()=>{for(const root of roots.splice(0))await rm(root,{recursive:true,force:true});});
async function run(executable:string,args:string[],env:NodeJS.ProcessEnv){
 const child=spawn(process.execPath,[executable,...args],{env,stdio:["ignore","pipe","pipe"]});let stdout="",stderr="";
 child.stdout.setEncoding("utf8").on("data",chunk=>stdout+=chunk);child.stderr.setEncoding("utf8").on("data",chunk=>stderr+=chunk);
 const code=await new Promise<number|null>(resolve=>child.once("close",resolve));return {code,stdout,stderr};
}

describe("explicit Codex CLI profiles",()=>{
 test("add uses the requested CODEX_HOME identity and registers it as monitored",async()=>{
  const root=await mkdtemp(path.join(os.tmpdir(),"sensei-codex-profile-"));roots.push(root);
  const profile=path.join(root,"work-profile"),fixture=path.join(root,"codex-fixture"),cli=path.resolve(import.meta.dir,"../home/.local/bin/sensei-codex-accounts");
  await mkdir(profile);await writeFile(path.join(profile,"auth.json"),"{}");
  await writeFile(fixture,`#!/usr/bin/env bun\nlet input="";for await(const chunk of process.stdin){input+=chunk;for(;;){const split=input.indexOf("\\n");if(split<0)break;const line=input.slice(0,split);input=input.slice(split+1);const request=JSON.parse(line);if(!request.id)continue;const chosen=process.env.CODEX_HOME===${JSON.stringify(profile)};const result=request.method==="account/read"?{account:{type:"chatgpt",email:chosen?"chosen@example.test":"wrong@example.test",accountId:chosen?"chosen-account":"wrong-account",planType:"plus"}}:{rateLimits:{primary:{usedPercent:10,resetsAt:"2030-01-01T00:00:00Z"}}};console.log(JSON.stringify({id:request.id,result}));}}\n`);
  await chmod(fixture,0o700);
  const env={...process.env,HOME:root,OMP_AGENT_DIR:path.join(root,".omp/agent"),CODEX_EXECUTABLE:fixture};
  const added=await run(cli,["add","--profile",profile,"--name","Work account"],env);expect(added.code).toBe(0);expect(JSON.parse(added.stdout).ok).toBe(true);
  const listed=await run(cli,["list"],env);expect(listed.code).toBe(0);const accounts=JSON.parse(listed.stdout).accounts;
  const selected=accounts.find((account:{source:string;identity:string})=>account.source==="profile"&&account.identity==="chosen-account");expect(selected).toEqual(expect.objectContaining({email:"chosen@example.test",name:"Work account",monitored:true}));
  expect(accounts.some((account:{identity:string})=>account.identity==="wrong-account")).toBe(false);
  const removed=await run(cli,["remove","--account",selected.id],env);expect(removed.code).toBe(0);expect(await Bun.file(path.join(profile,"auth.json")).text()).toBe("{}");
  const hidden=await run(cli,["list"],env),after=JSON.parse(hidden.stdout).accounts.find((account:{id:string})=>account.id===selected.id);expect(after.monitored).toBe(false);
 });
});
