#!/usr/bin/env python3
"""Create an optional engineering vault without modifying existing vault contents."""
import hashlib
import json
from pathlib import Path
import shutil
from datetime import datetime

home = Path.home()
vault = home / 'Study/Obsidian/Engineering/Workbench'
settings = vault / '.obsidian'
settings.mkdir(parents=True, exist_ok=True)
def fresh(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    if not path.exists(): path.write_text(json.dumps(value, indent=2) + '\n')
fresh(home / '.config/sensei-dev/knowledge.json', {'default_vault': str(vault), 'extra_vaults': []})
fresh(settings / 'core-plugins.json', ['file-explorer', 'global-search', 'switcher', 'graph', 'backlink', 'outgoing-link', 'tag-pane', 'properties', 'page-preview', 'daily-notes', 'templates', 'note-composer', 'command-palette', 'bookmarks', 'outline', 'word-count', 'file-recovery', 'canvas', 'bases'])
fresh(settings / 'templates.json', {'folder': 'Templates'})
fresh(settings / 'daily-notes.json', {'folder': 'Workbench/Daily', 'format': 'YYYY-MM-DD'})
plugins = []
source = home / 'Study/Obsidian/Robotics/Noesis/.obsidian/plugins'
for name in ['obsidian-excalidraw-plugin', 'obsidian-latex-suite']:
    origin = source / name
    if not (origin / 'manifest.json').exists(): continue
    destination = settings / 'plugins' / name
    destination.mkdir(parents=True, exist_ok=True)
    for filename in ['manifest.json', 'main.js', 'styles.css']:
        if (origin / filename).exists() and not (destination / filename).exists(): shutil.copy2(origin / filename, destination / filename)
    plugins.append(name)
fresh(settings / 'community-plugins.json', plugins)
(vault / 'Templates').mkdir(exist_ok=True)
(vault / 'Workbench/Daily').mkdir(parents=True, exist_ok=True)
index = vault / 'Start here.md'
if not index.exists():
    index.write_text('''# Workbench

Code in Neovim. Think, connect and sketch here. Use any vault you like.

[[Workbench/Engineering.base|Projects and experiments]]

From Neovim: `<Space>kp` project · `<Space>ha` code walkthrough · `<Space>kc` Canvas · `<Space>hs` drawing · `<Space>kS` search every registered vault.

Math uses `$inline$` or `$$display$$`. Canvas connects notes, code links and diagrams; Excalidraw handles pen drawings. Bases indexes properties without a second database.

Choose another destination with `sensei-dev knowledge PATH --vault NAME --kind project`. Extra vault paths live in `~/.config/sensei-dev/knowledge.json`; there is no count limit.
''')
registry = home / '.config/obsidian/obsidian.json'
app = json.loads(registry.read_text()) if registry.exists() else {}
if not any(x.get('path') == str(vault) for x in app.get('vaults', {}).values()):
    if registry.exists(): shutil.copy2(registry, registry.with_name('obsidian.json.backup-' + datetime.now().strftime('%Y%m%d-%H%M%S')))
    app.setdefault('vaults', {})[hashlib.sha256(str(vault).encode()).hexdigest()[:16]] = {'path': str(vault), 'ts': int(datetime.now().timestamp() * 1000), 'open': False}
    registry.parent.mkdir(parents=True, exist_ok=True)
    registry.write_text(json.dumps(app, indent=2) + '\n')
desktop = home / '.local/share/applications/sensei-dev.desktop'
desktop.parent.mkdir(parents=True, exist_ok=True)
desktop.write_text('[Desktop Entry]\nType=Application\nName=Sensei code link\nExec="' + str(home / '.local/bin/sensei-dev') + '" uri %u\nTerminal=false\nNoDisplay=true\nMimeType=x-scheme-handler/sensei-dev;\n')
print(vault)
