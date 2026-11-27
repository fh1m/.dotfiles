import type {ExtensionAPI} from '@oh-my-pi/pi-coding-agent';
import fs from 'node:fs';
import path from 'node:path';
const H='/home/fh1m';

export default function(pi:ExtensionAPI){
 pi.setLabel('Den | read-only Wayland inspection');
 pi.registerTool({
  name:'den_desktop',label:'Inspect Hyprland desktop',
  description:'Read-only Hyprland display/window inventory or screenshot. Use when native computer capture is unavailable on Wayland. No input, focus changes, clipboard access, or control. Captures stay private on the host. Select a connected output by exact name.',
  parameters:pi.zod.object({action:pi.zod.enum(['inspect','capture']),monitor:pi.zod.string().optional()}),
  async execute(_id,p,signal){
   const forwarded=fs.existsSync('/run/.containerenv')||fs.existsSync('/.dockerenv');
   const invoke=async(argv:string[],env?:Record<string,string|undefined>)=>{
    const child=Bun.spawn(forwarded?['/usr/bin/distrobox-host-exec',...argv]:argv,{stdout:'pipe',stderr:'pipe',env:env?{...process.env,...env}:process.env,signal});
    const [stdout,stderr,exit]=await Promise.all([new Response(child.stdout).text(),new Response(child.stderr).text(),child.exited]);
    if(exit!==0)throw new Error(argv[0]+': '+stderr.slice(0,1500));
    return stdout;
   };
   const instances=JSON.parse(await invoke(['hyprctl','instances','-j'])) as {instance:string,wl_socket:string}[];
   if(instances.length!==1)throw new Error('Expected exactly one Hyprland session; refusing to guess a desktop.');
   const runtime={XDG_RUNTIME_DIR:'/run/user/1000',HYPRLAND_INSTANCE_SIGNATURE:instances[0].instance,WAYLAND_DISPLAY:instances[0].wl_socket};
   const monitors=JSON.parse(await invoke(['env',...Object.entries(runtime).map(([k,v])=>k+'='+v),'hyprctl','monitors','-j'])) as {name:string,focused:boolean}[];
   if(p.action==='inspect'){
    const clients=JSON.parse(await invoke(['env',...Object.entries(runtime).map(([k,v])=>k+'='+v),'hyprctl','clients','-j']));
    return {content:[{type:'text',text:JSON.stringify({monitors,clients},null,2)}]};
   }
   const output=p.monitor||monitors.find(m=>m.focused)?.name;
   if(!output||!monitors.some(m=>m.name===output))throw new Error('Monitor is not connected: '+String(output));
   const folder=path.join(H,'.local/state/omp-den/captures');fs.mkdirSync(folder,{recursive:true,mode:0o700});
   const file=path.join(folder,Date.now()+'-'+crypto.randomUUID()+'.png');
   await invoke(['env',...Object.entries(runtime).map(([k,v])=>k+'='+v),'grim','-o',output,file]);
   fs.chmodSync(file,0o600);
   return {content:[{type:'text',text:'Read-only capture of '+output+': '+file},{type:'image',data:fs.readFileSync(file).toString('base64'),mimeType:'image/png'}]};
  }
 });
}
