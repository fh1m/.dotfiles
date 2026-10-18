"""Small full-colour engineering motion over the owner's existing wallpaper."""
import fcntl,hashlib,json,subprocess,struct,os
from pathlib import Path
VERSION=4
STAGES={'main':(0,8,'SKETCH'),'upper':(8,16,'BUILD'),'lower':(16,24,'CALIBRATE'),'homie':(24,32,'SIMULATE'),'screenpad':(32,40,'UNDERSTAND')}

def render(role,width,height,base,assets,cache,away=False,seconds=40):
 if role not in STAGES or type(width)is not int or type(height)is not int or not 320<=width<=7680 or not 200<=height<=4320:raise ValueError('Unsupported native output')
 base=Path(base);assets=Path(assets);cache=Path(cache)
 if not base.is_file():raise ValueError('Saved wallpaper is unavailable; preserving fallback')
 actor=assets/'field-actors-v4.png'
 digest=hashlib.sha256(Path(__file__).read_bytes()+base.read_bytes()+actor.read_bytes()+json.dumps([role,width,height,away,seconds]).encode()).hexdigest()[:20]
 folder=cache/digest;folder.mkdir(parents=True,exist_ok=True,mode=0o700);result=folder/'story.png'
 with (folder/'.render.lock').open('a') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  if result.exists() and (folder/'complete.json').exists():return result
  def run(args):subprocess.run(['taskset','-c',str(max(os.sched_getaffinity(0))),'nice','-n','19','ionice','-c','3',*args],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,timeout=1800,check=True)
  begin,end,label=STAGES[role];scale=width/1920;h=height/scale;stage_y=.48*h if role!='screenpad' else .72*h
  # Tiny engineering fixture; the saved wallpaper remains the scene, not a new backdrop.
  text='OUT COLLECTING QUESTIONS' if away and role=='homie' else label
  svg=folder/'fixture.svg';fixture=folder/'fixture.png'
  x=550 if role!='screenpad' else 1370;y=stage_y
  svg.write_text(f'''<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 1920 {h}">
<g transform="translate({x},{y})"><path d="M-90 0H110M-65 0V18M90 0V18" stroke="#655461" stroke-width="3"/><rect x="-80" y="-64" width="58" height="40" rx="3" fill="#100d15" stroke="#74405e"/>
<path d="M-73-36L-65-36L-58-47L-51-31L-42-41L-30-41" fill="none" stroke="#6eaaac" stroke-width="1.5"/>
<text x="-80" y="39" fill="#9b818f" font-family="JetBrains Mono,monospace" font-size="10" letter-spacing="2">{text}</text>
<path d="M-80 49H110" stroke="#442e3e" stroke-width="1"/></g></svg>''')
  run(['rsvg-convert','-o',str(fixture),str(svg)])
  still=folder/'still.png'
  run(['ffmpeg','-nostdin','-y','-v','error','-threads','1','-i',str(base),'-i',str(fixture),'-filter_complex_threads','1','-filter_complex',f'[0:v]scale={width}:{height}:force_original_aspect_ratio=increase,crop={width}:{height},colorchannelmixer=rr=.8:gg=.8:bb=.8[b];[b][1:v]overlay=0:0[out]','-map','[out]','-frames:v','1',str(still)])
  # Only the small foreground changes. APNG retains every original background colour.
  aw,ah=struct.unpack('>II',actor.read_bytes()[16:24]);cw=aw//8;ch=ah//2
  # Native transparent atlas, eight columns and two rows.
  filters=['[1:v]split=2[a][d]',f"[a]crop={cw}:{ch}:x='floor(mod(floor(n/3),8)*{aw}/8)':y=0,scale={round(110*scale)}:{round(146*scale)}[auv]",f"[d]crop={cw}:{ch}:x='floor(mod(floor(n/3),8)*{aw}/8)':y={ch},scale={round(112*scale)}:{round(149*scale)}[drone]"]
  # Vehicle visibly works during its chapter. The same parcel advances to the next host.
  px=f'({x}+22+10*sin(t*1.5))*{scale}';py=f'({y}-146+3*sin(t*2))*{scale}'
  filters.append(f"[0:v][auv]overlay=x='{px}':y='{py}':enable='between(t,{begin},{end})':shortest=1[stage]")
  filters.append(f"[stage][drone]overlay=x='({x}-230+400*(t-{end-3})/3)*{scale}':y='({y}-230+5*sin(t*3))*{scale}':enable='between(t,{end-3},{end})':shortest=1[travel]")
  # A 4px light marks the shared chapter progression, not real experiment telemetry.
  filters.append(f"[travel][2:v]overlay=x='({x}-80+190*mod(t,40)/40)*{scale}':y='{(y+47)*scale}':shortest=1,format(rgba)[out]".replace('format(rgba)','format=rgba'))
  target=folder/'story.partial.png'
  run(['ffmpeg','-nostdin','-y','-v','error','-threads','1','-loop','1','-framerate','25','-i',str(still),'-loop','1','-framerate','25','-i',str(actor),'-f','lavfi','-i',f'color=c=0xf23d70:s={max(2,round(4*scale))}x{max(2,round(4*scale))}:r=25','-filter_complex_threads','1','-filter_complex',';'.join(filters),'-map','[out]','-t',str(seconds),'-c:v','apng','-threads:v','1','-compression_level','3','-plays','0','-f','apng',str(target)])
  target.replace(result);(folder/'complete.json').write_text(json.dumps({'version':VERSION,'role':role,'width':width,'height':height,'fps':25,'seconds':seconds,'away':away,'base_sha256':hashlib.sha256(base.read_bytes()).hexdigest(),'hash':digest}))
  return result
