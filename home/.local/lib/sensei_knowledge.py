"""Local, vault-count-independent bridge between code and Obsidian."""
from datetime import datetime
import hashlib
import json
from pathlib import Path
import re
from urllib.parse import urlencode

def configuration(host):
    f = host / '.config/sensei-dev/knowledge.json'
    cfg = json.loads(f.read_text()) if f.exists() else {}
    registered = host / '.config/obsidian/obsidian.json'
    app = json.loads(registered.read_text()) if registered.exists() else {}
    paths = [Path(v['path']) for v in app.get('vaults', {}).values() if Path(v['path']).is_dir()]
    paths += [Path(p).expanduser() for p in cfg.get('extra_vaults', []) if Path(p).expanduser().is_dir()]
    default = Path(cfg.get('default_vault', host / 'Study/Obsidian/Engineering/Workbench'))
    if default.is_dir(): paths.insert(0, default)
    unique = list(dict.fromkeys(str(p.resolve()) for p in paths))
    names = {}
    vaults = []
    for path in unique:
        name = Path(path).name
        if name in names: name += '-' + hashlib.sha256(path.encode()).hexdigest()[:6]
        names[name] = path
        vaults.append({'name': name, 'path': path})
    return {**cfg, 'default_vault': str(default), 'vaults': vaults}

def uri(vault, relative=None):
    values = {'path': str(Path(vault) / relative)} if relative else {'vault': str(vault)}
    return 'obsidian://open?' + urlencode(values)

def put_new(file, text):
    file.parent.mkdir(parents=True, exist_ok=True)
    if not file.exists(): file.write_text(text)
    return file

def frontmatter(p, kind):
    # JSON strings are valid YAML scalar values; names/paths cannot inject keys.
    return '\n'.join(['---', 'type: ' + kind, 'project: ' + json.dumps(Path(p['root']).name),
        'source_root: ' + json.dumps(p['root']), 'environment: ' + json.dumps(p.get('container') or 'host'),
        'created: ' + datetime.now().strftime('%Y-%m-%d'), 'status: active', 'tags: [engineering, workbench]', '---', ''])

def project(host, p, vault=None):
    cfg = configuration(host)
    chosen = vault or p.get('knowledge_vault') or cfg['default_vault']
    matching = next((v['path'] for v in cfg['vaults'] if v['name'] == chosen or v['path'] == chosen), chosen)
    root = Path(matching)
    if not root.is_dir(): raise ValueError('Vault not available: ' + str(root))
    token = re.sub(r'[^\w .-]', '-', Path(p['root']).name) + '-' + hashlib.sha256(p['root'].encode()).hexdigest()[:8]
    rel = Path('Workbench/Projects') / token
    directory = root / rel
    link = lambda name: '[[' + str(rel / name) + ']]'
    code_uri = 'sensei-dev://open?' + urlencode({'project': p['root']})
    put_new(directory / 'Project.md', frontmatter(p, 'project') + '# ' + Path(p['root']).name + '\n\n'
        + '[Open code in Neovim](' + code_uri + ') · ' + link('Map.canvas') + ' · ' + link('Scratchpad.md') + '\n\n'
        + '## Working question\n\n## Contract and interfaces\n\n## Decisions / evidence\n\n## Next experiment\n\n'
        + '![[Workbench/Engineering.base]]\n')
    put_new(directory / 'Scratchpad.md', frontmatter(p, 'scratchpad') + '# Workbench\n\n'
        + link('Project.md') + '\n\n## Question\n\n## Hypothesis\n\n## Experiment\n\n## Observation\n\n## Decision\n\n- [ ] Next action\n')
    canvas = {'nodes': [
        {'id': 'project', 'type': 'file', 'file': str(rel / 'Project.md'), 'x': 0, 'y': 0, 'width': 420, 'height': 500},
        {'id': 'experiment', 'type': 'file', 'file': str(rel / 'Scratchpad.md'), 'x': 500, 'y': 0, 'width': 420, 'height': 500},
        {'id': 'model', 'type': 'text', 'text': '## Model before code\n\nInputs → state → outputs\n\nUnits · frames · timing · failure recovery', 'x': 0, 'y': 580, 'width': 420, 'height': 250}],
        'edges': [{'id': 'test', 'fromNode': 'project', 'fromSide': 'right', 'toNode': 'experiment', 'toSide': 'left', 'label': 'test the claim'},
            {'id': 'reason', 'fromNode': 'model', 'fromSide': 'top', 'toNode': 'project', 'toSide': 'bottom', 'label': 'justify the contract'}]}
    put_new(directory / 'Map.canvas', json.dumps(canvas, indent=2))
    base = '''filters:
  and:
    - 'file.inFolder("Workbench/Projects")'
    - 'file.ext == "md"'
properties:
  project:
    displayName: Project
  type:
    displayName: Kind
  status:
    displayName: Status
views:
  - type: table
    name: Engineering
    order:
      - file.name
      - project
      - type
      - status
      - file.mtime
    sort:
      - property: file.mtime
        direction: DESC
  - type: table
    name: Code walkthroughs
    filters:
      and:
        - 'type == "code-review"'
    order:
      - file.name
      - project
      - source_file
      - created
'''
    put_new(root / 'Workbench/Engineering.base', base)
    return root, rel, directory

