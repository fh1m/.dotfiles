"""Native, owned handwriting artifacts; PDF previews are disposable projections."""
import gzip
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import uuid
import xml.etree.ElementTree as ET
from .persistence import contained, lock

LIMIT=64*1024*1024
PAPERS=('plain','lined','graph')

def atomic_bytes(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    fd,name=tempfile.mkstemp(prefix='.'+path.name+'.',dir=path.parent)
    try:
        with os.fdopen(fd,'wb') as f:f.write(data);f.flush();os.fsync(f.fileno())
        os.replace(name,path)
    finally:
        if os.path.exists(name):os.unlink(name)

def prepare(root,identity,title,operation,paper='plain',pdf_file=None):
    from .exploration import target,reserve,begin_publication
    from .models import create
    from .scopes import assert_unique
    root=Path(root);assert_unique(root)
    if paper not in PAPERS:raise ValueError('Choose plain, lined or graph paper')
    if not title.strip() or any(c in title for c in '/\\\n\r\0'):raise ValueError('Use a title, not a path')
    origin=target(root,identity);uuid.UUID(operation)
    folder='Explorations/'+operation
    name='notebook-'+operation+'.xopp'
    file=contained(root,folder+'/'+name);preview=folder+'/preview.pdf'
    source=None;payload=None
    if pdf_file:
        source=Path(pdf_file).expanduser().resolve()
        copied=file.parent/'background.pdf'
        selected=copied if file.is_file() and copied.is_file() else source
        if not selected.is_file() or selected.suffix.lower()!='.pdf' or selected.stat().st_size>LIMIT:raise ValueError('Choose a local PDF below 64 MiB')
        with selected.open('rb') as f:payload=f.read(LIMIT+1)
        if len(payload)>LIMIT or not payload.startswith(b'%PDF-'):raise ValueError('Invalid or oversized PDF background')
        if not shutil.which('xournalpp'):raise ValueError('Xournal++ is required for PDF ink; original PDF unchanged')
    request={'action':'prepare','origin':identity,'title':title,'mode':'ink','paper':paper,
             'pdf_file':str(source) if source else None,'pdf_sha256':hashlib.sha256(payload).hexdigest() if payload else None}
    reserve(root,operation,request);begin_publication(root,operation)
    with lock(root):
        file.parent.mkdir(parents=True,exist_ok=True)
        if not file.exists():
            if source:
                background=file.parent/'background.pdf'
                if not background.exists():atomic_bytes(background,payload)
                elif hashlib.sha256(background.read_bytes()).hexdigest()!=request['pdf_sha256']:raise ValueError('Existing background differs; preserved for recovery')
                # Same-directory CLI conversion keeps the background reference relative.
                staging=file.with_name('.creating-'+uuid.uuid4().hex+'.xopp')
                try:
                    result=subprocess.run(['xournalpp','-s',str(staging),str(background)],capture_output=True,timeout=30)
                    if result.returncode or not staging.is_file():raise ValueError('PDF journal creation failed; original PDF unchanged')
                    staging.chmod(0o600);os.replace(staging,file)
                finally:staging.unlink(missing_ok=True)
            else:
                journal=ET.Element('xournal',{'creator':'Noesis / Xournal++','fileversion':'4'})
                ET.SubElement(journal,'title').text=title
                page=ET.SubElement(journal,'page',{'width':'842','height':'595'})
                ET.SubElement(page,'background',{'type':'solid','color':'#ffffffff','style':paper})
                ET.SubElement(page,'layer')
                atomic_bytes(file,gzip.compress(ET.tostring(journal,encoding='utf-8',xml_declaration=True)))
    body=('Editable handwriting, not a competence claim.\n\nOrigin: [['+origin['path']+']]\n\n'
          '## Working model\n\nUse the notebook for derivations, diagrams, observations or reconstruction. '
          'Preserve an earlier failed model rather than erasing it.\n\n'
          '## Notebook\n\n[['+folder+'/'+name+']]\n\n'
          '## Saved preview\n\n![['+preview+']]\n\n'
          'Save in Xournal++; the current notebook preview refreshes after the saved file settles. '
          'Keep any assessment and assistance disclosure in the linked learning attempt.\n')
    return create(root,'artifact',title,body,fields={'local_file':folder+'/'+name,'location':folder+'/'+name,
                  'preview_file':preview,'artifact_kind':'drawing','drawing_format':'ink','paper':paper,
                  'background_file':folder+'/background.pdf' if source else None,
                  'origin_ref':{'record_id':identity,'vault_id':origin['vault_id']}},
                  parent_id=identity,relation='references',operation_id=operation)

def publish_preview(root,identity):
    from .exploration import local_file
    root=Path(root);record,file=local_file(root,identity);props=record['props']
    if props.get('drawing_format')!='ink' or file.suffix!='.xopp' or not file.resolve().is_relative_to(root.resolve()):raise ValueError('Choose an owned Noesis ink notebook')
    output=contained(root,props['preview_file']);receipt=output.with_name('.preview.json')
    binary=shutil.which('xournalpp')
    if not binary:raise ValueError('Xournal++ unavailable; notebook and last preview preserved')
    with lock(root):
        with file.open('rb') as f:data=f.read(LIMIT+1)
        if len(data)>LIMIT:raise ValueError('Notebook exceeds 64 MiB; use Xournal++ export directly')
        digest=hashlib.sha256(data).hexdigest()
        background=file.parent/'background.pdf'
        bg_digest=None
        if background.is_file():
            with background.open('rb') as f:bg=f.read(LIMIT+1)
            if len(bg)>LIMIT:raise ValueError('PDF background exceeds 64 MiB; last preview preserved')
            bg_digest=hashlib.sha256(bg).hexdigest()
        key={'source_sha256':digest,'background_sha256':bg_digest,'source_path':str(file.relative_to(root))}
        try:old=json.loads(receipt.read_text())
        except (OSError,ValueError):old={}
        if old==key and output.is_file():return {'published':False,'preview':str(output),'source_sha256':digest}
        # Snapshot beside its background, so export cannot observe half a save.
        token=uuid.uuid4().hex;snapshot=file.with_name('.ink-'+token+'.xopp');temp=output.with_name('.preview-'+token+'.pdf')
        try:
            atomic_bytes(snapshot,data)
            result=subprocess.run([binary,'-p',str(temp),str(snapshot)],capture_output=True,timeout=30)
            if result.returncode or not temp.is_file() or temp.stat().st_size>LIMIT:raise ValueError('Preview export failed; last preview preserved')
            with temp.open('rb') as f:
                if f.read(5)!=b'%PDF-':raise ValueError('Invalid PDF export; last preview preserved')
            with file.open('rb') as f:after=f.read(LIMIT+1)
            if len(after)>LIMIT or hashlib.sha256(after).hexdigest()!=digest:raise ValueError('Notebook changed during export; save again for a fresh preview')
            if background.is_file():
                with background.open('rb') as f:after_bg=f.read(LIMIT+1)
                if len(after_bg)>LIMIT or hashlib.sha256(after_bg).hexdigest()!=bg_digest:raise ValueError('Background changed during export; last preview preserved')
            temp.chmod(0o600);os.replace(temp,output)
            atomic_bytes(receipt,json.dumps(key).encode())
        except (OSError,subprocess.SubprocessError) as error:raise ValueError('Preview export unavailable; notebook and last preview preserved') from error
        finally:
            snapshot.unlink(missing_ok=True);temp.unlink(missing_ok=True)
    return {'published':True,'preview':str(output),'source_sha256':digest}
