import {test,expect} from 'bun:test';
import extension from '../home/.omp/agent/extensions/sensei-unified';
import type {ExtensionAPI} from '/home/fh1m/.bun/install/global/node_modules/@oh-my-pi/pi-coding-agent/src/extensibility/extensions/types';
type Call={toolName:string,input:{command:string,cwd:string}};
type Hook=(event:Call,ctx:{cwd:string})=>{input:{command:string}}|undefined;
type Terminal={execute(id:string,p:{environment:string,cwd:string,command:string},signal:AbortSignal):Promise<{isError:boolean,details:{exit:number},content:{text:string}[]}>};
const handlers:Record<string,Hook>={};
let terminalTool:Terminal;
const scalar={optional(){return this;}};
const harness={setLabel(){},on(name:string,fn:Hook){handlers[name]=fn;},registerTool(tool:Terminal){terminalTool=tool;},registerCommand(){},zod:{object<T>(x:T){return x;},enum(){return scalar;},string(){return scalar;}}};
// Registration-only harness: the tested paths never call the rest of ExtensionAPI.
extension(harness as unknown as ExtensionAPI);

test('Rupsha uses Jazzy in its owning container rather than host Humble',()=>{
 const result=handlers.tool_call({toolName:'bash',input:{command:'printf hello',cwd:'/home/fh1m/tmp/rupsha_ws'}},{cwd:'/home/fh1m'});
 expect(result.input.command).toContain("'rupsha_dev'");
 expect(result.input.command).toContain('/opt/ros/jazzy/setup.bash || exit');
});

test('similarly named sibling is not routed into robotics',()=>{
 const result=handlers.tool_call({toolName:'bash',input:{command:'printf hello',cwd:'/home/fh1m/tmp/rupsha_ws-old'}},{cwd:'/home/fh1m'});
 expect(result).toBeUndefined();
});

test('terminal integration retains failing exit and bounded output',async()=>{
 const result=await terminalTool.execute('test',{environment:'host',cwd:'/tmp',command:"python3 -c 'print(\"x\"*100000)' ; exit 7"},new AbortController().signal);
 expect(result.isError).toBe(true);
 expect(result.details.exit).toBe(7);
 expect(result.content[0].text).toContain('output truncated');
 expect(result.content[0].text.length).toBeLessThan(36000);
});

test('bad working directory cannot execute payload in parent directory',async()=>{
 const result=await terminalTool.execute('test',{environment:'host',cwd:'/no-such-omp-project',command:'printf PAYLOAD_EXECUTED'},new AbortController().signal);
 expect(result.isError).toBe(true);
 expect(result.content[0].text).not.toContain('\nPAYLOAD_EXECUTED');
});
