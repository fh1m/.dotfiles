#!/usr/bin/env python3
"""Provision the shared Neovim configuration in the CURRENT user environment.

Run directly on the host or through sensei-dev setup --container NAME. Downloads
are digest-verified; no project Python dependencies or system packages change.
"""
import argparse
from datetime import datetime
import gzip
import hashlib
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request

REPO = Path(__file__).resolve().parents[1]
HOME = Path.home()
SOURCE = REPO / 'home/.config/nvim'
STAGE = HOME / '.config/sensei-nvim'
STATE = HOME / '.local/state/sensei-dev'
BIN = HOME / '.local/bin'
OPT = HOME / '.local/opt'
PACKAGES = ['basedpyright', 'ruff', 'clangd', 'lua-language-server', 'typescript-language-server',
    'html-lsp', 'css-lsp', 'json-lsp', 'yaml-language-server', 'bash-language-server',
    'cmake-language-server', 'dockerfile-language-server', 'lemminx', 'debugpy', 'codelldb',
    'clang-format', 'stylua', 'prettier', 'shfmt', 'black', 'shellcheck']
PARSERS = ['lua', 'vim', 'vimdoc', 'query', 'python', 'c', 'cpp', 'bash', 'cmake', 'json',
    'yaml', 'xml', 'html', 'css', 'javascript', 'typescript', 'tsx', 'markdown', 'markdown_inline', 'dockerfile', 'qmljs']

def fetch(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'sensei-dotfiles-dev-setup'})
    with urllib.request.urlopen(req, timeout=90) as r: return r.read()

def release(repo, tag, name):
    metadata = json.loads(fetch(f'https://api.github.com/repos/{repo}/releases/tags/{tag}' if tag else f'https://api.github.com/repos/{repo}/releases/latest'))
    asset = next(a for a in metadata['assets'] if (name(a['name']) if callable(name) else a['name'] == name))
    digest = asset.get('digest')
    if not digest or not digest.startswith('sha256:'): raise RuntimeError(f'No published SHA256 digest for {repo} {asset["name"]}')
    data = fetch(asset['browser_download_url'])
    if hashlib.sha256(data).hexdigest() != digest.split(':', 1)[1]: raise RuntimeError('Download checksum mismatch')
    return data, {'repository': repo, 'version': metadata['tag_name'], 'asset': asset['name'], 'sha256': digest.split(':', 1)[1]}

def unpack(data, destination):
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        archive = Path(tmp) / 'archive.tar.gz'; archive.write_bytes(data)
        with tarfile.open(archive) as tar:
            # Release archives are verified; still reject escapes in member paths.
            for member in tar.getmembers():
                if member.name.startswith('/') or '..' in Path(member.name).parts: raise RuntimeError('Unsafe archive path')
            tar.extractall(destination, filter='data') if hasattr(tarfile, 'data_filter') else tar.extractall(destination)

def link(source, dest):
    if dest.is_symlink() and dest.resolve() == source.resolve(): return
    if dest.exists() or dest.is_symlink(): raise RuntimeError(f'Refusing to replace existing {dest} without backup')
    dest.parent.mkdir(parents=True, exist_ok=True); dest.symlink_to(source)

