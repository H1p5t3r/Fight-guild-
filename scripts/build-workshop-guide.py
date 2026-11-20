#!/usr/bin/env python3
"""Build the searchable, bookmarked Move Workshop PDF from maintained content.

Requires reportlab and a current build/workbench-pack.json (npm run build:workshop).
Capture screenshots separately with node scripts/capture-workshop-guide.mjs.
"""
from __future__ import annotations

import json
import subprocess
from collections import Counter
from pathlib import Path
from xml.sax.saxutils import escape
from PIL import Image as RasterImage

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Flowable, Frame, Image, PageBreak,
    PageTemplate, Paragraph, Spacer, Table, TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/workshop-guide'
OUTPUT = ROOT / 'exports/FightGuild-Move-Workshop-Guide.pdf'
CONTENT = json.loads((SOURCE / 'content.json').read_text())
PACK = json.loads((ROOT / 'build/workbench-pack.json').read_text())
META = json.loads(subprocess.check_output([
    'node', '--input-type=module', '-e',
    "import {SPECS,GROUPS,ART_FIELDS} from './web/workbench/specs.mjs';"
    "console.log(JSON.stringify({specs:SPECS,groups:GROUPS,art:ART_FIELDS}));",
], cwd=ROOT, text=True))

# Fail rather than silently publish a guide missing a new/renamed field.
expected = [k for g in META['groups'] for k in g['fields']]
documented = [i['key'] for p in CONTENT['pages'] for b in p['blocks']
              if b['type'] == 'fields' for i in b['items']]
assert len(set(expected)) == len(expected) == 104
assert Counter(expected) == Counter(documented), 'Gameplay field coverage mismatch'
art_expected = [row[0] for row in META['art']]
art_documented = [i['key'] for p in CONTENT['pages'] for b in p['blocks']
                  if b['type'] == 'artfields' for i in b['items']]
assert Counter(art_expected) == Counter(art_documented), 'Art field coverage mismatch'
assert PACK['defaults']['schema'] == PACK['defaults']['coreVersion'] == CONTENT['schema']

FONT_ROOT = Path('/usr/share/fonts/truetype/open-sans')
for name, file in [('Body', 'OpenSans-Regular.ttf'), ('BodyBold', 'OpenSans-Semibold.ttf'),
                   ('BodyItalic', 'OpenSans-Italic.ttf')]:
    pdfmetrics.registerFont(TTFont(name, str(FONT_ROOT / file)))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='BodyBold', italic='BodyItalic', boldItalic='BodyBold')
pdfmetrics.registerFont(TTFont('Display', str(ROOT / 'godot/assets/fonts/DejaVuSansCondensed-BoldOblique.ttf')))

INK = colors.HexColor('#182933')
MUTED = colors.HexColor('#51636b')
GOLD = colors.HexColor('#9b6c25')
GOLD_PALE = colors.HexColor('#f7f0e3')
LINE = colors.HexColor('#d7dfe1')
PALE = colors.HexColor('#f2f6f7')
BLUE = colors.HexColor('#2b718c')
ORANGE = colors.HexColor('#b9671b')
GREEN = colors.HexColor('#50764c')
W, H = A4
MARGIN = 42
WIDTH = W - MARGIN * 2
BODY_HEIGHT = H - 124

def style(name, size=10, leading=13.5, **kw):
    return ParagraphStyle(name, fontName='Body', fontSize=size, leading=leading,
                          textColor=INK, spaceAfter=7, **kw)

STYLES = {
    'body': style('body'),
    'small': ParagraphStyle(
        'small', fontName='Body', fontSize=8.4, leading=11.5, textColor=MUTED, spaceAfter=4),
    'label': ParagraphStyle(
        'label', fontName='BodyBold', fontSize=9.6, leading=12.3, textColor=INK, spaceAfter=2),
    'title': ParagraphStyle('title', fontName='Display', fontSize=24, leading=28, textColor=INK, spaceAfter=12),
    'cover': ParagraphStyle('cover', fontName='Display', fontSize=34, leading=39, textColor=INK, spaceAfter=16),
    'intro': style('intro', 10.3, 14.5, spaceBefore=0),
    'caption': ParagraphStyle('caption', fontName='BodyItalic', fontSize=8, leading=11, textColor=MUTED, alignment=TA_CENTER, spaceAfter=9),
    'index': style('index', 9.2, 12.5),
    'code': style('code', 9.5, 15),
}

def p(text, name='body'):
    return Paragraph(escape(str(text)).replace('\n', '<br/>'), STYLES[name])

def rich(text, name='body'):
    return Paragraph(text, STYLES[name])

