#!/usr/bin/env python3
"""Extract saved normal tables and embedded hitbox diagrams; no network requests.

Usage: python scripts/extract-dustloop-frame-archive.py archive.mht queen-dizzy
Requires lxml and Pillow. Original diagram bytes are retained, never repainted.
"""
from pathlib import Path
from email import policy
from email.parser import BytesParser
from urllib.parse import urlsplit, unquote
import argparse, hashlib, io, json, re
from lxml import html
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('archive', type=Path)
parser.add_argument('character', choices=['queen-dizzy', 'leo-whitefang', 'ky-kiske'])
parser.add_argument('--exclude-dust', action='store_true', help='Omit D normals and their diagrams from this reference pass.')
args = parser.parse_args()
raw = args.archive.read_bytes()
message = BytesParser(policy=policy.default).parsebytes(raw)
parts = [p for p in message.walk() if not p.is_multipart()]
page = next(p for p in parts if p.get_content_type() == 'text/html')
tree = html.fromstring(page.get_payload(decode=True))
normal = next(t for t in tree.xpath('//table') if t.xpath('./tbody/tr[@data-mw-details]'))
headers = ['', 'Input', 'Damage', 'Guard', 'Startup', 'Active', 'Recovery',
           'On-Block', 'On-Hit', 'Level', 'Counter Type', 'Invuln', 'Proration', 'RISC Gain', 'RISC Loss']
text = lambda n: ' '.join(n.text_content().split())
outdir = ROOT / 'references/frame-data' / (args.character + '-2026-11-18')
outdir.mkdir(parents=True, exist_ok=True)
images = {}
image_bytes = {}
for part in parts:
    location = str(part.get('Content-Location', ''))
    if part.get_content_type() != 'image/png' or 'hitbox' not in location.lower():
        continue
    data = part.get_payload(decode=True)
    name = re.sub(r'^\d+px-', '', unquote(Path(urlsplit(location).path).name))
    image_bytes[name] = data
    images[name.replace('_', ' ').lower()] = {
        'file': name, 'url': location, 'sha256': hashlib.sha256(data).hexdigest(),
        'size': list(Image.open(io.BytesIO(data)).size)}
rows = []
excluded = []
for row in normal.xpath('./tbody/tr[@data-mw-details]'):
    values = [text(c) for c in row.xpath('./td')]
    details = html.fromstring(row.get('data-mw-details'))
    record = dict(zip(headers[1:], values[1:]))
    if args.exclude_dust and 'D' in record['Input']:
        excluded.append(record['Input'])
        continue
    record['rawCells'] = values[1:]
    # This archived j.D row has an extra IAS block-advantage cell before Level.
    # Preserve it verbatim above, and record the interpretation explicitly.
    if args.character == 'queen-dizzy' and record['Input'] == 'j.D':
        record.update({'On-Block': '-7 (IAS)', 'Level': '', 'Counter Type': 'Very Small',
                       'Invuln': '', 'Proration': '80%', 'RISC Gain': '500', 'RISC Loss': '1000',
                       'tableCorrection': 'Malformed saved row has an extra -7 (IAS) cell; attack level is not specified. Raw cells retained.'})
    record['details'] = {}
    record['hitboxImages'] = []
    for tr in details.xpath('.//tr'):
        cells = tr.xpath('./td')
        if len(cells) != 2:
            continue
        label = text(cells[0]).rstrip(': ')
        if label == 'hitboxes':
            for img in cells[1].xpath('.//img'):
                src = img.get('src', '')
                name = re.sub(r'^\d+px-', '', unquote(Path(urlsplit(src).path).name))
                saved = images.get(name.replace('_', ' ').lower())
                record['hitboxImages'].append(saved or {'file': None, 'url': 'https://www.dustloop.com' + src, 'missing': True})
        elif label != 'images':
            record['details'][label] = text(cells[1])
    rows.append(record)
used_images = {asset['file'] for row in rows for asset in row['hitboxImages'] if asset.get('file')}
for name in used_images:
    (outdir / name).write_bytes(image_bytes[name])
result = {'sourceFile': args.archive.name, 'sha256': hashlib.sha256(raw).hexdigest(),
          'url': str(message.get('Snapshot-Content-Location', '')), 'savedAt': str(message.get('Date', '')),
          'scope': 'Saved normal table and embedded diagrams. Thumbnail diagrams do not include numerical engine coordinates or exact per-frame changes.',
          'moves': rows}
if excluded:
    result['excludedInputs'] = excluded
    result['scope'] += ' D attacks are excluded by request; special, super and universal-action tables are not extracted.'
dest = outdir / 'source.json'
dest.write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
print(f'{dest.relative_to(ROOT)}: {len(rows)} normal rows, {len(used_images)} referenced embedded hitbox diagrams')
