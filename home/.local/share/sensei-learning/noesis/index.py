import hashlib
import json
from pathlib import Path
import sqlite3
import uuid
from .persistence import notes, parse, contained, manifest_path


class Index:
    def __init__(self, root, cache=None):
        self.root = Path(root).resolve()
        try:
            self.manifest = json.loads(manifest_path(self.root).read_text())
        except (ValueError, OSError):
            self.manifest = {}
        folder = Path(cache) if cache else Path.home() / '.cache/noesis'
        folder.mkdir(parents=True, exist_ok=True, mode=0o700)
        folder.chmod(0o700)
        key = hashlib.sha256(str(self.root).encode()).hexdigest()
        self.db = sqlite3.connect(folder / (key + '.sqlite'))
        (folder / (key + '.sqlite')).chmod(0o600)
        self.db.executescript('''
            CREATE TABLE IF NOT EXISTS records(path TEXT PRIMARY KEY, stamp TEXT,
              id TEXT, kind TEXT, title TEXT, props TEXT, body TEXT);
            CREATE INDEX IF NOT EXISTS identities ON records(id);
            CREATE TABLE IF NOT EXISTS meta(generation INTEGER);
            INSERT INTO meta SELECT 0 WHERE NOT EXISTS(SELECT 1 FROM meta);
            CREATE VIRTUAL TABLE IF NOT EXISTS search USING fts5(path UNINDEXED,title,body);
            CREATE TABLE IF NOT EXISTS activities(path TEXT PRIMARY KEY,target TEXT,timestamp TEXT,props TEXT);
            CREATE INDEX IF NOT EXISTS activity_target ON activities(target,timestamp);
            CREATE TABLE IF NOT EXISTS relationships(path TEXT PRIMARY KEY,source TEXT,target TEXT,relation TEXT,role TEXT,context TEXT,props TEXT);
            CREATE INDEX IF NOT EXISTS relationship_source ON relationships(source);
            CREATE INDEX IF NOT EXISTS relationship_target ON relationships(target);
            CREATE TABLE IF NOT EXISTS aliases(path TEXT,alias TEXT);
            CREATE INDEX IF NOT EXISTS external_alias ON aliases(alias);
            CREATE INDEX IF NOT EXISTS alias_path ON aliases(path);
        ''')
        if self.db.execute('PRAGMA user_version').fetchone()[0] != 3:
            with self.db:
                for table in ('records', 'search', 'activities', 'relationships', 'aliases'):
                    self.db.execute('DELETE FROM ' + table)
                self.db.execute('PRAGMA user_version=3')

    def close(self):
        self.db.close()

    def reconcile(self, paths=None):
        if paths is None:
            previous = dict(self.db.execute('SELECT path,stamp FROM records'))
            candidates = notes(self.root)
        else:
            if not isinstance(paths, list) or len(paths) > 1000:raise ValueError('Changed paths must be a bounded list')
            targets = [contained(self.root, p) for p in paths]
            if any(p.suffix != '.md' for p in targets):return self.reconcile()
            previous = {}
            for path in targets:
                row = self.db.execute('SELECT path,stamp FROM records WHERE path=?', (str(path.relative_to(self.root)),)).fetchone()
                if row:previous[row[0]] = row[1]
            candidates = [p for p in targets if p.is_file() and not p.is_symlink()]
        seen, errors, changed = set(), [], False
        with self.db:
            for path in candidates:
                relative = str(path.relative_to(self.root))
                if relative.startswith((self.manifest.get('templates', 'Templates') + '/', '92 Templates/')):continue
                seen.add(relative)
                stat = path.stat()
                stamp = str((stat.st_mtime_ns, stat.st_size, stat.st_ino))
                if previous.get(relative) == stamp:
                    continue
                try:
                    props, body = parse(path.read_text())
                    if props.get('noesis_schema') == 2:
                        uuid.UUID(str(props.get('id', '')))
                    if props.get('type') == 'activity' and not isinstance(props.get('target'), dict):
                        raise ValueError('Activity needs a structured durable target')
                    if props.get('external_aliases') is not None and not isinstance(props['external_aliases'], list):
                        raise ValueError('External aliases must be a list')
                    title = props.get('title') or props.get('imported_title') or path.stem
                    self.db.execute('DELETE FROM search WHERE rowid IN (SELECT rowid FROM records WHERE path=?)', (relative,))
                    row = self.db.execute('INSERT OR REPLACE INTO records VALUES(?,?,?,?,?,?,?)',
                        (relative, stamp, str(props.get('id', '')), str(props.get('type', 'note')), str(title), json.dumps(props, default=str), body))
                    self.db.execute('INSERT INTO search(rowid,path,title,body) VALUES(?,?,?,?)', (row.lastrowid, relative, str(title), body))
                    for table in ('activities', 'relationships', 'aliases'):
                        self.db.execute('DELETE FROM ' + table + ' WHERE path=?', (relative,))
                    raw = json.dumps(props, default=str)
                    if props.get('type') == 'activity':
                        self.db.execute('INSERT INTO activities VALUES(?,?,?,?)', (relative, props.get('target', {}).get('record_id'), props.get('timestamp'), raw))
                    if props.get('type') == 'relationship':
                        self.db.execute('INSERT INTO relationships VALUES(?,?,?,?,?,?,?)', (relative, props.get('source'), props.get('target'), props.get('relation'), props.get('role'), props.get('context'), raw))
                    for alias in props.get('external_aliases', []):
                        self.db.execute('INSERT INTO aliases VALUES(?,?)', (relative, str(alias)))
                    changed = True
                except (ValueError, OSError) as error:
                    errors.append({'path': relative, 'error': str(error)})
                    self.db.execute('DELETE FROM search WHERE rowid IN (SELECT rowid FROM records WHERE path=?)', (relative,))
                    self.db.execute('DELETE FROM records WHERE path=?', (relative,))
                    for table in ('activities', 'relationships', 'aliases'):
                        self.db.execute('DELETE FROM ' + table + ' WHERE path=?', (relative,))
                    changed = True
            for relative in previous.keys() - seen:
                self.db.execute('DELETE FROM search WHERE rowid IN (SELECT rowid FROM records WHERE path=?)', (relative,))
                self.db.execute('DELETE FROM records WHERE path=?', (relative,))
                for table in ('activities', 'relationships', 'aliases'):
                    self.db.execute('DELETE FROM ' + table + ' WHERE path=?', (relative,))
                changed = True
            if changed:
                self.db.execute('UPDATE meta SET generation=generation+1')
        duplicates = list(self.db.execute("SELECT lower(id) FROM records WHERE id!='' GROUP BY lower(id) HAVING COUNT(*)>1"))
        errors.extend({'error': 'Duplicate ID: ' + row[0]} for row in duplicates)
        return {'generation': self.generation, 'errors': errors}

    @property
    def generation(self):
        return self.db.execute('SELECT generation FROM meta').fetchone()[0]

    def query(self, query='', kind=None, cursor=0, limit=50):
        if not isinstance(query, str):raise ValueError('Search query must be text')
        query = query.strip()
        limit = min(50, max(1, int(limit)))
        cursor = max(0, int(cursor))
        where, args = ([] if kind else ["kind NOT IN ('activity','relationship') AND kind NOT LIKE 'imported-%'"]), []
        if query:
            # Quoted tokens avoid exposing FTS operators as a command language.
            where.append('path IN (SELECT path FROM search WHERE search MATCH ?)')
            args.append(' AND '.join('"' + s.replace('"', '""') + '"*' for s in query.split()))
        if kind:
            kinds = kind if isinstance(kind, list) else [kind]
            where.append('kind IN (' + ','.join('?' for _ in kinds) + ')')
            args.extend(kinds)
        sql = 'SELECT path,id,kind,title FROM records'
        if where:
            sql += ' WHERE ' + ' AND '.join(where)
        rows = list(self.db.execute(sql + ' ORDER BY path LIMIT ? OFFSET ?', args + [limit + 1, cursor]))
        results, size = [], 0
        for row in rows[:limit]:
            item = dict(zip(('path', 'id', 'type', 'title'), row))
            item['title'] = item['title'][:256]
            item['type'] = item['type'][:80]
            item_size = len(json.dumps(item).encode())
            if results and size + item_size > 60 * 1024:break
            results.append(item)
            size += item_size
        return {'generation': self.generation, 'records': results, 'cursor': cursor + len(results) if len(rows) > len(results) else None}

    def record(self, identity):
        rows = list(self.db.execute('SELECT path,props,body FROM records WHERE id=?', (identity,)))
        if len(rows) != 1:
            raise ValueError('Target ID missing or duplicated: ' + identity)
        path, props, body = rows[0]
        metadata = json.loads(props)
        from .activities import progress_state
        try:
            state, head = progress_state(metadata, self.timeline(identity))
        except ValueError as error:
            state, head = {'conflict': str(error)}, None
        artifact = None
        if metadata.get('type') == 'artifact':
            location = metadata.get('location', metadata.get('local_file', ''))
            file = Path(location).expanduser() if location else None
            artifact = {'location': location, 'availability': 'available' if file and file.exists() else 'artifact unavailable', 'expected_checksum': metadata.get('sha256')}
        return {'path': path, 'props': metadata, 'body': body, 'state': state, 'activity_head': head, 'artifact': artifact}

    def timeline(self, identity):
        return [dict(json.loads(raw), path=path) for path, raw in self.db.execute('SELECT path,props FROM activities WHERE target=? ORDER BY timestamp,path', (identity,))]

    def relations(self, identity):
        result = []
        for path, raw in self.db.execute('SELECT path,props FROM relationships WHERE source=? OR target=? ORDER BY path LIMIT 50', (identity, identity)):
            props = json.loads(raw)
            other = props['target'] if props['source'] == identity else props['source']
            locations = list(self.db.execute('SELECT path,title,kind FROM records WHERE id=?', (other,)))
            row = dict(props, path=path, other_id=other)
            if len(locations) == 1:
                row.update(zip(('other_path', 'other_title', 'other_type'), locations[0]))
            else:row['availability'] = 'Missing or duplicate related identity'
            result.append(row)
        return sorted(result, key=lambda row: (row['order'] if type(row.get('order')) is int else float('inf'), row.get('other_title', ''), row['path']))
