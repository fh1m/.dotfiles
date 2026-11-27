import { afterEach, describe, expect, test } from "bun:test";
import { mkdtemp, mkdir, rm, writeFile, chmod } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { readProfileUsage } from "../home/.local/share/sensei/codex_app_server.ts";

const roots:string[]=[];
afterEach(async()=>{for(const root of roots.splice(0))await rm(root,{recursive:true,force:true});});
async function fixture() {
 const root=await mkdtemp(path.join(os.tmpdir(),"sensei-codex-fixture-"));roots.push(root);
 const exe=path.join(root,"codex");
 await writeFile(exe,`#!/usr/bin/env bun\nlet buf="";for await(const chunk of process.stdin){buf+=chunk;for(;;){const n=buf.indexOf("\\n");if(n<0)break;const m=JSON.parse(buf.slice(0,n));buf=buf.slice(n+1);if(!m.id)continue;let result={};if(m.method==="account/read")result={account:{type:"chatgpt",email:process.env.CODEX_HOME.endsWith("/a")?"a@example.test":"b@example.test",accountId:process.env.CODEX_HOME.endsWith("/a")?"acct-a":"acct-b",planType:"plus"}};if(m.method==="account/rateLimits/read")result={rateLimits:{primary:{usedPercent:21,resetsAt:"2030-01-01T00:00:00Z"}},rateLimitsByLimitId:{primary:{usedPercent:21}}};console.log(JSON.stringify({id:m.id,result}));}}\n`);
 await chmod(exe,0o700);await mkdir(path.join(root,"a"));await mkdir(path.join(root,"b"));return {root,exe,a:path.join(root,"a"),b:path.join(root,"b")};
}
describe("Codex app-server profile isolation",()=>{
 test("uses requested CODEX_HOME and returns only that profile's account and quota",async()=>{const f=await fixture();const result=await readProfileUsage({executable:f.exe,profileDir:f.a});expect(result.identity).toBe("acct-a");expect(result.account.email).toBe("a@example.test");expect((result.rateLimits as {primary:{usedPercent:number}}).primary.usedPercent).toBe(21);});
 test("rejects identity crossover rather than returning another profile's quota",async()=>{const f=await fixture();await expect(readProfileUsage({executable:f.exe,profileDir:f.a,expectedIdentity:"acct-b"})).rejects.toThrow("identity changed");});
 test("server errors fail closed",async()=>{const f=await fixture();const bad=path.join(f.root,"bad");await writeFile(bad,`#!/usr/bin/env bun\nfor await(const c of process.stdin){for(const l of c.toString().split("\\n")){try{const m=JSON.parse(l);if(m.id)console.log(JSON.stringify({id:m.id,error:{message:"offline"}}))}catch{}}}\n`);await chmod(bad,0o700);await expect(readProfileUsage({executable:bad,profileDir:f.a})).rejects.toThrow();});
 test("malformed protocol rows fail closed",async()=>{const f=await fixture();const bad=path.join(f.root,"malformed");await writeFile(bad,`#!/usr/bin/env bun\nfor await(const c of process.stdin){process.stdout.write("not-json\\n")}\n`);await chmod(bad,0o700);await expect(readProfileUsage({executable:bad,profileDir:f.a})).rejects.toThrow("Malformed");});
 test("aborts and reaps the exact owned profile process",async()=>{const f=await fixture();const controller=new AbortController();controller.abort();await expect(readProfileUsage({executable:f.exe,profileDir:f.a,signal:controller.signal})).rejects.toThrow("cancelled");});
});
