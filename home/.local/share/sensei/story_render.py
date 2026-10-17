"""Native-resolution animation exports from a single minimal Den scene.

SVG geometry is resolution-independent; architecture and actors are original imagegen
assets. FFmpeg composes the timeline as video, then writes a delta-optimized GIF.
No live scene graph, model, browser or per-frame Python renderer is needed to play it.
"""
import base64,hashlib,json,os,subprocess,tempfile,fcntl
from pathlib import Path
VERSION=3
PLACEMENTS={'upper':(-1920,-1080),'lower':(-1920,0),'main':(0,0),'screenpad':(0,1080),'homie':(960,-1080)}

def image(path,x,y,w,h):
 data=base64.b64encode(path.read_bytes()).decode()
 return f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="data:image/png;base64,{data}"/>'

def scene(assets,role,away=False):
 # Sparse connected architecture, one horizon, no separate scene per display.
 sky='''<defs><linearGradient id="sky" x2="0" y2="1"><stop stop-color="#172340"/><stop offset=".52" stop-color="#42577d"/><stop offset="1" stop-color="#a97e91"/></linearGradient><linearGradient id="sea" x2="0" y2="1"><stop stop-color="#345b72"/><stop offset="1" stop-color="#132b42"/></linearGradient></defs>
<rect x="-3000" y="-2000" width="9000" height="4500" fill="url(#sky)"/>
<path d="M-3000 760L-2500 760L-2500 660L-2250 660L-2250 570L-1980 570L-1980 630L-1630 630L-1630 730L-1200 730L-1200 650L-930 650L-930 590L-690 590L-690 690L-300 690L-300 760L400 760L400 700L800 700L800 610L1080 610L1080 670L1510 670L1510 720L2100 720L2100 640L2600 640L2600 710L6000 710V1100H-3000Z" fill="#30425d"/>
<rect x="-3000" y="900" width="9000" height="2000" fill="url(#sea)"/>
<path d="M-3000 900H6000" stroke="#83adbc" stroke-width="3"/>
<circle cx="1260" cy="-600" r="65" fill="#e6caa6" opacity=".65"/>
<path d="M-1650-270H2470" stroke="#192638" stroke-width="24"/>
<path d="M-1650-283H2470" stroke="#64758d" stroke-width="3"/>
<path d="M-1300-250H2300V650H1120V990H-1250V1370H2100" fill="none" stroke="#b33768" stroke-width="5"/>
<path d="M-1920 790H-850V850H-1920Z M780 760H1910V820H780Z" fill="#22384b"/>
<path d="M-1920 790H-850 M780 760H1910" fill="none" stroke="#77939b" stroke-width="4"/>
'''
 detail=''.join(f'<rect x="{x}" y="{y}" width="{w}" height="3" fill="#7296aa" opacity=".25"/>' for x,y,w in [(-1700,1020,190),(-950,1120,100),(-300,960,160),(200,1210,230),(900,1060,120),(1600,1270,160),(2300,990,130)])
 structures=''.join([image(assets/'observatory-v3.png',-1810,-970,1070,715),image(assets/'lighthouse-v3.png',1590,-1070,1140,840),image(assets/'rooftop-v3.png',850,260,700,460),image(assets/'dock-v3.png',-1830,210,910,610)])
 sensors=''.join(f'<rect x="{x}" y="1370" width="26" height="60" fill="#284b60"/><rect x="{x+4}" y="1370" width="18" height="5" fill="#77c5bf"/>' for x in (280,620,1110,1530))
 label='<text x="-1640" y="880" font-family="JetBrains Mono,monospace" font-size="16" fill="#b2c2ce" letter-spacing="2">MONGLA / SMALL BASELINES. BIG OCEANS.</text><text x="1200" y="810" font-family="JetBrains Mono,monospace" font-size="18" fill="#b2c2ce" letter-spacing="4">FH1M / FIELD LAB</text>'
 if away and role=='homie':label+='<rect x="1020" y="-420" width="560" height="92" rx="5" fill="#263047" stroke="#b2879f" stroke-dasharray="10 8"/><text x="1050" y="-382" font-family="JetBrains Mono,monospace" font-size="19" fill="#e7c9ab">ARETE IS OUT COLLECTING QUESTIONS</text><text x="1050" y="-350" font-family="JetBrains Mono,monospace" font-size="15" fill="#b8c6d8">One piece travelling. The den stays warm.</text>'
 return sky+detail+structures+sensors+label

