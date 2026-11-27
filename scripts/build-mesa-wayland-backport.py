#!/usr/bin/env python3
"""Build a scoped EGL repair; never replace system Mesa, GBM, or GPU drivers."""
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import time

REVISION = '96cb43121031992b85767f9c1be8f3f48e22b1d2'
UPSTREAM_FIX = '3d2a7e8ad2e09bb5b9b532121bc45230a55221b2'
CALLER = 'src/egl/drivers/dri2/platform_wayland.c'
CALLER_SHA = 'b9ac8c38c8513715c2dad861a2877921fbd2588ecf3f1eaf9bfcd643bb39a76e'
SPARSE = '''bin build-support include licenses subprojects src/egl src/gbm
src/util src/c11 src/compiler src/mapi src/mesa src/loader src/gtest
src/android_stub src/tool src/virtio src/amd/common src/amd/vulkan/bvh
src/amd/vulkan/tools src/vulkan/runtime/bvh src/vulkan/util src/x11 src/glx
src/3rdparty src/gallium/auxiliary src/gallium/include src/gallium/frontends/dri
src/gallium/targets src/gallium/winsys/sw src/gallium/drivers/softpipe
src/gallium/drivers/trace src/gallium/drivers/noop src/gallium/drivers/rbug
src/gallium/drivers/llvmpipe src/gallium/drivers/zink'''.split()


def run(*args, cwd=None, capture=False):
    result = subprocess.run([str(arg) for arg in args], cwd=cwd, check=True,
                            text=True, capture_output=capture)
    return result.stdout if capture else None


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def exports(path):
    return {line.split()[-1] for line in run('nm', '-D', '--defined-only', path,
                                           capture=True).splitlines()
            if len(line.split()) >= 3}


