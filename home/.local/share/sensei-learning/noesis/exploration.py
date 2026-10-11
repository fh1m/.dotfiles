"""Owned visual artifacts and explicitly invoked terminal experiments.

Files remain specialist-tool authority; records and activities reuse Noesis contracts.
"""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import os
import subprocess
import shutil
import sys
import uuid
from .index import Index
from .models import create
from .activities import record_activity
from .persistence import contained, lock, publish, checksum


def target(root, identity):
    index = Index(root)
    try:
        health = index.reconcile()
        if health['errors']: raise ValueError('Resolve vault/index errors before this action')
        record = index.record(identity, include_body=False, include_attempt=False)
        record['vault_id'] = index.manifest['vault_id']
        return record
    finally: index.close()


def child_id(operation, name):
    return str(uuid.uuid5(uuid.UUID(operation), name))


def reserve(root, operation, request):
    uuid.UUID(operation)
    path=contained(root,'.Noesis/Executions/'+operation+'.json')
    digest=checksum(json.dumps(request,sort_keys=True))
    with lock(root):
        if path.exists():
            if json.loads(path.read_text()).get('request_hash')!=digest:raise ValueError('Operation identity already belongs to another request')
        else:publish(path,json.dumps({'status':'prepared','request_hash':digest,'request':request}))


def begin_publication(root, operation):
    path=contained(root,'.Noesis/Executions/'+operation+'.json')
    with lock(root):
        original=path.read_text();value=json.loads(original);value['status']='started'
        publish(path,json.dumps(value),checksum(original))


def prepare(root, identity, title, mode, operation, native_cli=None, prediction="", code_file=None):
    from .scopes import assert_unique
    assert_unique(root)
    origin = target(root, identity)
    uuid.UUID(operation)
    if not title.strip() or any(c in title for c in '/\\\n\r\0'):
        raise ValueError('Use a title, not a file path')
    existing_drawing=contained(root,'Explorations/'+operation+'/drawing.excalidraw.md').is_file()
    if mode=='freehand' and not existing_drawing:
        plugin=root/'.obsidian/plugins/obsidian-excalidraw-plugin/manifest.json'
        enabled=root/'.obsidian/community-plugins.json'
        try:available=json.loads(plugin.read_text()).get('id')=='obsidian-excalidraw-plugin' and 'obsidian-excalidraw-plugin' in json.loads(enabled.read_text())
        except (OSError,ValueError,TypeError):available=False
        if not available:raise ValueError('Excalidraw is not enabled in this Obsidian vault. Choose Canvas map; no plugin was installed.')
        if native_cli is None:raise ValueError('Open this vault in Obsidian to create a freehand drawing')
        import re
        active=native_cli(root,'eval','code=!!app.plugins.plugins["obsidian-excalidraw-plugin"]')
        if not re.fullmatch(r'(?:=>\s*)?true',active.strip()):raise ValueError('Excalidraw is not active in the selected Obsidian vault. Enable it there, or choose Canvas map. Nothing was created.')
    existing_code=None
    if code_file:
        existing_code=Path(code_file).expanduser().resolve()
        if not existing_code.is_file() or existing_code.suffix.lower()!='.py' or existing_code.stat().st_size>1024*1024:raise ValueError('Choose an existing Python file below 1 MiB')
    reserve(root,operation,{'action':'prepare','origin':identity,'title':title,'mode':mode,'prediction':prediction,'code_file':str(existing_code) if existing_code else None})
    folder = 'Explorations/' + operation
    directory = contained(root, folder)
    begin_publication(root,operation)
    directory.mkdir(parents=True, exist_ok=True)
    backlink = '[[' + origin['path'] + ']]'
    if mode == 'scratch':
        file = directory / 'scratch.py'
        if not existing_code and not file.exists():
            publish(file, '# My exploration\n# Origin: ' + origin['path'] + '\n# Write a prediction, then implement your own check.\n# Save plots/data to os.environ[\"NOESIS_RUN_DIRECTORY\"] to capture them.\n# No solution is supplied.\n\n')
        return create(root, 'experiment', title,
                      '## Question\n\n' + backlink + '\n\n## Prediction\n\n## Interpretation\n\nExecution and understanding are separate.\n',
                      fields={'hypothesis':prediction, 'local_file': str(existing_code) if existing_code else folder + '/scratch.py', 'external_code':bool(existing_code), 'scratch_directory': folder,
                              'origin_ref': {'record_id': identity, 'vault_id': origin['vault_id']}},
                      parent_id=identity, relation='references', operation_id=operation)
    if mode not in ('canvas', 'freehand'): raise ValueError('Choose Canvas or freehand')
    path = folder + ('/drawing.excalidraw.md' if mode == 'freehand' else '/map.canvas')
    file = contained(root, path)
    if mode == 'freehand':
        if native_cli is None and not file.exists(): raise ValueError('Open this vault in Obsidian to create a freehand drawing')
        # File identity is fixed before the non-replayed native command. A retry
        # discovers an existing file rather than producing another drawing.
        if not file.exists():
            code = '(async()=>{const p=app.plugins.plugins["obsidian-excalidraw-plugin"];if(!p)throw Error("Excalidraw is not enabled in this vault. Choose Canvas map instead.");if(app.vault.getAbstractFileByPath('+json.dumps(path)+'))return '+json.dumps(path)+';return await p.createAndOpenDrawing("drawing.excalidraw.md","active-pane",'+json.dumps(folder)+');})()'
            native_cli(root, 'eval', 'code=' + code)
        if not file.is_file(): raise ValueError('Drawing creation was not confirmed; inspect Obsidian before retrying')
    elif not file.exists():
        publish(file, json.dumps({'nodes': [{'id': uuid.uuid4().hex[:16], 'type': 'text', 'text': 'Origin: '+backlink+'\n\nSketch the mechanism here. Opening a source or reference in another tool is a deliberate handoff; declare assistance when relevant.',
                                            'x': 0, 'y': 0, 'width': 420, 'height': 300}], 'edges': []}))
    return create(root, 'artifact', title,
                  'Editable learning drawing. Not evidence of understanding.\n\nOrigin: ' + backlink + '\n\n[[' + path + ']]\n',
                  fields={'local_file': path, 'location': path, 'artifact_kind': 'drawing', 'drawing_format': mode,
                          'origin_ref': {'record_id': identity, 'vault_id': origin['vault_id']}},
                  parent_id=identity, relation='references', operation_id=operation)