def render(role,width,height,assets,cache,away=False,seconds=16):
 if role not in PLACEMENTS or type(width) is not int or type(height) is not int or not 320<=width<=7680 or not 200<=height<=4320:raise ValueError('Unsupported native output dimensions')
 assets=Path(assets);cache=Path(cache)
 names=['observatory-v3.png','lighthouse-v3.png','rooftop-v3.png','dock-v3.png','actors-v2.png']
 digest=hashlib.sha256(Path(__file__).read_bytes()+json.dumps([role,width,height,away,seconds]).encode())
 for name in names:digest.update((assets/name).read_bytes())
 key=digest.hexdigest()[:20];directory=cache/key;result=directory/'story.gif'
 if result.is_file() and (directory/'complete.json').is_file():return result
 directory.mkdir(parents=True,exist_ok=True,mode=0o700)
 x,y=PLACEMENTS[role];logical_w=1920;logical_h=550 if role=='screenpad' else 1080
 with (directory/'.render.lock').open('a') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  if result.is_file() and (directory/'complete.json').is_file():return result
  svg=directory/'scene.svg';base=directory/'still.png';palette=directory/'palette.png';target=directory/'story.partial.gif'
  svg.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="{x} {y} {logical_w} {logical_h}">'+scene(assets,role,away)+'</svg>')
  def run(argv):subprocess.run(['nice','-n','15','ionice','-c','3',*argv],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,timeout=900)
  run(['rsvg-convert','-w',str(width),'-h',str(height),'-o',str(base),str(svg)])
  # One-frame palette creation avoids buffering a full 4K animation in RAM.
  run(['ffmpeg','-nostdin','-v','error','-y','-threads','1','-i',str(base),'-i',str(assets/'actors-v2.png'),'-filter_complex_threads','1','-filter_complex','[0:v]scale=512:288[a];[1:v]scale=324:288[b];[a][b]hstack,palettegen=max_colors=256:reserve_transparent=1[p]','-map','[p]','-frames:v','1',str(palette)])
  sx=width/logical_w;sy=height/logical_h
  # A single 16-second story, projected identically into every output.
  positions=[('-1500+600*min(t,6)','-460+8*sin(t*5)','between(t,0,8)',112,0,295),('-1400+900*(t-8)','850+100*(t-8)+12*sin(t*2)','between(t,8,12)',144,295,296),('300+600*(t-12)','1350+8*sin(t*4)','between(t,12,14)',112,591,266),('1500+15*sin(t*3)','650-600*(t-14)','between(t,14,16)',100,857,325)]
  filters=['[1:v]split=4[s0][s1][s2][s3]'];last='0:v'
  for index,(px,py,enable,size,cy,ch) in enumerate(positions):
   filters.append(f"[s{index}]crop=329:{ch}:x='if(eq(mod(n,4),0),1,if(eq(mod(n,4),1),333,if(eq(mod(n,4),2),666,998)))':y={cy},scale={round(size*sx)}:{round(size*sy)}:flags=neighbor[a{index}]")
   filters.append(f"[{last}][a{index}]overlay=x='(({px})-({x}))*{sx}':y='(({py})-({y}))*{sy}':enable='{enable}':shortest=1[o{index}]");last=f'o{index}'
  filters.append(f'[{last}][2:v]paletteuse=dither=none:diff_mode=rectangle[out]')
  run(['ffmpeg','-nostdin','-v','error','-y','-threads','1','-loop','1','-framerate','8','-i',str(base),'-loop','1','-framerate','8','-i',str(assets/'actors-v2.png'),'-i',str(palette),'-filter_complex_threads','1','-filter_complex',';'.join(filters),'-map','[out]','-t',str(seconds),'-gifflags','+offsetting+transdiff','-loop','0',str(target)])
  target.replace(result);(directory/'complete.json').write_text(json.dumps({'version':VERSION,'role':role,'width':width,'height':height,'fps':8,'seconds':seconds,'away':away,'hash':key}))
  svg.unlink(missing_ok=True) # contains embedded originals; reproducible from this source.
  return result
