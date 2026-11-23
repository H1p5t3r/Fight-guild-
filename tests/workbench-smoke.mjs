import {STEP_DRIVE_DEFAULTS} from '../web/step-drive.mjs';
import {LINE_DEFAULTS} from '../web/line-drive.mjs';
import {comboMoveDefaults} from '../web/combo-rules.mjs';
import {legacyPack} from './legacy-data.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Workshop,blockAdvantage,inputName} from '../web/workbench/model.mjs';
import {CombatPreview} from '../web/workbench/simulation.mjs';
const json=async p=>JSON.parse(await readFile(p,'utf8'));
const pack=legacyPack(await json('build/workbench-pack.json'));

test('Latest Smoke upload keeps every tuning value, note and photo except four new art selectors',async()=>{
 const raw=await json('godot/data/workshop/2026-11-18-user-smoke/FightGuild-moves-2026-11-18.json');
 for(const [slot,artPose] of [[14,21],[25,22],[15,23],[16,24]])raw.characters[2].moves[slot].artPose=artPose;
 const archived=await json('godot/data/workshop/2026-11-18-user-smoke/FightGuild-Smoke-Animations.json');
 assert.deepEqual(archived,raw);
 // This is the historical sprite pass. Current tuning lineage is checked by
 // workbench-slash-sweep, including preserved notes/photos and the changed 2S.
 const w=new Workshop(pack,raw);
 assert.deepEqual(new Workshop(pack,JSON.parse(w.export())).data,w.data);
 const art=pack.art[2];
 assert.deepEqual(art.projectile_variants['14'],art.projectile_variants['25']);
 assert.equal(art.attack_animation.frames.length,69);
 assert.equal(inputName(w.move(2,14)),'236S');assert.equal(inputName(w.move(2,25)),'236Hs');
 assert.equal(inputName(w.move(2,15)),'214S');assert.equal(inputName(w.move(2,16)),'214Hs');
});

test('Backdraft uses all eight keys with one hit; pillar clocks and special art follow the saved core',()=>{
 const preview=new CombatPreview(pack),data=pack.draft.data;
 for(const facing of [1,-1]){
  const backdraft=preview.record(data,2,7,{gap:60,facing});
  assert.equal(backdraft.contacts.length,1);
  assert.deepEqual([...new Set(backdraft.frames.filter(f=>f.state.players[0].posePhase===14).map(f=>f.state.players[0].poseIndex))].sort((a,b)=>a-b),[0,1,2,3,4,5,6,7]);
  for(const slot of [14,25,15,16]){
   const r=preview.record(data,2,slot,{gap:500,facing}),m=data.characters[2].moves[slot];
   assert.ok(r.executed);assert.ok(r.frames.some(f=>f.state.players[0].posePhase===14));
   assert.ok(r.frames.some(f=>f.selectedFrame===m.startup&&f.state.players[0].posePhase===14&&
    /First-active/.test(pack.art[2].attack_animation.frames[f.state.players[0].poseIndex].motion_cue)));
   if(slot===14||slot===25){
    const projectiles=r.frames.flatMap(f=>f.state.projectiles);
    assert.ok(projectiles.length>6);
    assert.ok(projectiles.every(q=>q.age===m.projectileLife-q.life&&q.move===slot));
    assert.equal(new Set(projectiles.map(q=>q.x)).size,1);assert.equal(new Set(projectiles.map(q=>q.y)).size,1);
   }
  }
 }
});