def main():
    home = Path.home()
    cache = Path(os.environ.get('XDG_CACHE_HOME', home / '.cache')) / 'sensei-mesa-egl'
    source, build = cache / 'source-lean', cache / 'build-egl-v1'
    prefix = home / '.local/opt/sensei-mesa-egl'
    stage = prefix.with_name(prefix.name + '.staging')
    if stage.exists():
        raise SystemExit(f'Existing staging directory: {stage}. Inspect before retrying.')
    libdir = Path(run('pkg-config', '--variable=libdir', 'egl', capture=True).strip())
    original = libdir / 'libEGL_mesa.so.0'
    needed = run('readelf', '-d', original, capture=True)
    drivers = re.findall(r'Shared library: \[(libgallium-[^\]\n]+)\]', needed)
    if len(drivers) != 1 or not re.fullmatch(r'libgallium-26\.2\.4(?:-[A-Za-z0-9._]+)?\.so', drivers[0]):
        raise SystemExit('This reviewed repair targets Mesa 26.2.4 only; use a fixed distro release or review a new backport.')
    driver = libdir / drivers[0]
    system_libraries = [original, driver, libdir / 'libgbm.so.1']
    before = {str(path): sha(path) for path in system_libraries}
    if not (source / '.git').is_dir():
        source.mkdir(parents=True, exist_ok=True)
        run('git', 'init', '-q', source)
        run('git', '-C', source, 'remote', 'add', 'origin', 'https://github.com/mirror/mesa.git')
        run('git', '-C', source, 'sparse-checkout', 'set', '--cone', *SPARSE)
        run('git', '-C', source, 'fetch', '--depth', '1', '--filter=blob:none', 'origin', REVISION)
        run('git', '-C', source, 'checkout', '--detach', '-q', 'FETCH_HEAD')
    if run('git', '-C', source, 'rev-parse', 'HEAD', capture=True).strip() != REVISION:
        raise SystemExit('Unexpected Mesa source revision; source was not overwritten.')
    run('git', '-C', source, 'diff', '--cached', '--quiet')
    run('git', '-C', source, 'diff', '--quiet', '--', '.', f':(exclude){CALLER}')
    if sha(source / CALLER) != CALLER_SHA:
        run('git', '-C', source, 'diff', '--quiet', '--', CALLER)
        patch = Path(__file__).resolve().parent / 'patches/mesa-wayland-failed-buffer.patch'
        run('git', '-C', source, 'apply', '--check', patch)
        run('git', '-C', source, 'apply', patch)
    if sha(source / CALLER) != CALLER_SHA:
        raise SystemExit('Patched Mesa source fingerprint differs from the tested repair.')
    options = ['--buildtype=release', '--wrap-mode=nodownload', '-Dgallium-drivers=softpipe',
               '-Dvulkan-drivers=[]', '-Dplatforms=wayland,x11', '-Degl=enabled',
               '-Dglvnd=enabled', '-Dglx=disabled', '-Dgles1=disabled', '-Dgles2=enabled',
               '-Dllvm=disabled', '-Dgallium-va=disabled', '-Dgallium-mediafoundation=disabled',
               '-Dvideo-codecs=[]', '-Dbuild-tests=false', '-Dvalgrind=disabled',
               '-Db_lto=false', '-Dlibgbm-external=true']
    reconfigure = ['--reconfigure'] if (build / 'meson-private/coredata.dat').is_file() else []
    run('meson', 'setup', *reconfigure, build, source, *options)
    target = 'src/egl/libEGL_mesa.so.0.0.0'
    query = run('ninja', '-C', build, '-t', 'query', target, capture=True)
    inputs = []
    for line in query.splitlines()[2:]:
        if line.startswith('  outputs:'):
            break
        item = line.strip().lstrip('|').strip()
        if item and not item.startswith(('/', 'src/gallium/targets/dri/')):
            inputs.append(item)
    link = shlex.split(run('ninja', '-C', build, '-t', 'commands', '-s', target, capture=True))
    built_driver = 'src/gallium/targets/dri/libgallium-26.2.4.so'
    if link.count(built_driver) != 1 or not inputs or not any(item.endswith('.o') for item in inputs):
        raise SystemExit('Unexpected upstream build graph; refusing an unreviewed link recipe.')
    # Keep Meson's actual compile recipe, but reuse the installed GPU driver.
    # Building another Gallium or shipping a software renderer is unnecessary.
    run('nice', '-n', '15', 'ionice', '-c', '3', 'ninja', '-C', build, '-j', '2', *inputs)
    link = [str(driver) if word == built_driver else word for word in link
            if not word.startswith(('-Wl,-rpath,', '-Wl,-rpath-link,'))]
    run('nice', '-n', '15', 'ionice', '-c', '3', *link, cwd=build)
    library = build / target
    dynamic = run('readelf', '-d', library, capture=True)
    if '(RPATH)' in dynamic or '(RUNPATH)' in dynamic or f'[{driver.name}]' not in dynamic:
        raise SystemExit('Unexpected runtime paths or GPU driver dependency; not installed.')
    if exports(original) - exports(library):
        raise SystemExit('Candidate removes installed EGL exports; not installed.')
    dependencies = run('ldd', '-r', library, capture=True)
    if 'not found' in dependencies or 'undefined symbol:' in dependencies:
        raise SystemExit('Candidate has unresolved runtime dependencies; not installed.')
    if before != {str(path): sha(path) for path in system_libraries}:
        raise SystemExit('System graphics changed during the build; mixed inputs not installed.')
    (stage / 'lib').mkdir(parents=True)
    installed = stage / 'lib/libEGL_mesa.so.0.0.0'
    shutil.copy2(library, installed)
    (stage / 'lib/libEGL_mesa.so.0').symlink_to(installed.name)
    shutil.copytree(source / 'licenses', stage / 'licenses')
    manifest = ''.join(f'{digest}  {path}\n' for path, digest in before.items())
    manifest += f'{sha(installed)}  lib/{installed.name}\n'
    (stage / 'mesa-libraries.sha256').write_text(manifest)
    (stage / 'source.json').write_text(json.dumps({'sourceCommit': REVISION,
        'upstreamFix': UPSTREAM_FIX, 'sourceFileSHA256': CALLER_SHA,
        'installedDriver': driver.name}, indent=2) + '\n')
    if prefix.exists():
        previous = prefix.with_name(prefix.name + '.previous.' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
        if previous.exists():
            raise SystemExit('Previous-prefix destination exists; inspect staging before retrying.')
        prefix.rename(previous)
    stage.rename(prefix)
    print('Built the scoped EGL repair. System Mesa/GBM/drivers were not replaced.')
    print('Validate native allocation and visible-frame recovery before restarting only sensei-shell.')


if __name__ == '__main__':
    main()