def local_file(root, identity):
    record = target(root, identity)
    value = record['props'].get('local_file') or record['props'].get('location')
    if not value: raise ValueError('This record has no linked file')
    file = Path(value).expanduser()
    if not file.is_absolute(): file = contained(root, value)
    if not file.is_file(): raise ValueError('Linked file is missing. Locate it through Connect artifact; its history is preserved.')
    return record, file


def open_code(root, identity):
    record, file = local_file(root, identity)
    terminal = Path.home() / '.local/bin/sensei-terminal'
    if not terminal.is_file(): raise ValueError('The configured terminal helper is unavailable; your code is preserved')
    if not shutil.which('nvim'): raise ValueError('Neovim is unavailable; your code is preserved')
    return [str(terminal), '--title', 'Noesis · ' + record['display_title'], '--working-directory', str(file.parent), '-e', 'nvim', '--', str(file)]


def terminal_command(root, identity):
    record, file = local_file(root, identity)
    if not record['props'].get('scratch_directory'): raise ValueError('Choose a quick experiment')
    import shlex
    if not (Path.home()/'.local/bin/sensei-terminal').is_file(): raise ValueError('The configured terminal helper is unavailable; no code was executed')
    if not shutil.which('bash'): raise ValueError('Bash is unavailable; no code was executed')
    command = shlex.join([str(Path.home()/'.local/bin/sensei-learn'), 'scratch-run', '--vault', str(root), identity, '--operation-id', str(uuid.uuid4())])
    # Prompt leaves execution deliberate and preserves an interactive terminal.
    script = 'printf "%s\\n" ' + shlex.quote('Run captures Python output for: ' + str(file) + '\nCommand: ' + command) + '; read -r -p "Press Enter to execute, or Ctrl+C to cancel: " answer; ' + command + '; exec bash'
    return [str(Path.home()/'.local/bin/sensei-terminal'), '--title', 'Noesis · quick experiment', '--working-directory', str(file.parent), '-e', 'bash', '-c', script]


