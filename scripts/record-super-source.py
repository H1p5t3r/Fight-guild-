#!/usr/bin/env python3
"""Copy an original generated super atlas and record its exact provenance."""
import argparse,hashlib,json,shutil
from pathlib import Path
from PIL import Image
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('super');p.add_argument('key');p.add_argument('source',type=Path)
p.add_argument('--reference',action='append',default=[]);p.add_argument('--prompt')
a=p.parse_args();root=Path(__file__).resolve().parents[1]
production=root/'art/characters/supers-v2'/a.super
out=root/'godot/assets/fighters/supers-v2'/a.super/(a.key+'.png');out.parent.mkdir(parents=True,exist_ok=True)
im=Image.open(a.source)
assert im.mode=='RGBA' and im.size==(1536,1024),(im.mode,im.size)
assert im.getchannel('A').getextrema()[0]==0,'Background is not transparent; regenerate it.'
shutil.copyfile(a.source,out)
record=dict(id=a.key,file=str(out.relative_to(root)),original=str(a.source),sha256=hashlib.sha256(out.read_bytes()).hexdigest(),prompt=a.prompt or str((production/(a.key+'-prompt.txt')).relative_to(root)),references=a.reference)
p=production/'sources.json';sources=json.loads(p.read_text()) if p.exists() else []
sources=[s for s in sources if s['id']!=a.key]+[record];p.write_text(json.dumps(sources,indent=2)+'\n')
print(a.super,a.key,im.size,'original bytes retained')
