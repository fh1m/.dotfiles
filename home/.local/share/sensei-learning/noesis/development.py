"""Explicit development handoff and observed code provenance; no code execution."""
from datetime import datetime, timezone
from pathlib import Path
import os
import shutil
import subprocess


def snapshot(location):
    repository=Path(location).expanduser().resolve()
    if not repository.is_dir():raise ValueError('Repository unavailable; its learning history is preserved')
    def git(*args, optional=False):
        result=subprocess.run(['git','-C',str(repository),*args],capture_output=True,text=True,timeout=5,
                              env=dict(os.environ,GIT_OPTIONAL_LOCKS='0'))
        if result.returncode and optional:return None
        if result.returncode:raise ValueError('Choose an existing Git repository; Noesis does not initialize or modify it')
        return result.stdout.strip()
    try:
        top=Path(git('rev-parse','--show-toplevel')).resolve()
        commit=git('rev-parse','--verify','HEAD',optional=True)
        dirty=bool(git('status','--porcelain','--untracked-files=normal'))
    except subprocess.TimeoutExpired as error:raise ValueError('Repository inspection timed out; nothing was executed') from error
    return {'repository':str(top),'commit':commit,'dirty':dirty,'observed_at':datetime.now(timezone.utc).isoformat(),
            'authority':'Git working tree; uncommitted changes are not captured by the commit'}


def command(props):
    location=props.get('repository') or (props.get('code_snapshot') or {}).get('repository')
    if not location:raise ValueError('Connect an implementation repository first')
    state=snapshot(location)
    terminal=Path.home()/'.local/bin/sensei-terminal'
    if not terminal.is_file():raise ValueError('The configured terminal helper is unavailable')
    if not shutil.which('nvim'):raise ValueError('Neovim is unavailable; the repository reference is preserved')
    entry=props.get('code_entrypoint')
    if entry:
        from .persistence import contained
        file=contained(Path(state['repository']),entry)
        if not file.is_file():raise ValueError('Code entry point is unavailable; the repository reference is preserved')
    return [str(terminal),'--title','Noesis · '+str(props.get('title','Implementation')),
            '--working-directory',state['repository'],'-e','nvim',*(['--',entry] if entry else ['.'])]