def tools():
    versions = {}
    BIN.mkdir(parents=True, exist_ok=True); OPT.mkdir(parents=True, exist_ok=True)
    # Use a local stable runtime in containers; leave the host's current stable package alone.
    executable = shutil.which('nvim')
    version = re.search(r'NVIM v(\d+)\.(\d+)\.(\d+)', subprocess.check_output([executable, '--version'], text=True)) if executable else None
    stable = bool(version and tuple(map(int, version.groups())) >= (0, 12, 5))
    if not stable:
        dest = OPT / 'neovim-v0.12.5'
        if not (dest / 'bin/nvim').exists():
            data, versions['neovim'] = release('neovim/neovim', 'v0.12.5', 'nvim-linux-x86_64.tar.gz')
            with tempfile.TemporaryDirectory() as tmp:
                unpack(data, Path(tmp)); shutil.copytree(Path(tmp) / 'nvim-linux-x86_64', dest, symlinks=True)
        if (BIN / 'nvim').exists() or (BIN / 'nvim').is_symlink():
            if (BIN / 'nvim').resolve() != (dest / 'bin/nvim').resolve(): raise RuntimeError('Existing user-local nvim preserved; resolve it before provisioning')
        else: link(dest / 'bin/nvim', BIN / 'nvim')
        executable = str(dest / 'bin/nvim')
    versions['neovim_runtime'] = subprocess.check_output([executable, '--version'], text=True).splitlines()[0]
    if not shutil.which('tree-sitter'):
        data, versions['tree-sitter'] = release('tree-sitter/tree-sitter', 'v0.27.0', 'tree-sitter-linux-x64.gz')
        file = BIN / 'tree-sitter'; file.write_bytes(gzip.decompress(data)); file.chmod(0o755)
    tree = shutil.which('tree-sitter') or str(BIN / 'tree-sitter')
    if subprocess.run([tree, '--version'], capture_output=True).returncode != 0:
        # Official current binaries require glibc 2.39. Build against this
        # container's libc instead of contaminating ROS with a libc upgrade.
        cargo = shutil.which('cargo') or str(HOME / '.cargo/bin/cargo')
        if not Path(cargo).exists(): raise RuntimeError('Tree-sitter needs a compatible build here; install Rust in this environment and rerun setup.')
        prefix = OPT / 'tree-sitter-v0.27.0'
        subprocess.run([cargo, 'install', 'tree-sitter-cli', '--version', '0.27.0', '--locked',
            '--root', str(prefix), '--jobs', '2', '--target', 'x86_64-unknown-linux-gnu'], check=True)
        shutil.copy2(prefix / 'bin/tree-sitter', BIN / 'tree-sitter')
        versions['tree-sitter'] = {'version': '0.27.0', 'build': 'native, two workers; glibc-compatible'}
    fzf = shutil.which('fzf')
    modern_fzf = fzf and tuple(int(x) for x in subprocess.check_output([fzf, '--version'], text=True).split()[0].split('.')[:2]) >= (0, 36)
    if not modern_fzf:
        data, versions['fzf'] = release('junegunn/fzf', 'v0.74.4', 'fzf-0.74.4-linux_amd64.tar.gz')
        unpack(data, BIN)
    for name, repo in [('fd', 'sharkdp/fd'), ('bat', 'sharkdp/bat')]:
        if shutil.which(name): continue
        data, versions[name] = release(repo, None, lambda n: 'x86_64-unknown-linux-musl.tar.gz' in n)
        with tempfile.TemporaryDirectory() as tmp:
            unpack(data, Path(tmp)); binary = next(Path(tmp).glob(f'*/{name}')); shutil.copy2(binary, BIN / name)
    npm = shutil.which('npm')
    healthy_node = shutil.which('node') and npm and subprocess.run([npm, '--version'], capture_output=True).returncode == 0
    if not healthy_node:
        index = json.loads(fetch('https://nodejs.org/dist/index.json'))
        version = next(x['version'] for x in index if x['version'].startswith('v22.') and x['lts'])
        filename = f'node-{version}-linux-x64.tar.xz'
        sums = fetch(f'https://nodejs.org/dist/{version}/SHASUMS256.txt').decode()
        sha = next(line.split()[0] for line in sums.splitlines() if line.split()[-1] == filename)
        data = fetch(f'https://nodejs.org/dist/{version}/{filename}')
        if hashlib.sha256(data).hexdigest() != sha: raise RuntimeError('Node checksum mismatch')
        dest = OPT / f'node-{version}'
        with tempfile.TemporaryDirectory() as tmp:
            archive = Path(tmp) / filename; archive.write_bytes(data)
            with tarfile.open(archive) as tar: tar.extractall(tmp)
            if dest.exists(): shutil.rmtree(dest)
            shutil.copytree(Path(tmp) / f'node-{version}-linux-x64', dest, symlinks=True)
        link(dest, OPT / 'node')
        for name in ['node', 'npm', 'npx']: link(dest / 'bin' / name, BIN / name)
        versions['node'] = {'version': version, 'sha256': sha}
    return executable, versions