def action(host, p, kind, vault=None, source_file='', excerpt='', start=1, end=1, filetype=''):
    root, rel, directory = project(host, p, vault)
    if kind == 'project' or kind == 'open': return directory / 'Project.md', kind == 'open'
    if kind == 'scratchpad': return directory / 'Scratchpad.md', False
    if kind == 'canvas': return directory / 'Map.canvas', True
    if kind == 'draw':
        drawing = {'type': 'excalidraw', 'version': 2, 'source': 'https://excalidraw.com',
            'elements': [], 'appState': {'viewBackgroundColor': '#ffffff', 'gridSize': None}, 'files': {}}
        text = '---\nexcalidraw-plugin: parsed\ntags: [excalidraw, engineering]\n---\n\n# Excalidraw Data\n\n## Text Elements\n\n## Drawing\n```json\n' + json.dumps(drawing, indent=2) + '\n```\n'
        return put_new(directory / 'Drawing.excalidraw.md', text), True
    if kind == 'base': return root / 'Workbench/Engineering.base', True
    if kind == 'daily':
        f = root / 'Workbench/Daily' / (datetime.now().strftime('%Y-%m-%d') + '.md')
        return put_new(f, '# ' + datetime.now().strftime('%A, %d %B %Y') + '\n\n'
            + '[[' + str(rel / 'Project.md') + ']]\n\n## Intent\n\n## Experiment / evidence\n\n## What I understood\n\n- [ ] Next action\n'), False
    if kind == 'review':
        code_link = 'sensei-dev://open?' + urlencode({'project': p['root'], 'file': source_file, 'line': start})
        f = directory / (datetime.now().strftime('%Y%m%d-%H%M%S-%f') + '-walkthrough.md')
        content = frontmatter(p, 'code-review')
        content = content.replace('status: active', 'source_file: ' + json.dumps(source_file) + '\nsource_line: ' + str(start) + '\nstatus: learning')
        content += '# Explain it before trusting it\n\n[[' + str(rel / 'Project.md') + ']] · [Return to code](' + code_link + ')\n\n'
        content += f'Source lines: {start}–{end}\n\n```{filetype}\n{excerpt}\n```\n\n'
        content += '## Contract / invariants\nWhat enters, what leaves, and what must remain true?\n\n'
        content += '## Trace one input\nUnits, frames, ownership, state, timing and failure recovery.\n\n'
        content += '## Why this design?\nCompare a simpler alternative. Which evidence decides?\n\n'
        content += '## Counterexample\nPredict a boundary test, then run it.\n\n'
        content += '## Explain without the agent\nReimplement one small part. Which assumption was hardest?\n\n'
        content += '## References / confidence\nSeparate measured facts from claims.\n\n- [ ] Next experiment\n'
        return put_new(f, content), False
    raise ValueError('Unknown knowledge action')
