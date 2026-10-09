import hashlib
import json
from pathlib import Path
import sqlite3
import uuid
from .persistence import notes, parse, contained, manifest_path
from .presentation import display_title


def local_relationship(alias):
    """SQL ownership predicate; supply the current vault UUID for both endpoints."""
    if alias not in ('r','edge','edges'):raise ValueError('Unknown relationship query alias')
    return ' AND '.join("(json_extract("+alias+".props,'$."+endpoint+"_ref.vault_id') IS NULL OR json_extract("+alias+".props,'$."+endpoint+"_ref.vault_id')=?)" for endpoint in ('source','target'))


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
            CREATE TABLE IF NOT EXISTS cache_identity(token TEXT);
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
            CREATE TABLE IF NOT EXISTS states(id TEXT PRIMARY KEY,status TEXT,state TEXT);
            CREATE INDEX IF NOT EXISTS state_status ON states(status);
        ''')
        with self.db:
            if not self.db.execute('SELECT token FROM cache_identity').fetchone():
                self.db.execute('INSERT INTO cache_identity VALUES(?)',(str(uuid.uuid4()),))
        self.cache_identity=self.db.execute('SELECT token FROM cache_identity').fetchone()[0]
        if self.db.execute('PRAGMA user_version').fetchone()[0] != 6:
            with self.db:
                for table in ('records', 'search', 'activities', 'relationships', 'aliases', 'states'):
                    self.db.execute('DELETE FROM ' + table)
                self.db.execute('PRAGMA user_version=6')

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
        seen, errors, changed, affected = set(), [], False, set()
        def invalidate(relative):
            affected.update(row[0] for row in self.db.execute('SELECT id FROM records WHERE path=?',(relative,)) if row[0])
            affected.update(row[0] for row in self.db.execute('SELECT target FROM activities WHERE path=?',(relative,)) if row[0])
        with self.db:
            for path in candidates:
                relative = str(path.relative_to(self.root))
                if relative.startswith((self.manifest.get('templates', 'Templates') + '/', '92 Templates/')):continue
                seen.add(relative)
                stat = path.stat()
                stamp = str((stat.st_mtime_ns, stat.st_size, stat.st_ino))
                if previous.get(relative) == stamp:
                    continue
                invalidate(relative)
                try:
                    props, body = parse(path.read_text())
                    if props.get('noesis_schema') == 2:
                        uuid.UUID(str(props.get('id', '')))
                    if props.get('type') == 'activity' and not isinstance(props.get('target'), dict):
                        raise ValueError('Activity needs a structured durable target')
                    if props.get('type')=='activity' and props.get('noesis_schema')==2:
                        target=props['target']
                        uuid.UUID(str(target.get('record_id','')))
                        if target.get('vault_id')!=self.manifest.get('vault_id'):
                            raise ValueError('Activity belongs to another vault; preserve it and resolve ownership before applying its history')
                    if props.get('external_aliases') is not None and not isinstance(props['external_aliases'], list):
                        raise ValueError('External aliases must be a list')
                    if props.get('parent_ref'):
                        parent=props['parent_ref']
                        if not isinstance(parent,dict) or parent.get('vault_id')!=self.manifest.get('vault_id') or not parent.get('record_id'):
                            raise ValueError('Parent reference must identify a record in this vault')
                    title = display_title(props, relative)
                    self.db.execute('DELETE FROM search WHERE rowid IN (SELECT rowid FROM records WHERE path=?)', (relative,))
                    row = self.db.execute('INSERT OR REPLACE INTO records VALUES(?,?,?,?,?,?,?)',
                        (relative, stamp, str(props.get('id', '')), str(props.get('type', 'note')), str(title), json.dumps(props, default=str), body))
                    self.db.execute('INSERT INTO search(rowid,path,title,body) VALUES(?,?,?,?)', (row.lastrowid, relative, str(title), body))
                    for table in ('activities', 'relationships', 'aliases'):
                        self.db.execute('DELETE FROM ' + table + ' WHERE path=?', (relative,))
                    raw = json.dumps(props, default=str)
                    if props.get('id'):affected.add(str(props['id']))
                    if props.get('type') == 'activity':
                        if props.get('target',{}).get('record_id'):affected.add(props['target']['record_id'])
                        self.db.execute('INSERT INTO activities VALUES(?,?,?,?)', (relative, props.get('target', {}).get('record_id'), props.get('timestamp'), raw))
                    if props.get('type') == 'relationship':
                        self.db.execute('INSERT INTO relationships VALUES(?,?,?,?,?,?,?)', (relative, props.get('source'), props.get('target'), props.get('relation'), props.get('role'), props.get('context'), raw))
                    elif props.get('parent_ref'):
                        parent=props['parent_ref']
                        edge={'source':parent['record_id'],'target':props['id'],'source_ref':parent,
                              'target_ref':{'vault_id':self.manifest['vault_id'],'record_id':props['id']},
                              'relation':parent.get('relation','contains'),'order':parent.get('order'),'ownership':'child metadata'}
                        self.db.execute('INSERT INTO relationships VALUES(?,?,?,?,?,?,?)',(relative,edge['source'],edge['target'],edge['relation'],None,None,json.dumps(edge)))
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
                invalidate(relative)
                self.db.execute('DELETE FROM search WHERE rowid IN (SELECT rowid FROM records WHERE path=?)', (relative,))
                self.db.execute('DELETE FROM records WHERE path=?', (relative,))
                for table in ('activities', 'relationships', 'aliases'):
                    self.db.execute('DELETE FROM ' + table + ' WHERE path=?', (relative,))
                changed = True
            from .activities import progress_state
            for identity in affected:
                rows=list(self.db.execute("SELECT props FROM records WHERE id=? AND kind!='activity' AND kind NOT LIKE 'imported-%'",(identity,)))
                if len(rows)!=1:
                    self.db.execute('DELETE FROM states WHERE id=?',(identity,));continue
                try:state,_=progress_state(json.loads(rows[0][0]),self.timeline(identity))
                except ValueError as error:state={'conflict':str(error)}
                self.db.execute('INSERT OR REPLACE INTO states VALUES(?,?,?)',(identity,state.get('status'),json.dumps(state,default=str)))
            if changed:
                self.db.execute('UPDATE meta SET generation=generation+1')
        duplicates = list(self.db.execute("SELECT lower(id) FROM records WHERE id!='' GROUP BY lower(id) HAVING COUNT(*)>1"))
        errors.extend({'error': 'Duplicate ID: ' + row[0]} for row in duplicates)
        return {'generation': self.generation, 'errors': errors}

    @property
    def generation(self):
        return self.db.execute('SELECT generation FROM meta').fetchone()[0]

    def query(self, query='', kind=None, cursor=0, limit=50, resource_kinds=None, relevance=False):
        if not isinstance(query, str):raise ValueError('Search query must be text')
        query = query.strip()
        limit = min(50, max(1, int(limit)))
        cursor = max(0, int(cursor))
        where, args = ([] if kind else ["kind NOT IN ('activity','relationship') AND kind NOT LIKE 'imported-%'"]), []
        if query:
            # Quoted tokens avoid exposing FTS operators as a command language.
            import re
            alias=query.strip().lower()
            if re.match(r'^(https?://(dx\.)?doi\.org/|doi:)',alias):alias='doi:'+re.sub(r'^(https?://(dx\.)?doi\.org/|doi:)','',alias)
            elif re.match(r'^10\.\d{4,9}/',alias):alias='doi:'+alias
            where.append('(path IN (SELECT path FROM search WHERE search MATCH ?) OR path IN (SELECT path FROM aliases WHERE alias=?) OR records.id=?)')
            args.extend([' AND '.join('"' + s.replace('"', '""') + '"*' for s in query.split()),alias,query])
        if kind:
            kinds = kind if isinstance(kind, list) else [kind]
            where.append('kind IN (' + ','.join('?' for _ in kinds) + ')')
            args.extend(kinds)
        if resource_kinds is not None:
            if not isinstance(resource_kinds,list) or any(not isinstance(value,str) for value in resource_kinds):raise ValueError('Resource kinds must be a list of source kinds')
            where.append("(kind!='resource' OR json_extract(records.props,'$.source_kind') IN ("+','.join('?' for _ in resource_kinds)+'))')
            args.extend(resource_kinds)
        sql = "SELECT records.path,records.id,kind,title,states.status,COALESCE(json_extract(states.state,'$.material.source_kind'),json_extract(records.props,'$.source_kind')) FROM records LEFT JOIN states ON states.id=records.id"
        if where:
            sql += ' WHERE ' + ' AND '.join(where)
        order='path'
        if relevance:
            # One deterministic ordering shared by every owner in a collection.
            order='lower(substr(title,1,256)),path'
            if query:
                order='CASE WHEN records.id=? OR records.path IN (SELECT path FROM aliases WHERE alias=?) THEN 0 WHEN lower(substr(title,1,256))=? THEN 1 WHEN substr(lower(substr(title,1,256)),1,length(?))=? THEN 2 ELSE 3 END,'+order
                args.extend([query,alias,query.lower(),query.lower(),query.lower()])
        rows = list(self.db.execute(sql + ' ORDER BY '+order+' LIMIT ? OFFSET ?', args + [limit + 1, cursor]))
        results, size = [], 0
        for row in rows[:limit]:
            item = dict(zip(('path', 'id', 'type', 'title', 'status', 'source_kind'), row))
            item['title'] = item['title'][:256]
            item['type'] = item['type'][:80]
            item['source_kind']=item['source_kind'][:80] if isinstance(item['source_kind'],str) else None
            item_size = len(json.dumps(item).encode())
            if results and size + item_size > 60 * 1024:break
            results.append(item)
            size += item_size
        return {'generation': self.generation, 'records': results, 'cursor': cursor + len(results) if len(rows) > len(results) else None}

    def record(self, identity, include_body=True, include_attempt=True):
        rows = list(self.db.execute('SELECT path,props,'+('body' if include_body else "''")+' FROM records WHERE id=?', (identity,)))
        if len(rows) != 1:
            raise ValueError('Target ID missing or duplicated: ' + identity)
        path, props, body = rows[0]
        metadata = json.loads(props)
        from .activities import progress_state, unfinished_attempts
        try:
            cached=self.db.execute('SELECT state FROM states WHERE id=?',(identity,)).fetchone()
            if cached:state,head=json.loads(cached[0]),None
            else:state, head = progress_state(metadata, self.timeline(identity))
            if include_attempt:
                _,head=progress_state(metadata,self.timeline(identity))
        except ValueError as error:
            state, head = {'conflict': str(error)}, None
        artifact = None
        if metadata.get('type') == 'artifact':
            location = metadata.get('location', metadata.get('local_file', ''))
            file = Path(location).expanduser() if location else None
            artifact = {'location': location, 'availability': 'available' if file and file.exists() else 'artifact unavailable', 'expected_checksum': metadata.get('sha256')}
        unfinished = unfinished_attempts(self.timeline(identity)) if include_attempt else []
        from .materials import effective_props
        effective=effective_props(metadata,state)
        effective_source={key:effective.get(key) for key in ('source','source_kind','local_file','zotero_uri','zotero_attachment_key')}
        return {'effective_source':effective_source,'path': path, 'display_title':display_title(metadata,path), 'props': metadata, 'body': body, 'state': state, 'activity_head': head, 'artifact': artifact,
                'attempt': unfinished[0] if len(unfinished) == 1 else None, 'attempt_conflict': len(unfinished) > 1}

    def timeline(self, identity):
        return [dict(json.loads(raw), path=path) for path, raw in self.db.execute('SELECT path,props FROM activities WHERE target=? ORDER BY timestamp,path', (identity,))]

    def relations(self, identity):
        result = []
        for path, raw in self.db.execute('SELECT path,props FROM relationships WHERE source=? OR target=? ORDER BY path LIMIT 50', (identity, identity)):
            props = json.loads(raw)
            other = props['target'] if props['source'] == identity else props['source']
            reference=props.get('target_ref' if props['source']==identity else 'source_ref') or {}
            row = dict(props, path=path, other_id=other)
            if reference.get('vault_id') and reference['vault_id']!=self.manifest.get('vault_id'):
                try:
                    from .references import resolve
                    resolved=resolve(reference)
                    row.update(other_path=resolved['path'],other_title=resolved['title'],other_type=resolved['type'],other_status=resolved['status'],other_vault=resolved['vault'],other_vault_id=resolved['vault_id'])
                except (ValueError,OSError,KeyError) as error:row['availability']=str(error)
                result.append(row);continue
            locations = list(self.db.execute('SELECT r.path,r.title,r.kind,s.status FROM records r LEFT JOIN states s ON s.id=r.id WHERE r.id=?', (other,)))
            if len(locations) == 1:
                row.update(zip(('other_path', 'other_title', 'other_type','other_status'), locations[0]))
            else:row['availability'] = 'Missing or duplicate related identity'
            result.append(row)
        return sorted(result, key=lambda row: (row['order'] if type(row.get('order')) is int else float('inf'), row.get('other_title', ''), row['path']))