def make_table(rows, widths, header=False, label_column=True, small=False):
    data = []
    for n, row in enumerate(rows):
        data.append([v if isinstance(v, (Paragraph, list)) else p(v, 'label' if (header and n == 0) or (label_column and i == 0) else ('small' if small else 'body')) for i, v in enumerate(row)])
    table = Table(data, colWidths=widths, hAlign='LEFT', repeatRows=1 if header else 0)
    commands = [
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 8), ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 5), ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LINEBELOW', (0, 0), (-1, -1), 0.35, LINE),
    ]
    if header:
        commands += [('BACKGROUND', (0, 0), (-1, 0), PALE)]
    else:
        commands += [('BACKGROUND', (0, 0), (0, -1), PALE)]
    table.setStyle(TableStyle(commands))
    table.spaceAfter = 10
    return table


class Diagram(Flowable):
    def __init__(self, kind):
        super().__init__()
        self.kind = kind
        self.width = WIDTH
        self.height = {'timeline': 91, 'geometry': 151, 'rekka': 130, 'numpad': 181}[kind]

    def draw(self):
        c = self.canv
        c.setFont('Body', 9)
        if self.kind == 'timeline':
            x, y, unit = 12, 39, (WIDTH - 24) / 16
            for i in range(16):
                fill = GOLD_PALE if i < 4 else colors.HexColor('#fbe3c8') if i < 7 else PALE
                c.setFillColor(fill); c.setStrokeColor(colors.white)
                c.rect(x + i * unit, y, unit, 24, fill=1, stroke=1)
                c.setFillColor(INK); c.drawCentredString(x + (i + .5) * unit, y + 8, str(i + 1))
            c.setFillColor(MUTED)
            c.drawCentredString(x + 2 * unit, 22, 'WINDUP · 4f')
            c.drawCentredString(x + 5.5 * unit, 22, 'ACTIVE · 3f')
            c.drawCentredString(x + 11.5 * unit, 22, 'RECOVERY · 9f')
            c.setFont('BodyBold', 9); c.setFillColor(INK)
            c.drawString(12, 77, '5f startup: frame 5 is already active.')
        elif self.kind == 'geometry':
            ox, oy, s = 75, 28, 1.5
            c.setStrokeColor(LINE); c.setLineWidth(1)
            c.line(20, oy, WIDTH - 35, oy); c.line(ox, 13, ox, 137)
            c.setFillColor(INK); c.circle(ox, oy, 2, fill=1, stroke=0)
            c.setFillColor(colors.HexColor('#fbe3c8')); c.setStrokeColor(ORANGE)
            c.rect(ox + 20*s, oy + 20*s, 80*s, 45*s, fill=1, stroke=1)
            c.setFillColor(ORANGE); c.setFont('BodyBold', 9)
            c.drawCentredString(ox + 60*s, 135, 'WIDTH = FRONT − BACK = 80px')
            c.setFont('Body', 9); c.setFillColor(INK)
            c.drawString(ox + 110*s, 95, 'Front edge = 100px')
            c.drawString(ox + 110*s, 79, 'Bottom = 20px')
            c.drawString(ox + 110*s, 63, 'Height = 45px → top = 65px')
            c.drawString(20, 10, 'Root (0, 0)')
            c.drawString(ox + 20*s, 38, 'Back = 20px')
            c.setFillColor(MUTED); c.drawRightString(WIDTH - 35, 10, 'Forward →')
        elif self.kind == 'rekka':
            def box(x, y, title, subtitle, color):
                c.setFillColor(PALE); c.setStrokeColor(color); c.roundRect(x, y, 139, 43, 4, fill=1)
                c.setFillColor(INK); c.setFont('BodyBold', 11); c.drawCentredString(x+69.5, y+26, title)
                c.setFillColor(MUTED); c.setFont('Body', 8.5); c.drawCentredString(x+69.5, y+11, subtitle)
            box(4, 70, '236S', 'Upward slash', GOLD)
            box(184, 70, '6S', 'Middle stab', GOLD)
            box(364, 70, '2S', 'Low ending', ORANGE)
            c.setStrokeColor(GOLD); c.setFillColor(GOLD); c.setLineWidth(1.5)
            for a, b in [(143, 184), (323, 364)]:
                c.line(a+3, 91, b-5, 91); c.line(b-12, 96, b-5, 91); c.line(b-12, 86, b-5, 91)
            c.line(73, 70, 73, 38); c.line(73, 38, 434, 38); c.line(434, 38, 434, 65)
            c.line(429, 58, 434, 65); c.line(439, 58, 434, 65)
            c.setFillColor(MUTED); c.setFont('Body', 9); c.drawCentredString(253, 18, 'Skip the middle: 236S → 2S')
        elif self.kind == 'numpad':
            cell, ox, oy = 51, 14, 14
            labels = [('7', 'up-back'), ('8', 'up'), ('9', 'up-forward'), ('4', 'back'), ('5', 'neutral'), ('6', 'forward'), ('1', 'down-back'), ('2', 'down'), ('3', 'down-forward')]
            for i, (number, caption) in enumerate(labels):
                x = ox + (i % 3) * cell; y = oy + (2 - i//3) * cell
                c.setFillColor(GOLD_PALE if number == '5' else PALE); c.setStrokeColor(colors.white)
                c.rect(x, y, cell, cell, fill=1, stroke=1)
                c.setFillColor(INK); c.setFont('BodyBold', 18); c.drawCentredString(x+cell/2, y+26, number)
                c.setFont('Body', 6.7); c.drawCentredString(x+cell/2, y+12, caption)
            c.setFillColor(INK); c.setFont('BodyBold', 13); c.drawString(204, 139, 'Forward is toward the opponent.')
            c.setFont('Body', 10)
            for n, line in enumerate(['236: down → down-forward → forward', '214: down → down-back → back', '623: forward → down → down-forward', 'P · K · S · Hs · D are attack buttons.']):
                c.drawString(204, 110-n*22, line)


page_numbers = {page['id']: n + 1 for n, page in enumerate(CONTENT['pages'])}
field_pages = {item['key']: (page['id'], page_numbers[page['id']])
               for page in CONTENT['pages'] for block in page['blocks']
               if block['type'] == 'fields' for item in block['items']}

def range_label(key):
    spec = META['specs'][key]
    if spec['type'] == 'flag':
        return 'Checkbox · on / off'
    if spec['type'] == 'number':
        bounds = PACK['limits']['moves'][5][key]
        lo, hi = bounds['min'] / spec['scale'], bounds['max'] / spec['scale']
        # UI suffix inference misses some durations; use their actual units here.
        unit = spec['unit']
        if key in ('recovery', 'active', 'knockdownFrames', 'wakeupFrames', 'landingRecovery'):
            unit = 'f'
        return f'{lo:g}–{hi:g} {unit}'.strip().replace('--', '−')
    return 'See description'

def blocks(page):
    out = [p(page['title'], 'cover' if page['id'] == 'cover' else 'title')]
    if page.get('intro'):
        out.append(p(page['intro'], 'intro'))
    for block in page['blocks']:
        kind = block['type']
        if kind in ('text', 'formula'):
            out.append(p(block['text'], 'code' if kind == 'formula' else 'body'))
        elif kind == 'callout':
            box = Table([[ [p(block['title'], 'label'), p(block['text'])] ]], colWidths=[WIDTH])
            box.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, -1), GOLD_PALE),
                ('LINEBEFORE', (0, 0), (0, -1), 2.5, GOLD),
                ('LEFTPADDING', (0, 0), (-1, -1), 12), ('RIGHTPADDING', (0, 0), (-1, -1), 12),
                ('TOPPADDING', (0, 0), (-1, -1), 9), ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
            ])); box.spaceAfter = 10; out.append(box)
        elif kind in ('fields', 'controls', 'artfields'):
            rows=[]
            for item in block['items']:
                if kind == 'fields':
                    label = META['specs'][item['key']]['label']
                    left = [p(label, 'label'), p(item.get('range', range_label(item['key'])), 'small')]
                elif kind == 'artfields':
                    label = next(row[1] for row in META['art'] if row[0] == item['key'])
                    left = p(label, 'label')
                else:
                    left = p(item['label'], 'label')
                rows.append([left, p(item['text'])])
            out.append(make_table(rows, [153, WIDTH-153]))
        elif kind == 'table':
            out.append(make_table([block['headers']] + block['rows'], [153, WIDTH-153], header=True))
        elif kind == 'steps':
            out.append(make_table([[f'{i:02}', text] for i, text in enumerate(block['items'], 1)], [35, WIDTH-35]))
        elif kind == 'image':
            image_path = SOURCE / block['path']
            with RasterImage.open(image_path) as raster:
                image = Image(str(image_path), width=block['width'], height=raster.height / raster.width * block['width'])
            out += [image, Spacer(1, 6), p(block['caption'], 'caption')]
        elif kind == 'diagram':
            out += [Diagram(block['kind']), Spacer(1, 6)]
        elif kind == 'contents':
            rows=[]
            for item in [page for page in CONTENT['pages'] if page['id'] != 'cover' and not page['id'].startswith('contents')][block.get('start',0):block.get('start',0)+block.get('count',100)]:
                number=page_numbers[item['id']]
                rows.append([rich(f'<link href="#{item["id"]}" color="#182933">{escape(item["title"])}</link>', 'index'), p(str(number), 'index')])
            table=make_table(rows, [WIDTH-38, 38], label_column=False)
            table.setStyle(TableStyle([('TOPPADDING',(0,0),(-1,-1),3),('BOTTOMPADDING',(0,0),(-1,-1),3),('ALIGN',(-1,0),(-1,-1),'RIGHT')]))
            out.append(table)
        elif kind == 'index':
            rows=[['Exact editor label', 'Where to find it / page']]
            for key in sorted(expected, key=lambda k:META['specs'][k]['label'].lower()):
                label=META['specs'][key]['label']
                if block['start'] <= label[0].upper() <= block['end']:
                    dest,number=field_pages[key]
                    source=CONTENT['pages'][number-1]
                    rows.append([rich(f'<link href="#{dest}" color="#182933">{escape(label)}</link>', 'index'),
                                 p(f'{source["title"]} · {number}', 'small')])
            table=make_table(rows,[220,WIDTH-220],header=True,label_column=False)
            table.setStyle(TableStyle([('TOPPADDING',(0,0),(-1,-1),2),('BOTTOMPADDING',(0,0),(-1,-1),2)]))
            out.append(table)
            out.append(p(f"Workspace: pp. {page_numbers['navigation']}–{page_numbers['combat-preview']}. Hitbox keys: pp. {page_numbers['hit-keys']}–{page_numbers['hit-key-boxes']}. Hurtboxes: p. {page_numbers['hurtboxes']}. Art: p. {page_numbers['art']}. Photos: p. {page_numbers['photos']}. Files: p. {page_numbers['save']}.", 'small'))
        else:
            raise ValueError(kind)
    return out


