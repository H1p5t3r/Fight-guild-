import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Workshop,blockAdvantage} from '../web/workbench/model.mjs';
import {CombatPreview} from '../web/workbench/simulation.mjs';
const json=async p=>JSON.parse(await readFile(p,'utf8'));
const pack=await json('build/workbench-pack.json');
const slots=[0,1,32,2,3,4,5,6,7,17,18,19,20,8,9,11];

test('Shark batch changes only the16 selected normals and appends briefs without losing uploaded data',async()=>{
 const before=await json('godot/data/workshop/2026-11-18-user-smoke/FightGuild-Smoke-Animations.json');
 const data=pack.draft.data;
 for(let c=0;c<6;++c){
  if(c!==4){assert.deepEqual(data.characters[c],before.characters[c]);continue;}
  assert.deepEqual(data.characters[c].movement,before.characters[c].movement);
  for(let m=0;m<45;++m)if(!slots.includes(m))assert.deepEqual(data.characters[c].moves[m],before.characters[c].moves[m],String(m));
 }
 for(const [k,v] of Object.entries(before).filter(([k])=>!['characters','_moveWorkshop'].includes(k)))assert.deepEqual(data[k],v);
 for(const [name,note] of Object.entries(before._moveWorkshop.notes)){
  const now=data._moveWorkshop.notes[name];
  for(const [key,value] of Object.entries(note)){
   if(name.startsWith('Shark/')&&key==='intent'&&now[key]!==value)assert.ok(now[key].startsWith(value));
   else assert.deepEqual(now[key],value,name+'/'+key);
  }
 }
 const w=new Workshop(pack,data);assert.deepEqual(new Workshop(pack,JSON.parse(w.export())).data,w.data);
});

test('Ky timing and scaled traces survive editor import/export; multi-hit is2Hs only',async()=>{
 const w=new Workshop(pack,pack.draft.data),source=await json('references/frame-data/ky-kiske-2026-11-18/source.json');
 const traces=await json('references/frame-data/ky-kiske-2026-11-18/traces.json');
 source.moves.forEach((r,i)=>{
  const m=w.move(4,slots[i]);assert.equal(m.startup,Number(r.Startup));assert.equal(m.recovery,Number(r.Recovery));
  assert.equal(m.active,r.Input==='2H'?5:Number(r.Active));assert.equal(m.artPose,i+5);
  assert.equal(m.hitLevel,{All:0,Low:1,High:2}[r.Guard]);assert.equal(m.specialCancel,1);
  assert.deepEqual(m.hitboxTimeline.keys.map(k=>k.boxes),traces.moves[r.Input].map(t=>t.boxes));
  assert.equal(m.hitboxTimeline.multiHit,r.Input==='2H');
  assert.equal(m.counterFreezeFrames,r['Counter Type'].startsWith('Large')?31:r['Counter Type']==='Mid'?21:-1);
  assert.equal(m.counterSlowFrames,r['Counter Type'].startsWith('Large')?35:r['Counter Type']==='Mid'?25:0);
  if(!r.Input.startsWith('j.'))assert.equal(blockAdvantage(m),Number(r['On-Block']));
 });
 assert.deepEqual(w.move(4,7).hitboxTimeline.keys.map(k=>[k.frame,k.hit,k.damage]),[[1,1,14],[2,2,40]]);
 assert.equal(w.move(4,8).hurtMaskWindup,3);assert.equal(w.move(4,8).hurtWindowStart,4);
 assert.equal(w.move(4,8).hurtWindowEnd,13);assert.equal(w.move(4,8).hurtWindowMask,1);
 const art=pack.art[4];assert.equal(art.signature_active.frames.length,20);assert.equal(art.attack_animation.frames.length,26);
});

test('Low Scoop follows8 saved-clock keys, hits twice and supports the one-hit toggle in both facings',()=>{
 const p=new CombatPreview(pack),data=pack.draft.data;
 for(const facing of [1,-1]){
  const clip=p.record(data,4,7,{gap:70,facing});
  assert.ok(clip.executed);assert.equal(clip.contacts.length,2);
  const keys=[...new Set(clip.frames.filter(f=>f.state.players[0].posePhase===14).map(f=>f.state.players[0].poseIndex))].sort((a,b)=>a-b);
  assert.deepEqual(keys,[0,1,2,3,4,5,6,7]);
  assert.deepEqual(p.record(data,4,7,{gap:70,facing}),clip,'Deterministic saved frames');
  const once=structuredClone(data);once.characters[4].moves[7].hitboxTimeline.multiHit=false;
  assert.equal(p.record(once,4,7,{gap:70,facing}).contacts.length,1);
  const air=p.record(data,4,20,{gap:70,facing});
  assert.ok(air.frames.some(f=>f.state.players[0].posePhase===14&&f.state.players[0].poseIndex===24));
 }
});
