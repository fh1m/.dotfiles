import contextlib
import fcntl
import hashlib
import json
import os
from pathlib import Path
import tempfile
import uuid
import yaml


class StrictLoader(yaml.SafeLoader):
    pass


def mapping(loader, node, deep=False):
    result = {}
    for key, value in node.value:
        name = loader.construct_object(key, deep=deep)
        if name in result:
            raise ValueError('Duplicate frontmatter key: ' + str(name))
        result[name] = loader.construct_object(value, deep=deep)
    return result


StrictLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, mapping)


def parse(text):
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].rstrip('\r\n') != '---':
        return {}, text
    end = next((i for i in range(1, len(lines)) if lines[i].rstrip('\r\n') == '---'), None)
    if end is None:
        raise ValueError('Unclosed frontmatter')
    try:
        props = yaml.load(''.join(lines[1:end]), Loader=StrictLoader) or {}
    except yaml.YAMLError as error:
        raise ValueError('Malformed frontmatter: ' + str(error)) from error
    if not isinstance(props, dict):
        raise ValueError('Frontmatter must be a mapping')
    return props, ''.join(lines[end + 1:])


def render(props, body):
    return '---\n' + yaml.safe_dump(props, sort_keys=False, allow_unicode=True) + '---\n' + body


def contained(root, relative):
    root = Path(root).resolve()
    path = Path(relative)
    if path.is_absolute() or '..' in path.parts:
        raise ValueError('Path must be inside vault')
    target = (root / path).resolve()
    if not target.is_relative_to(root):
        raise ValueError('Path escapes vault')
    return target


def checksum(text):
    return hashlib.sha256(text.encode()).hexdigest()


@contextlib.contextmanager
def lock(root):
    # Local lock is separate from syncable content and keyed by canonical location.
    folder = Path.home() / '.local/state/sensei-learning/locks'
    folder.mkdir(parents=True, exist_ok=True)
    key = hashlib.sha256(str(Path(root).resolve()).encode()).hexdigest()
    with (folder / key).open('a') as stream:
        fcntl.flock(stream, fcntl.LOCK_EX)
        yield


def publish(path, text, expected=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix='.noesis-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        if expected is None:
            os.link(temp, path)  # exclusive atomic publication; never overwrite
        else:
            if checksum(path.read_text()) != expected:
                raise ValueError('Content changed; refusing conflicting update')
            os.replace(temp, path)
        directory = os.open(path.parent, os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def notes(root):
    for folder, dirs, files in os.walk(root, followlinks=False):
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in {'node_modules', 'Datasets', 'Runs'} and not (Path(folder) / d).is_symlink()]
        for name in files:
            path = Path(folder) / name
            if path.suffix == '.md' and not path.is_symlink():
                yield path


def manifest_path(root):
    for relative in ('System/System.json', '94 Meta/System.json'):
        path = contained(root, relative)
        if path.is_file():
            return path
    raise ValueError('No Noesis manifest; adopt this vault explicitly first')


def migration(root, apply=False):
    with lock(root):
        manifest = manifest_path(root)
        original = manifest.read_text()
        meta = json.loads(original)
        changes, seen = [], {}
        for path in sorted(notes(root)):
            relative = str(path.relative_to(root))
            if relative.startswith((meta.get('templates', 'Templates') + '/', '92 Templates/')):
                continue
            text = path.read_text()
            props, body = parse(text)
            identity = props.get('id')
            if identity:
                canonical = str(uuid.UUID(str(identity)))
                if canonical in seen:
                    raise ValueError('Duplicate ID: ' + relative + ' and ' + seen[canonical])
                seen[canonical] = relative
            updated = dict(props, id=identity or str(uuid.uuid4()), noesis_schema=2)
            if updated != props:
                changes.append((path, text, render(updated, body)))
        updated_meta = dict(meta, noesis_schema=2, vault_id=meta.get('vault_id') or str(uuid.uuid4()), activity=meta.get('activity', 'Activity'))
        uuid.UUID(updated_meta['vault_id'])
        contained(root, updated_meta['activity'])
        result = {'vault': str(root), 'apply': apply, 'changed': [str(p.relative_to(root)) for p, _, _ in changes]}
        if apply:
            # Keep originals outside the vault before the first changed byte.
            backup = Path.home() / '.local/state/sensei-learning/migrations' / str(uuid.uuid4())
            backup.mkdir(parents=True, mode=0o700)
            for path, text, _ in changes:
                target = backup / path.relative_to(root)
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(text)
            target = backup / manifest.relative_to(root)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(original)
            for path, text, replacement in changes:
                publish(path, replacement, checksum(text))
            if updated_meta != meta:
                publish(manifest, json.dumps(updated_meta, indent=2) + '\n', checksum(original))
            result['backup'] = str(backup)
        return result
