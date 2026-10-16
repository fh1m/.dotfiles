#!/usr/bin/env python3
"""Build an ABI-matched, user-local Qt6 theme provider. No system Qt replacement."""
import datetime,json,os,shutil,subprocess
from pathlib import Path
REV='00823e41aa60e8fe266d5aee328e82ad1ad94348'  # upstream qt6ct 0.11 release
URL='https://www.opencode.net/trialuser/qt6ct.git'

def run(*args,**kw):return subprocess.check_output(args,text=True,**kw).strip()
def main():
    home=Path.home();qt=run('pkg-config','--modversion','Qt6Core')
    cache=Path(os.environ.get('XDG_CACHE_HOME',home/'.cache'))/'sensei-build'/('qt6ct-0.11-qt'+qt)
    source=cache/'source';build=cache/'build-v2';cache.mkdir(parents=True,exist_ok=True)
    if not source.exists():
        subprocess.run(['git','clone','--filter=blob:none','--no-checkout',URL,str(source)],check=True)
        subprocess.run(['git','-C',str(source),'checkout','--detach',REV],check=True)
    if run('git','-C',str(source),'rev-parse','HEAD')!=REV:raise SystemExit('Unexpected source revision; preserve and inspect the build cache')
    if run('git','-C',str(source),'diff','--name-only'):raise SystemExit('Modified upstream source; preserve and inspect it before rebuilding')
    (cache/'CMakeLists.txt').write_text('cmake_minimum_required(VERSION 3.16)\nproject(SenseiQtTheme LANGUAGES CXX)\nfind_package(Qt6 REQUIRED COMPONENTS GuiPrivate WidgetsPrivate)\nadd_subdirectory(source)\n')
    subprocess.run(['cmake','-S',str(cache),'-B',str(build),'-G','Ninja','-DCMAKE_BUILD_TYPE=Release','-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON','-DCMAKE_INSTALL_RPATH=$ORIGIN/..'],check=True)
    subprocess.run(['cmake','--build',str(build),'--target','qt6ct-qtplugin','qt6ct-style','-j2'],check=True)
    # Keep upstream private-ABI guard; do not load a Qt6.11 provider into Qt6.12.
    stamp=datetime.datetime.now().strftime('%Y%m%d-%H%M%S');prefix=home/'.local/opt/sensei-qt6ct'
    stage=prefix.with_name(prefix.name+'.stage-'+stamp);lib=stage/'lib';lib.mkdir(parents=True)
    for name,subdir in [('qt6ct-qtplugin','platformthemes'),('qt6ct-style','styles')]:
        dest=lib/subdir;dest.mkdir()
        for p in (build/'source/src'/name).glob('*.so'):shutil.copy2(p,dest/p.name)
    for p in (build/'source/src/qt6ct-common').glob('*.so*'):
        if p.is_symlink():(lib/p.name).symlink_to(os.readlink(p))
        else:shutil.copy2(p,lib/p.name)
    # Relative RPATH keeps this provider independent of caches and system ABI.
    (stage/'build.json').write_text(json.dumps({'upstream':URL,'revision':REV,'qt':qt,'built':stamp},indent=2)+'\n')
    shutil.copy2(source/'COPYING',stage/'COPYING')
    if prefix.exists():prefix.rename(prefix.with_name(prefix.name+'.previous-'+stamp))
    stage.rename(prefix)
    print('Installed',prefix,'for Qt',qt)
if __name__=='__main__':main()