def agents():
    """Install missing native CLIs only; leave accounts and existing versions alone."""
    BIN.mkdir(parents=True, exist_ok=True)
    if not shutil.which('codex'):
        data, meta = release('openai/codex', 'rust-v0.161.0', 'codex-x86_64-unknown-linux-musl.tar.gz')
        with tempfile.TemporaryDirectory() as tmp:
            unpack(data, Path(tmp))
            binary = next(x for x in Path(tmp).rglob('*') if x.is_file() and x.name.startswith('codex') and os.access(x, os.X_OK))
            shutil.copy2(binary, BIN / 'codex')
        print('Installed Codex', meta['version'])
    if not shutil.which('claude'):
        version = '2.1.283'
        base = 'https://downloads.claude.ai/claude-code-releases'
        manifest = json.loads(fetch(f'{base}/{version}/manifest.json'))
        sha = manifest['platforms']['linux-x64']['checksum']
        data = fetch(f'{base}/{version}/linux-x64/claude')
        if hashlib.sha256(data).hexdigest() != sha: raise RuntimeError('Claude checksum mismatch')
        binary = BIN / 'claude'; binary.write_bytes(data); binary.chmod(0o755)
        print('Installed Claude', version)
    for name in ['codex', 'claude']:
        subprocess.run([str(BIN / name) if (BIN / name).exists() else name, '--version'], check=True)

def backup_move(path, stamp):
    if not path.exists() and not path.is_symlink(): return
    dest = STATE / 'backups' / stamp / path.name
    dest.parent.mkdir(parents=True, exist_ok=True)
    path.rename(dest)

def nvim_run(executable, code, timeout=600):
    env = dict(os.environ, NVIM_APPNAME='sensei-nvim', PATH=str(BIN) + ':' + str(OPT / 'node/bin') + ':' + os.environ.get('PATH', ''))
    guarded = 'local ok,err=xpcall(function() ' + code + ' end,debug.traceback); if not ok then vim.api.nvim_err_writeln(err); vim.cmd("cquit") end'
    subprocess.run([executable, '--headless', '-i', 'NONE', '-c', 'lua ' + guarded], env=env, check=True, timeout=timeout)

