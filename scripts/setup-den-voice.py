#!/usr/bin/env python3
"""Opt-in pinned CPU whisper.cpp build and checked model download. Preview by default."""
import argparse,hashlib,os,subprocess,tempfile,urllib.request
from pathlib import Path
REV='0c7be696371069e0baa2515ed7aa08d5a5473aa6'
SHA='60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe'
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--apply',action='store_true');a=p.parse_args()
home=Path.home();src=home/'.local/src/whisper.cpp';models=home/'.local/share/sensei-voice/models';binary=home/'.local/bin/whisper-cli'
print('Pinned CPU-only whisper.cpp, 2 build threads; base multilingual model (~148 MB), SHA-256 verified. No service or automatic typing.')
if not a.apply:raise SystemExit(0)
def run(*args):subprocess.run(args,check=True)
if not src.exists():
 run('git','clone','--no-checkout','https://github.com/ggml-org/whisper.cpp',str(src))
 run('git','-C',str(src),'checkout','--detach',REV)
current=subprocess.check_output(['git','-C',str(src),'rev-parse','HEAD'],text=True).strip()
if current!=REV:raise SystemExit('Existing source revision differs; preserve it and review explicitly before changing the checkout.')
run('cmake','-S',str(src),'-B',str(src/'build-den'),'-DCMAKE_BUILD_TYPE=Release','-DGGML_CUDA=OFF','-DWHISPER_BUILD_TESTS=OFF')
run('nice','-n','10','cmake','--build',str(src/'build-den'),'--target','whisper-cli','-j2')
models.mkdir(parents=True,exist_ok=True);model=models/'ggml-base.bin'
def digest(path):
 with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
if not model.exists() or digest(model)!=SHA:
 fd,name=tempfile.mkstemp(dir=models,prefix='.model-');os.close(fd);temporary=Path(name)
 try:
  urllib.request.urlretrieve('https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',temporary)
  if digest(temporary)!=SHA:raise SystemExit('Model verification failed; existing file preserved')
  temporary.replace(model)
 finally:temporary.unlink(missing_ok=True)
binary.parent.mkdir(parents=True,exist_ok=True)
if binary.exists() and not binary.is_symlink():raise SystemExit('Existing whisper-cli is not our symlink; preserve and review')
binary.unlink(missing_ok=True);binary.symlink_to(src/'build-den/bin/whisper-cli')
print('Ready: sensei-voice transcribe --seconds 10')
