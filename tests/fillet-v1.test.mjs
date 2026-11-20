import {comboMoveDefaults} from '../web/combo-rules.mjs';
import {LINE_DEFAULTS} from '../web/line-drive.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,mkdirSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {gzipSync} from 'node:zlib';
import {Engine,FIELDS,INPUT} from '../web/engine.mjs';
import {packExtension,unpackExtension} from '../web/extensions.mjs';
const spec=JSON.parse(readFileSync('art/characters/fillet-v1/FILLET_SPEC.json'));
const wasm=await WebAssembly.compile(readFileSync('web/generated/fight.wasm'));
const create=async()=>new Engine(await WebAssembly.instantiate(wasm));
const ticks=(e,n,a=0,b=0)=>{while(n--)e.step(a,b);};
test('Selected Fillet scalars, timelines, named routes and art metadata survive a v23 round trip',async()=>{
 const e=await create(),data=e.data();assert.equal(data.schema,26);assert.equal(data.characters[5].moves.length,47);
 for(const a of [...spec.actions,...spec.disabledStableSlots]){
  const m=data.characters[5].moves[a.slot];assert.equal(m.id,a.id);
  for(const key of FIELDS)assert.equal(m[key],(a.schema22Scalars[key]??LINE_DEFAULTS[key]??comboMoveDefaults(a.schema22Scalars)[key]),`${a.id}/${key}`);
  const {multiHit,keys}=a.hitboxTimeline;
  assert.deepEqual(m.hitboxTimeline,{multiHit,keys:keys.map(({actionFrame,...key})=>key)});
  if(a.hurtboxTimeline){assert.deepEqual(m.extensions.hurtboxes,a.hurtboxTimeline.keys);assert.deepEqual(m.extensions.art.animation,a.animation);}
 }
 e.loadData(data);assert.deepEqual(e.data(),data);
 for(const c of data.characters){if(c.extensions)assert.deepEqual(unpackExtension(packExtension(c.extensions,true),true,c.extensions.art),c.extensions);for(const m of c.moves)if(m.extensions)assert.deepEqual(unpackExtension(packExtension(m.extensions),false,m.extensions.art),m.extensions);}
});
test('Actual old workshop export retains all existing scalar edits and does not activate the new kit',async()=>{
 const e=await create(),old=JSON.parse(readFileSync('godot/data/workshop/2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json'));
 e.loadData(old);const data=e.data();
 for(let c=0;c<6;++c){assert.equal(data.characters[c].extensions,undefined);for(let i=0;i<45;++i){for(const field of FIELDS)assert.equal(data.characters[c].moves[i][field],(old.characters[c].moves[i][field]??LINE_DEFAULTS[field]??comboMoveDefaults(old.characters[c].moves[i])[field]));assert.equal(data.characters[c].moves[i].extensions,undefined);}assert.ok(data.characters[c].moves.slice(45).every(m=>!m.enabled));}
});
test('Malformed, unknown and partial extension imports are atomic',async()=>{
 const e=await create(),before=e.data(),fingerprint=e.fingerprint();
 for(const corrupt of [d=>d.characters[5].extensions.version=2,d=>d.characters[5].moves[0].extensions.unknown=1,d=>d.characters[5].moves[0].extensions.hurtboxes[0].boxes.head=[3,0,1,4],d=>d.characters[5].extensions.params.bleedInterval=0,d=>d.characters[5].moves[0].extensions.routes.normal.push(99)]){
  const bad=structuredClone(before);corrupt(bad);assert.throws(()=>e.loadData(bad));assert.equal(e.fingerprint(),fingerprint);
 }
});
test('Pair snapshots replay capture, release damage, recovery and bleed identically',async()=>{
 const e=await create();e.reset([5,4]);e.api.fg_preview_place(0,40000,0,0);e.api.fg_preview_place(1,64000,0,0);assert.equal(e.api.fg_preview_status(1,1,59),1);e.api.fg_preview_begin(0,45);ticks(e,22);
 assert.equal(e.state().pairKind,2);const saved=e.snapshot();ticks(e,65);const expected=e.hash;
 assert.equal(e.state().players[1].health,886);assert.equal(e.state().players[1].bleedTime,0);assert.equal(e.state().players[0].lastDamage,114);
 e.restore(saved);ticks(e,65);assert.equal(e.hash,expected);
});
test('Unavailable cashout motions are consumed without falling back to Wound',async()=>{
 for(const last of [INPUT.left,INPUT.right]){const e=await create();e.reset([5,4]);e.step(INPUT.down,0);e.step(INPUT.down|last,0);e.step(last|INPUT.D,0);assert.equal(e.state().players[0].move,-1);ticks(e,10);assert.equal(e.state().players[0].lastMove,-1);}
});
test('Real c.S → f.S inputs preserve pressure spacing, FD push and combo scaling in both roles/facings',async()=>{
 for(const owner of [0,1])for(const facing of [-1,1])for(const mode of ['hit','block','fd']){
  const e=await create();e.reset(owner?[4,5]:[5,4]);
  e.api.fg_preview_place(owner,50000,0,10000);e.api.fg_preview_place(1-owner,50000+facing*6200,0,10000);
  const guard=mode==='hit'?0:INPUT.down|(facing>0?INPUT.right:INPUT.left)|(mode==='fd'?INPUT.faultless:0);
  const step=raw=>e.step(owner?guard:raw,owner?raw:guard);
  step(INPUT.S);for(let i=1;i<7;i++)step(0);
  assert.equal(e.state().players[owner].contactCount,1,`${owner}/${facing}/${mode}: c.S`);
  if(mode!=='hit')assert.equal(Math.abs(e.state().players[0].x-e.state().players[1].x),mode==='fd'?8000:6800);
  while(e.state().hitstop)step(0);
  step(INPUT.S);assert.equal(e.state().players[owner].move,2);
  for(let i=0;i<12&&e.state().players[owner].contactCount<2;i++)step(0);
  assert.equal(e.state().players[owner].contactCount,2,`${owner}/${facing}/${mode}: f.S`);
  if(mode==='hit')assert.equal(e.state().players[1-owner].health,924,'44 + 32 combo damage');
  else{assert.equal(Math.abs(e.state().players[0].x-e.state().players[1].x),mode==='fd'?11000:7800);assert.equal(e.state().players[1-owner].health,1000);}
 }
});