def setup(activate=False, skip_tools=False):
    if os.geteuid() == 0: raise RuntimeError('Use the Distrobox user, not root.')
    if not SOURCE.exists(): raise RuntimeError('Shared .dotfiles source is not mounted here.')
    STATE.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    os.environ['PATH'] = str(BIN) + ':' + str(OPT / 'node/bin') + ':' + os.environ.get('PATH', '')
    executable, versions = (shutil.which('nvim'), {}) if skip_tools else tools()
    if STAGE.exists() or STAGE.is_symlink():
        if STAGE.resolve() != SOURCE.resolve(): backup_move(STAGE, stamp)
    if not STAGE.is_symlink(): link(SOURCE, STAGE)
    nvim_run(executable, 'require("lazy").install({wait=true}); require("lazy").restore({wait=true}); vim.cmd("qa")')
    install = '''local r=require('mason-registry'); local completed=false
      r.refresh(function() completed=true end)
      assert(vim.wait(120000,function() return completed end,100),'Mason registry timeout')
      local names=''' + json.dumps(PACKAGES).replace('[', '{').replace(']', '}') + '''
      local packages={}
      for _,name in ipairs(names) do
        local p=r.get_package(name); table.insert(packages,p)
        if not p:is_installed() then p:install() end
      end
      assert(vim.wait(480000,function()
        for _,p in ipairs(packages) do if p:is_installing() then return false end end
        return true
      end,500),'Tool installation timeout')
      local missing={}
      for _,p in ipairs(packages) do if not p:is_installed() then table.insert(missing,p.name) end end
      if #missing>0 then error('Missing tools: '..table.concat(missing,', ')) end
      vim.cmd('qa')'''
    if not skip_tools:
        nvim_run(executable, "require('mason').setup({PATH='append'}); " + install, timeout=700)
        parsers = json.dumps(PARSERS).replace('[', '{').replace(']', '}')
        nvim_run(executable, "require('nvim-treesitter').install(" + parsers + "):wait(300000); "
            + "for _,p in ipairs(" + parsers + ") do assert(vim.uv.fs_stat(vim.fn.stdpath('data')..'/site/parser/'..p..'.so'),'Parser missing: '..p) end; vim.cmd('qa')", timeout=400)
    # Runtime directories stay per-home; rename staged data only on activation.
    if activate:
        dest = HOME / '.config/nvim'
        if dest.resolve() != SOURCE.resolve():
            backup_move(dest, stamp); link(SOURCE, dest)
        for prefix in ['.local/share', '.local/state', '.cache']:
            stage = HOME / prefix / 'sensei-nvim'; live = HOME / prefix / 'nvim'
            if stage.exists() and not stage.is_symlink():
                if live.exists() or live.is_symlink():
                    old = STATE / 'backups' / stamp / prefix.strip('.').replace('/', '-')
                    old.parent.mkdir(parents=True, exist_ok=True); live.rename(old)
                stage.rename(live); stage.symlink_to(live)
        # LSP tools must also be visible to launchers and command-line diagnostics.
        mason_bin = HOME / '.local/share/nvim/mason/bin'
        if mason_bin.exists():
            for file in mason_bin.iterdir():
                if not (BIN / file.name).exists() and not (BIN / file.name).is_symlink(): link(file, BIN / file.name)
        snippet = HOME / '.config/zsh/sensei-dev.zsh'
        snippet.parent.mkdir(parents=True, exist_ok=True)
        host_home = REPO.parent
        snippet.write_text('# User-local development tools; sourced after legacy PATH resets.\n'
            'export PATH="$HOME/.local/bin:$HOME/.local/opt/node/bin:$PATH"\n'
            + 'export SENSEI_HOST_HOME=' + __import__('shlex').quote(str(host_home)) + '\n')
        zshrc = HOME / '.zshrc'
        include = '\n# Shared development environment (keeps project dependencies separate).\n[[ -r "$HOME/.config/zsh/sensei-dev.zsh" ]] && source "$HOME/.config/zsh/sensei-dev.zsh"\n'
        current = zshrc.read_text() if zshrc.exists() else ''
        if 'source "$HOME/.config/zsh/sensei-dev.zsh"' not in current:
            if zshrc.exists():
                saved = STATE / 'backups' / stamp / '.zshrc'; saved.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(zshrc, saved)
            zshrc.write_text(current + include)
    report = {'activated': activate, 'home': str(HOME), 'runtime': executable, 'versions': versions,
        'mason_packages': PACKAGES, 'parsers': PARSERS, 'backup': str(STATE / 'backups' / stamp)}
    (STATE / ('ready.json' if activate else 'staged.json')).write_text(json.dumps(report, indent=2))
    print(json.dumps(report, indent=2))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--activate', action='store_true'); parser.add_argument('--skip-tools', action='store_true')
    parser.add_argument('--agents-only', action='store_true')
    args = parser.parse_args()
    if args.agents_only:
        os.environ['PATH'] = str(BIN) + ':' + os.environ.get('PATH', '')
        agents()
    else: setup(args.activate, args.skip_tools)