def run(root, identity, operation):
    from .scopes import assert_unique
    assert_unique(root)
    record, file = local_file(root, identity)
    props = record['props']
    if not props.get('scratch_directory') or file.suffix != '.py': raise ValueError('Choose an explicitly created Python scratch experiment')
    uuid.UUID(operation)
    directory = contained(root, props['scratch_directory'])
    if not props.get('external_code') and file.resolve().parent != directory: raise ValueError('Scratch code moved; reconnect it before execution')
    cwd=file.parent if props.get('external_code') else directory
    output_dir = directory / 'runs' / operation
    reservation = contained(root, '.Noesis/Executions/' + operation + '.json')
    if file.stat().st_size > 1024*1024: raise ValueError('Scratch code exceeds 1 MiB; use your external tooling')
    with file.open('rb') as stream:code_bytes=stream.read(1024*1024+1)
    if len(code_bytes)>1024*1024:raise ValueError('Scratch code exceeds 1 MiB; use your external tooling')
    try:code=code_bytes.decode('utf-8')
    except UnicodeDecodeError as error:raise ValueError('Use UTF-8 Python code for capture, or execute it in your external tooling') from error
    digest = hashlib.sha256(code_bytes).hexdigest()
    command = [sys.executable, str(file)]
    details = {'status': 'started', 'record_id': identity, 'command': command, 'cwd': str(cwd),
               'code_sha256': digest, 'prediction':props.get('hypothesis',''), 'python': sys.version, 'started_at': datetime.now(timezone.utc).isoformat(),
               'learner_achievement': False, 'environment':{'NOESIS_RUN_DIRECTORY':str(output_dir)}}
    import importlib.metadata
    details['package_versions']={}
    for package in ('numpy','scipy','sympy','matplotlib'):
        try:details['package_versions'][package]=importlib.metadata.version(package)
        except importlib.metadata.PackageNotFoundError:pass
    with lock(root):
        if reservation.exists(): raise ValueError('Execution already started; inspect its outputs instead of replaying it')
        output_dir.mkdir(parents=True, exist_ok=False)
        publish(reservation, json.dumps(details))
        publish(output_dir/'code.py', code)
    try:
        from .development import snapshot
        try:details['code_snapshot']=snapshot(cwd)
        except ValueError:details['code_snapshot']={'authority':'owned scratch file; no Git revision','sha256':digest}
        with (output_dir/'stdout.txt').open('wb') as stdout, (output_dir/'stderr.txt').open('wb') as stderr:
            process = subprocess.run(command, cwd=cwd, stdout=stdout, stderr=stderr, timeout=120,
                                     env=dict(os.environ, NOESIS_RUN_DIRECTORY=str(output_dir)))
        details.update(status='completed', exit_code=process.returncode)
    except subprocess.TimeoutExpired:
        details.update(status='timed-out', exit_code=None)
    except OSError as error:
        details.update(status='failed-to-start', error=str(error), exit_code=None)
    try:changed=hashlib.sha256(file.read_bytes()).hexdigest()!=digest
    except OSError:changed=True;details['code_unavailable_after_run']=True
    details.update(finished_at=datetime.now(timezone.utc).isoformat(), code_changed=changed)
    details['outputs'] = [{'path': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'size': p.stat().st_size} for p in [output_dir/'stdout.txt', output_dir/'stderr.txt'] if p.exists() and p.stat().st_size <= 32*1024*1024]
    publish(output_dir/'execution.json', json.dumps(details, indent=2))
    for file_output in list(output_dir.iterdir())[:20]:
        if file_output.suffix.lower() in ('.png','.csv','.json') and file_output.name != 'execution.json' and file_output.is_file() and not file_output.is_symlink() and file_output.stat().st_size <= 25*1024*1024:
            create(root, 'artifact', 'Run artifact ' + file_output.name, 'Actual output of an explicitly invoked scratch run.', fields={'location': str(file_output), 'sha256': hashlib.sha256(file_output.read_bytes()).hexdigest(), 'evidence_kind': 'software-run'}, parent_id=identity, relation='references', operation_id=child_id(operation,'artifact:'+file_output.name))
    artifact = create(root, 'artifact', 'Executed output ' + operation[:8],
                      'Actual explicit execution. Interpretation and understanding require separate learner decisions.',
                      fields={'location': str(output_dir/'execution.json'), 'local_file': str(output_dir/'stdout.txt'),
                              'execution': details, 'evidence_kind': 'software-run'}, parent_id=identity,
                      relation='references', operation_id=child_id(operation, 'output'))
    result = record_activity(root, record['path'], 'comparison', 'Explicit Python scratch execution; no hypothesis verdict inferred.',
                            operation_id=operation, prediction=props.get('hypothesis',''), observed={'exit_code': details['exit_code'], 'status': details['status']},
                            execution=details, artifact_id=artifact['id'], evidence_kind='software-run', learner_achievement=False)
    publish(reservation, json.dumps(dict(details, status='committed')), checksum(reservation.read_text()))
    return result


