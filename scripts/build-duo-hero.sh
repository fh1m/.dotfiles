#!/usr/bin/env bash
# Pair real captures of the main and ScreenPad surfaces for GitHub's README.
set -euo pipefail
cd "$(dirname "$0")/.."
font=$(fc-match -f '%{file}' 'Iosevka Nerd Font Mono')

build_pair() {
  local main_video=$1
  local name=$2
  local duration=$3
  local title=$4
  local filter
  filter=$(mktemp)
  cat > "$filter" <<FILTER
[0:v]trim=duration=$duration,setpts=PTS-STARTPTS,fps=10,scale=1120:630:flags=lanczos,format=yuv420p[main];
[1:v]trim=duration=$duration,setpts=PTS-STARTPTS,fps=10,scale=1120:321:flags=lanczos,format=yuv420p[pad];
color=c=0x090807:s=1200x1120:r=10:d=$duration,format=yuv420p,drawbox=x=30:y=40:w=1140:h=650:c=0x67505a:t=2,drawbox=x=30:y=750:w=1140:h=341:c=0x67505a:t=2,drawbox=x=30:y=40:w=158:h=3:c=0xf23d70:t=fill,drawbox=x=30:y=750:w=158:h=3:c=0xf23d70:t=fill,drawbox=x=599:y=692:w=2:h=56:c=0xf23d70:t=fill,drawtext=fontfile=$font:text='$title':fontcolor=0xe8e2da:fontsize=17:x=40:y=13,drawtext=fontfile=$font:text='MAIN 3840 x 2160':fontcolor=0xa99d97:fontsize=16:x=974:y=13,drawtext=fontfile=$font:text='02 / SCREENPAD':fontcolor=0xe8e2da:fontsize=17:x=40:y=718,drawtext=fontfile=$font:text='3840 x 1100':fontcolor=0xa99d97:fontsize=16:x=1020:y=718[base];
[base][main]overlay=x=40:y=50:shortest=1[upper];
[upper][pad]overlay=x=40:y=760:shortest=1,format=yuv420p[out]
FILTER
  ffmpeg -v error -y -i "$main_video" -stream_loop 1 -i docs/assets/screenpad-tools.mp4 -filter_complex "$(cat "$filter")" -map '[out]' -an -c:v libx264 -preset medium -crf 25 -movflags +faststart "docs/assets/$name.mp4"
  rm -f "$filter"
  ffmpeg -v error -y -i "docs/assets/$name.mp4" -filter_complex 'fps=8,scale=1000:-1:flags=lanczos,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=3' -loop 0 "docs/assets/$name.gif"
  ffmpeg -v error -y -ss 3 -i "docs/assets/$name.mp4" -frames:v 1 "docs/assets/$name.png"
}

build_pair docs/assets/flight-deck.mp4 duo-hero 8.4 'FIELD / R-01   SENSEI'
build_pair docs/assets/robotics-lab.mp4 duo-lab 6.0 'FIELD / R-01   LAB ONLINE'
