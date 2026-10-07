#!/usr/bin/env bash
# A paired-screen README hero from the real main-display and ScreenPad tours.
set -euo pipefail
cd "$(dirname "$0")/.."
font=$(fc-match -f '%{file}' 'Iosevka Nerd Font Mono')
filter=$(mktemp)
trap 'rm -f "$filter"' EXIT
cat > "$filter" <<FILTER
[0:v]trim=duration=8.4,setpts=PTS-STARTPTS,fps=10,scale=1120:630:flags=lanczos,format=yuv420p[main];
[1:v]trim=duration=8.4,setpts=PTS-STARTPTS,fps=10,scale=1120:321:flags=lanczos,format=yuv420p[pad];
color=c=0x090807:s=1200x1120:r=10:d=8.4,format=yuv420p,drawbox=x=30:y=40:w=1140:h=650:c=0x67505a:t=2,drawbox=x=30:y=750:w=1140:h=341:c=0x67505a:t=2,drawbox=x=30:y=40:w=158:h=3:c=0xf23d70:t=fill,drawbox=x=30:y=750:w=158:h=3:c=0xf23d70:t=fill,drawbox=x=599:y=692:w=2:h=56:c=0xf23d70:t=fill,drawtext=fontfile=$font:text='FIELD / R-01   SENSEI':fontcolor=0xe8e2da:fontsize=17:x=40:y=13,drawtext=fontfile=$font:text='MAIN 3840 x 2160':fontcolor=0xa99d97:fontsize=16:x=974:y=13,drawtext=fontfile=$font:text='02 / SCREENPAD':fontcolor=0xe8e2da:fontsize=17:x=40:y=718,drawtext=fontfile=$font:text='3840 x 1100':fontcolor=0xa99d97:fontsize=16:x=1020:y=718[base];
[base][main]overlay=x=40:y=50:shortest=1[upper];
[upper][pad]overlay=x=40:y=760:shortest=1,format=yuv420p[out]
FILTER
ffmpeg -v error -y -i docs/assets/flight-deck.mp4 -stream_loop 1 -i docs/assets/screenpad-tools.mp4 -filter_complex "$(cat "$filter")" -map '[out]' -an -c:v libx264 -preset medium -crf 25 -movflags +faststart docs/assets/duo-hero.mp4
ffmpeg -v error -y -i docs/assets/duo-hero.mp4 -filter_complex 'fps=8,scale=1000:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3' -loop 0 docs/assets/duo-hero.gif
ffmpeg -v error -y -i docs/assets/duo-hero.mp4 -frames:v 1 docs/assets/duo-hero.png