test('Complete input-selected rekka branches reach Wound against every current receiver, mirrored, with replay traces',async()=>{
 const current=JSON.parse(readFileSync('godot/data/workshop/current.json'));
 const batch=JSON.parse(readFileSync('godot/data/workshop/'+current.file));
 const digest=path=>createHash('sha256').update(readFileSync(path)).digest('hex');
 const evidence=[JSON.stringify({type:'build',schema:23,sourceSpecSHA256:digest('art/characters/fillet-v1/FILLET_SPEC.json'),wasmSHA256:digest('web/generated/fight.wasm'),batchSHA256:current.sha256,setup:'Only initial roots/meter are placed; all actions use ordinary input samples.'})];
 for(const receiver of [0,1,2,3,4,5])for(const owner of [0,1])for(const facing of [-1,1])for(const branch of ['high','low']){
  const e=await create();e.loadData(batch);e.reset(owner?[receiver,5]:[5,receiver]);
  e.api.fg_preview_place(owner,50000,0,0);e.api.fg_preview_place(1-owner,50000+facing*6200,0,0);
  const fixture=`receiver=${receiver},owner=${owner},facing=${facing},branch=${branch}`;
  evidence.push(JSON.stringify({type:'fixture',fixture,fingerprint:e.fingerprint(),initial:e.state()}));
  const step=raw=>{
   const input=owner?[0,raw]:[raw,0];e.step(...input);
   evidence.push(JSON.stringify({type:'tick',fixture,input,state:e.state(),checksum:e.hash,geometry:[0,1].map(p=>({hurt:e.boxes(p,0),push:e.boxes(p,1),hit:e.boxes(p,2)}))}));
  };
  const forward=facing>0?INPUT.right:INPUT.left;
  step(INPUT.down);step(INPUT.down|forward);step(forward|INPUT.S);
  assert.equal(e.state().players[owner].move,15,fixture+': Opening input');
  while(!e.state().players[owner].contactCount&&e.frame<50)step(0);
  assert.equal(e.state().players[owner].contactCount,1,fixture+': Opening hits');
  while(e.state().hitstop)step(0);
  step((branch==='high'?forward:INPUT.down)|INPUT.S);
  assert.equal(e.state().players[owner].move,branch==='high'?26:27,fixture+': named branch');
  while(e.state().players[owner].move>=0&&e.frame<200)step(0);
  assert.equal(e.state().players[owner].move,-1,fixture+': branch finishes');
  assert.equal(e.state().players[owner].contactCount,2,fixture+': branch hits once');
  const before=e.state();step(INPUT.D);
  assert.equal(e.state().players[owner].move,13,fixture+': Wound input');
  const saved=e.snapshot(),replayStart=e.frame;
  while(!e.state().pairKind&&e.state().players[owner].move>=0&&e.frame<300)step(0);
  assert.equal(e.state().pairKind,3,fixture+': natural Downed capture');
  assert.equal(e.state().pairOwner,owner,fixture+': capture owner');
  while((e.state().pairKind||e.state().hitstop)&&e.frame<350)step(0);
  const released=e.state(),victim=released.players[1-owner];
  assert.equal(victim.bleedTime,420,fixture+': release starts bleed');
  assert.equal(victim.greyLife,20,fixture+': initial grey life');
  assert.equal(victim.throwGrace,5,fixture+': release grace');
  assert.equal(victim.health,before.players[1-owner].health,fixture+': Wound does no health damage');
  assert.equal((victim.x-released.players[owner].x)*facing,12000,fixture+': exact neutral gap');
  assert.deepEqual(released.players.map(p=>p.momentum),before.players.map(p=>p.momentum),fixture+': Wound earns no meter');
  const finalHash=e.hash,replayTicks=e.frame-replayStart;e.restore(saved);ticks(e,replayTicks);
  assert.equal(e.hash,finalHash,fixture+': full Wound snapshot replay');
 }
 mkdirSync('build/fillet-v1-review',{recursive:true});
 writeFileSync('build/fillet-v1-review/branch-wound-traces.jsonl.gz',gzipSync(evidence.join('\n')+'\n'));
});