test('Smoke source timing, independent hits and charged slots survive workshop/core round trips',()=>{
 const w=new Workshop(pack,pack.draft.data),c=w.data.characters[2];
 assert.equal(w.data.schema,27);assert.equal(c.moves.length,47);
 assert.equal(blockAdvantage(c.moves[2]),-7);assert.equal(blockAdvantage(c.moves[3]),-4);
 assert.equal(blockAdvantage(c.moves[43]),12);
 assert.equal(inputName(c.moves[32]),'c.S');assert.equal(inputName(c.moves[2]),'f.S');assert.equal(inputName(c.moves[43]),'6[Hs]');
 assert.equal(c.moves[0].damage,25);assert.equal(c.moves[7].startup,18);
 assert.equal(c.moves[2].hitboxTimeline.keys.length,5);assert.equal(c.moves[3].hitboxTimeline.keys[2].hitstun,89);
 w.change(2,11,'holdFrame',40);w.change(2,43,'enabled',0);
 assert.deepEqual(new Workshop(pack,JSON.parse(w.export())).data,w.data);
 assert.equal(pack.art[2].signature_active.frames.length,24);assert.equal(pack.art[2].projectile.file,'smoke-v1/projectile.png');
});
test('Leo corrects Tapper boxes without changing his timing, damage, stance or movement',async()=>{
 const previous=await json('godot/data/workshop/2026-11-18-tapper/FightGuild-Tapper.json');
 for(const c of previous.characters)for(const m of c.moves)Object.assign(m,LINE_DEFAULTS,comboMoveDefaults(m),STEP_DRIVE_DEFAULTS);
 for(const c of previous.characters)for(const m of c.moves)if(m.category===4&&m.motion===0)m.startup=2;
 const now=new Workshop(pack,await json('godot/data/workshop/2026-11-18-startup/FightGuild-Startup.json')).data;
 for(const c of [0,1,4,5]){
  assert.deepEqual(now.characters[c].movement,{...previous.characters[c].movement,airDashPauseFrames:4,airBackdashPauseFrames:4});
  assert.deepEqual(now.characters[c].moves.slice(0,43),previous.characters[c].moves);
 }
 const geometry=new Set(['hitboxBack','bottom','reach','height','hitboxTimeline']);
 for(let i=0;i<43;++i)for(const [key,value] of Object.entries(previous.characters[3].moves[i])){
  if(!geometry.has(key))assert.deepEqual(now.characters[3].moves[i][key],value,`Tapper/${i}/${key}`);
 }
 assert.deepEqual(now.characters[3].movement,{...previous.characters[3].movement,airDashPauseFrames:4,airBackdashPauseFrames:4});
 for(const i of [13,23,24,35,36,37,38,39,40])assert.deepEqual(now.characters[3].moves[i],previous.characters[3].moves[i]);
 const traces=await json('references/frame-data/leo-whitefang-2026-11-18/traces.json');
 assert.deepEqual(now.characters[3].moves[0].hitboxTimeline.keys[0].boxes,traces.moves['5P'][0].boxes);
 const migrated=new Workshop(pack,previous);
 for(let c=0;c<6;++c){assert.deepEqual(migrated.data.characters[c].moves.slice(0,43),previous.characters[c].moves);assert.equal(migrated.move(c,43).enabled,0);assert.equal(migrated.move(c,44).enabled,0);}
});
test('Smoke preview uses independent hit groups, charged geometry, projectile and both facings',()=>{
 const preview=new CombatPreview(pack),data=pack.draft.data;
 for(const facing of [1,-1]){
  const five=preview.record(data,2,2,{gap:130,facing});
  assert.equal(five.executed,true);assert.equal(five.contacts.length,5);
  const once=structuredClone(data);once.characters[2].moves[2].hitboxTimeline.multiHit=false;
  assert.equal(preview.record(once,2,2,{gap:130,facing}).contacts.length,1);
  const charged=preview.record(data,2,43,{gap:80,facing,behavior:'crouch'});
  assert.equal(charged.executed,true);assert.equal(charged.contacts.length,1);
  assert.ok(charged.frames.some(f=>f.state.players[1].guardBreak));
  const ember=preview.record(data,2,21,{gap:180,facing});
  assert.equal(ember.executed,true);assert.ok(ember.frames.some(f=>f.state.projectiles.length));
  assert.ok(ember.frames.some(f=>f.state.players[0].vx*facing<0));
 }
});
