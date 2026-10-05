#!/usr/bin/env bash
# Live, aggregate facts for the README's isolated tmux showcase.
printf '\n  FIELD REPORT / GPU + CONTAINERS\n\n'
nvidia-smi --query-gpu=name,temperature.gpu,memory.used,memory.total,utilization.gpu \
  --format=csv,noheader
printf '\n'
docker info --format '  Containers: {{.Containers}}  Images: {{.Images}}  Driver: {{.Driver}}'
