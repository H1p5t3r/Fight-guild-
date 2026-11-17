#!/usr/bin/env python3
"""Package the original PNGs and their atlas metadata in an offline loop viewer."""
import base64
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
assets = ROOT / 'godot/assets/fighters'
manifest = json.loads((assets / 'manifest.json').read_text())
collision = json.loads((ROOT / 'godot/data/fighter_collision.json').read_text())
fighters = []
images = {}
for character in (5, 4):
    source = manifest['fighters'][character]
    fighter = {'name': source['name'], 'poses': {}, 'hurt': {}}
    for phase in ('ready', 'walk', 'run'):
        sheet = source[phase]
        fighter['poses'][phase] = sheet
        fighter['hurt'][phase] = collision['fighters'][character]['poses'][phase]
        images[sheet['file']] = 'data:image/png;base64,' + base64.b64encode((assets / sheet['file']).read_bytes()).decode()
    fighters.append(fighter)

html = r'''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Fight Guild · Movement studies</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#10191f;color:#eee8dc;font:16px system-ui;padding:clamp(16px,4vw,48px)}
header,main,footer{max-width:1240px;margin:auto}small{color:#ddb778;letter-spacing:2px}h1{font-size:clamp(30px,5vw,56px);font-style:italic;margin:10px 0}p{color:#a5b6be;line-height:1.6}
.tools{display:flex;flex-wrap:wrap;align-items:center;gap:16px;padding:20px 0}button,select{font:inherit;background:#21343e;border:1px solid #5f747e;color:inherit;border-radius:4px;padding:9px 14px}button{cursor:pointer}label{display:flex;align-items:center;gap:8px}input{accent-color:#ddb778}input[type=range]{max-width:160px}button:focus-visible,input:focus-visible,select:focus-visible{outline:2px solid #ddb778;outline-offset:3px}
.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}article{border:1px solid #344650;background:#15232b;border-top:3px solid #ad535b;border-radius:5px;overflow:hidden}article+article{border-top-color:#398f9f}h2{padding:20px 22px 0;margin:0;font-style:italic}h2 span{font-size:12px;letter-spacing:1px;color:#a5b6be;margin-left:10px}canvas{display:block;width:100%;height:auto}.caption{padding:0 22px 20px;font-size:13px;color:#a5b6be}footer{margin-top:24px;font-size:13px}output{font-variant-numeric:tabular-nums;min-width:80px}@media(max-width:700px){.pair{grid-template-columns:1fr}}
</style>
<header><small>FIGHT GUILD / MOVEMENT STUDIES</small><h1>Stalker. Shoulder Rest.</h1><p>Separate eight-frame walk and run loops built from the selected combat stances.</p>
<div class="tools"><label>Movement <select id="phase"><option value="ready">Combat stance</option><option value="walk" selected>Walk</option><option value="run">Run</option></select></label><button id="play" aria-pressed="true">Pause</button><label>Speed <input id="speed" type="range" min="0.25" max="1.5" value="1" step="0.25"></label><label><input id="mirror" type="checkbox"> Face left</label><label><input id="boxes" type="checkbox"> Hurtboxes</label><label>Frame <input id="frame" type="range" min="0" max="7" step="1" value="0"></label><output id="count">1 / 8</output></div></header>
<main class="pair"><article><h2>FILLET <span>A / STALKER</span></h2><canvas width="600" height="440" aria-label="Fillet movement preview"></canvas><div class="caption">Low forward pressure · controlled knives · loaded footfalls</div></article><article><h2>SHARK <span>F / SHOULDER REST</span></h2><canvas width="600" height="440" aria-label="Shark movement preview"></canvas><div class="caption">Confident shoulder carry · blue sports glasses · narrow flowing hair</div></article></main>
<footer><p>Preview loops run in place. The game uses travelled distance to advance the same frames. Blue rectangles show the three body hurtboxes; weapons, hair and clothing trails do not extend them. This file works offline.</p></footer>
<script>const pack=__PACK__;
const $=id=>document.getElementById(id),images={},canvases=[...document.querySelectorAll('canvas')];
let playing=true,clock=0,frame=0,last=0;
Promise.all(Object.entries(pack.images).map(async([key,src])=>{const image=new Image();image.src=src;await image.decode();images[key]=image;})).then(()=>requestAnimationFrame(tick));
function draw(){const phase=$('phase').value;const index=phase==='ready'?0:frame;$('frame').disabled=phase==='ready';$('count').textContent=`${index+1} / ${phase==='ready'?1:8}`;
 pack.fighters.forEach((fighter,i)=>{const ctx=canvases[i].getContext('2d'),sheet=fighter.poses[phase],tile=sheet.frames[index],scale=150/sheet.body_height*2.05,facing=$('mirror').checked?-1:1;
 ctx.clearRect(0,0,600,440);ctx.strokeStyle='#2c3d47';ctx.lineWidth=1;for(let x=0;x<600;x+=50){ctx.beginPath();ctx.moveTo(x,45);ctx.lineTo(x,390);ctx.stroke();}ctx.strokeStyle='#82909a';ctx.beginPath();ctx.moveTo(18,390);ctx.lineTo(582,390);ctx.stroke();
 ctx.save();ctx.translate(300,390);ctx.scale(facing,1);const [x,y,w,h]=tile.region;ctx.drawImage(images[sheet.file],x,y,w,h,-tile.pivot[0]*scale,-tile.pivot[1]*scale,w*scale,h*scale);
 if($('boxes').checked){ctx.strokeStyle='#7bd5ef';ctx.fillStyle='#7bd5ef18';for(const b of Object.values(fighter.hurt[phase][index].hurt)){const x=(b[0]-tile.pivot[0])*scale,y=(b[1]-tile.pivot[1])*scale,w=(b[2]-b[0])*scale,h=(b[3]-b[1])*scale;ctx.fillRect(x,y,w,h);ctx.strokeRect(x,y,w,h);}}
 ctx.restore();ctx.fillStyle='#ddb778';ctx.fillRect(297,387,6,6);
 });}
function tick(time){const dt=Math.min(100,time-last);last=time;if(playing&&$('phase').value!=='ready'){clock+=dt*Number($('speed').value);const duration=1000/60*($('phase').value==='run'?3:5);while(clock>=duration){clock-=duration;frame=(frame+1)%8;}$('frame').value=frame;}draw();requestAnimationFrame(tick);}
$('play').onclick=()=>{playing=!playing;$('play').textContent=playing?'Pause':'Play';$('play').setAttribute('aria-pressed',String(playing));};
$('frame').oninput=()=>{frame=Number($('frame').value);playing=false;$('play').textContent='Play';$('play').setAttribute('aria-pressed','false');clock=0;};
$('phase').onchange=()=>{frame=0;clock=0;$('frame').value=0;};
</script></html>'''
output = ROOT / 'exports/FightGuild-Movement-Preview.html'
output.write_text(html.replace('__PACK__', json.dumps({'fighters': fighters, 'images': images}, separators=(',', ':'))))
print(f'{output.relative_to(ROOT)}: {output.stat().st_size / 1024 / 1024:.1f} MiB, six original PNGs, no network dependencies')
