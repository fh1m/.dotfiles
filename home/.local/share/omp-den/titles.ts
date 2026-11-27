import {SessionManager} from "@HOME@/.bun/install/global/node_modules/@oh-my-pi/pi-coding-agent/src/session/session-manager.ts";
import fs from 'node:fs';
import path from 'node:path';
const manifest=process.argv[2];
if(!manifest)throw new Error('Expected private candidate manifest');
const candidates=JSON.parse(fs.readFileSync(manifest,'utf8'));
const backup=path.join(path.dirname(manifest),'before');fs.mkdirSync(backup,{mode:0o700});
const results=[];
for(const candidate of candidates){
 const stat=fs.statSync(candidate.path);
 const dest=path.join(backup,path.basename(candidate.path));
 fs.copyFileSync(candidate.path,dest,fs.constants.COPYFILE_EXCL);fs.chmodSync(dest,0o600);
 // OMP acquires the cross-process session lease before reading/writing.
 // An active session is skipped, never rewritten beneath its owner.
 const title=await SessionManager.renameSessionTitle(candidate.path,candidate.title);
 if(title)fs.utimesSync(candidate.path,stat.atime,stat.mtime);
 results.push({...candidate,result:title?'renamed':'busy-or-unavailable',title});
}
const output=path.join(path.dirname(manifest),'results.json');
fs.writeFileSync(output,JSON.stringify(results,null,2)+'\n',{mode:0o600});
console.log(JSON.stringify({renamed:results.filter(x=>x.result==='renamed').length,skipped:results.filter(x=>x.result!=='renamed').length,receipt:output}));