def reconnect(root, identity, location, title, operation, native_cli=None):
    """Retain an artifact ID when its owned file is renamed or explicitly relocated."""
    from .persistence import parse, render, checksum
    from .scopes import assert_unique
    assert_unique(root)
    record = target(root, identity)
    props = record['props']
    if props.get('type') != 'artifact': raise ValueError('Choose an artifact')
    uuid.UUID(operation)
    if not title.strip() or any(c in title for c in '/\\\n\r\0'): raise ValueError('Use a title, not a path')
    candidate=Path(location)
    if candidate.is_absolute():
        try:location=str(candidate.resolve().relative_to(root.resolve()))
        except ValueError as error:raise ValueError('Choose a file inside this owning vault') from error
    reserve(root,operation,{'action':'reconnect','record':identity,'title':title,'location':location})
    from .activities import operation_status
    committed=operation_status(root,operation)
    if committed['status']=='committed':
        if committed['records']:return committed['records'][0]
        raise ValueError('This reconnect already committed; inspect its history')
    destination = contained(root, location)
    old = props.get('local_file') or props.get('location')
    if not destination.is_file(): raise ValueError('Choose an existing file inside this owning vault')
    if props.get('artifact_kind') == 'drawing' and not (destination.suffix == '.canvas' or destination.name.endswith('.excalidraw.md')):
        raise ValueError('Choose an editable Canvas or Excalidraw file; exports are separate figures')
    if props.get('artifact_kind')=='drawing' and title!=props.get('title') and location==old and native_cli:
        suffix='.excalidraw.md' if destination.name.endswith('.excalidraw.md') else '.canvas'
        renamed=destination.with_name(title+suffix)
        if renamed.exists():raise ValueError('Another drawing already uses this name; choose another title')
        before_hash=hashlib.sha256(destination.read_bytes()).hexdigest()
        begin_publication(root,operation)
        try:
            native_cli(root,'move','path='+location,'to='+str(renamed.relative_to(root)))
        except (subprocess.SubprocessError,OSError,ValueError):
            # Native CLI acknowledgement may be lost after a successful move.
            # Confirm exact bytes and old-path absence; never repeat the mutation.
            if destination.exists() or not renamed.is_file() or hashlib.sha256(renamed.read_bytes()).hexdigest()!=before_hash:raise
        location=str(renamed.relative_to(root));destination=renamed
        if not destination.is_file():raise ValueError('Native rename was not confirmed; locate the drawing before retrying')
    begin_publication(root,operation)
    with lock(root):
        path = contained(root, record['path']); original = path.read_text(); updated, body = parse(original)
        updated.update(title=title, local_file=location, location=location)
        publish(path, render(updated, body.replace('[['+str(old)+']]', '[['+location+']]')), checksum(original))
    return record_activity(root, record['path'], 'artifact-check', 'Learner explicitly reconnected the owned artifact; content is not duplicated.', operation_id=operation,
                           location=location, availability='available', previous_location=old)


def recover(root, operation):
    """Publish a confirmed partial artifact; never repeat an external creation."""
    reservation=contained(root,'.Noesis/Executions/'+operation+'.json')
    request=json.loads(reservation.read_text()).get('request',{})
    if request.get('action')!='prepare':raise ValueError('This operation is not a recoverable artifact creation')
    mode=request['mode']
    expected=contained(root,'Explorations/'+operation+('/scratch.py' if mode=='scratch' else '/drawing.excalidraw.md' if mode=='freehand' else '/map.canvas'))
    if mode=='scratch' and request.get('code_file'):expected=Path(request['code_file'])
    if not expected.is_file():raise ValueError('No created file is confirmed. Inspect Obsidian and the preserved operation; recovery will not repeat creation.')
    return prepare(root,request['origin'],request['title'],mode,operation,prediction=request.get('prediction',''),code_file=request.get('code_file'))