class Guide(BaseDocTemplate):
    def __init__(self, path):
        super().__init__(str(path), pagesize=A4, leftMargin=MARGIN, rightMargin=MARGIN,
                         topMargin=72, bottomMargin=52, title=CONTENT['title'],
                         author='Fight Guild', subject='Complete browser Move Workshop control reference',
                         pageCompression=1)
        frame=Frame(MARGIN,52,WIDTH,BODY_HEIGHT,leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0,id='body')
        self.addPageTemplates(PageTemplate(id='page',frames=[frame],onPage=self.decorate))

    def decorate(self, canvas, doc):
        page=CONTENT['pages'][doc.page-1]
        canvas.saveState()
        canvas.setFillColor(INK); canvas.rect(0,H-49,W,49,fill=1,stroke=0)
        canvas.setFillColor(colors.HexColor('#e0ba76')); canvas.setFont('Display',11)
        canvas.drawString(MARGIN,H-29,'FIGHT GUILD / MOVE WORKSHOP')
        canvas.setFillColor(colors.white);canvas.setFont('Body',7.5)
        canvas.drawRightString(W-MARGIN,H-29,page['section'])
        canvas.setStrokeColor(LINE);canvas.line(MARGIN,38,W-MARGIN,38)
        canvas.setFillColor(MUTED);canvas.setFont('Body',7.5)
        canvas.drawString(MARGIN,25,f'CONTROL GUIDE · SCHEMA {CONTENT["schema"]} · {CONTENT["edition"]}')
        canvas.drawRightString(W-MARGIN,25,f'{doc.page:02} / {len(CONTENT["pages"]):02}')
        canvas.bookmarkPage(page['id'])
        canvas.addOutlineEntry(page['title'].replace('\n',' '),page['id'],level=0)
        canvas.restoreState()


# Each chapter has an intentional single-page layout. Preflight all flowables
# to catch overflow rather than allowing page numbers/index links to drift.
from reportlab.pdfgen.canvas import Canvas
import io
probe=Canvas(io.BytesIO(),pagesize=A4)
story=[]
layout=[]
for n,page in enumerate(CONTENT['pages']):
    flow=blocks(page)
    height=0
    for item in flow:
        _,h=item.wrapOn(probe,WIDTH,10000)
        height+=h+item.getSpaceBefore()+item.getSpaceAfter()
    layout.append({'page':n+1,'id':page['id'],'height':round(height,1),'available':round(BODY_HEIGHT,1)})
    if height>BODY_HEIGHT:
        print(f'OVERFLOW page {n+1} ({page["id"]}): {height:.1f} > {BODY_HEIGHT:.1f}')
    if n: story.append(PageBreak())
    story.extend(flow)
if any(row['height']>row['available'] for row in layout):
    raise SystemExit('Adjust overflowing pages before publishing.')

OUTPUT.parent.mkdir(exist_ok=True)
Guide(OUTPUT).build(story)
report={'output':str(OUTPUT.relative_to(ROOT)),'pages':len(CONTENT['pages']),
        'schema':CONTENT['schema'],'gameplay_fields':len(documented),'art_fields':len(art_documented),
        'field_pages':{k:v[1] for k,v in field_pages.items()},'layout':layout}
(ROOT/'build/workshop-guide-coverage.json').write_text(json.dumps(report,indent=2)+'\n')
print(f'Built {OUTPUT.relative_to(ROOT)}: {len(CONTENT["pages"])} pages; all {len(documented)} gameplay fields and {len(art_documented)} art fields documented.')
