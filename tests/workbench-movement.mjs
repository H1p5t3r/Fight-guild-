import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Engine,FIELDS,MOVEMENT_FIELDS} from '../web/engine.mjs';
import {Workshop} from '../web/workbench/model.mjs';
import {CombatPreview} from '../web/workbench/simulation.mjs';
const pack=JSON.parse(await readFile(new URL('../build/workbench-pack.json',import.meta.url),'utf8'));
test('Schema-14 drafts retain movement, hitbox and art edits while adding new controls',()=>{
 const old=structuredClone(pack.defaults);old.schema=old.coreVersion=14;
 for(const c of old.characters){for(const key of MOVEMENT_FIELDS.slice(9))delete c.movement[key];for(const m of c.moves)for(const key of FIELDS.slice(69))delete m[key];}
 old.characters[5].movement.walkSpeed=321;old.characters[5].moves[0].damage=91;old._moveWorkshop={version:1,notes:{'Fillet/5P':{active:'Keep my pose.'}}};
 const w=new Workshop(pack,old);assert.equal(w.data.schema,19);assert.equal(w.data.characters[5].movement.walkSpeed,321);assert.equal(w.move(5,0).damage,91);assert.equal(w.note(5,0).active,'Keep my pose.');
 w.changeMovement(5,'airDashEnabled',1);w.changeMovement(5,'forwardStyle',3);w.change(5,0,'projectileKind',2);w.change(5,0,'smearFrame1',8);
 const imported=new Workshop(pack,JSON.parse(w.export()));assert.deepEqual(imported.data,w.data);w.undo();assert.equal(w.move(5,0).smearFrame1,0);w.undo();w.undo();assert.equal(w.data.characters[5].movement.forwardStyle,0);
});
test('The same preview records walk/run, 44, teleports, air actions and FD from editable profiles',()=>{
 const preview=new CombatPreview(pack),data=structuredClone(pack.defaults),profile=data.characters[5].movement;
 const walk=preview.recordMovement(data,5,0,'walk'),run=preview.recordMovement(data,5,0,'forward');
 assert.ok(walk.frames.some(f=>f.state.players[0].posePhase===6));assert.ok(run.frames.some(f=>f.state.players[0].posePhase===7));assert.ok(run.displacement>walk.displacement);
 const back=preview.recordMovement(data,5,0,'back');assert.ok(back.frames.some(f=>f.state.players[0].dashTicks>0&&f.state.players[0].vx<0));
 profile.forwardStyle=3;const teleport=preview.recordMovement(data,5,0,'forward');assert.equal(teleport.frames.filter(f=>f.state.players[0].teleported).length,1);
 profile.airDashEnabled=1;const air=preview.recordMovement(data,5,0,'airForward');assert.ok(air.frames.some(f=>f.state.players[0].airDashUsed===1));assert.equal(air.frames.at(-1).state.players[0].airDashUsed,0);
 const fd=preview.recordMovement(data,5,0,'fd');assert.ok(fd.frames.some(f=>f.state.players[0].faultless));assert.ok(fd.contacts.some(c=>c.event===2));
});
test('Moving shots and traps show real independent contact and persistent geometry',()=>{
 const preview=new CombatPreview(pack),data=structuredClone(pack.defaults),m=data.characters[5].moves[0];
 Object.assign(m,{projectileKind:1,projectileSpeedX:800,projectileOffsetX:3000,projectileWidth:3000,projectileHeight:6000,projectileLife:180});
 const shot=preview.record(data,5,0,{gap:200});assert.ok(shot.contacts.length);assert.ok(shot.frames.some(f=>f.state.players[0].move<0&&f.state.projectiles.length));
 Object.assign(m,{projectileKind:2,projectileOffsetX:15000,projectileHits:3,projectileRehit:10,hitstun:30,pushback:0,hitstop:0,launch:0});
 const trap=preview.record(data,5,0,{gap:100});assert.equal(trap.contacts.length,3);const x=trap.frames.flatMap(f=>f.state.projectiles.map(q=>q.x));assert.equal(new Set(x).size,1);
});
test('Retired smear settings round-trip without affecting poses, contacts or timing',()=>{
 const preview=new CombatPreview(pack),baseline=preview.record(pack.defaults,5,0),w=new Workshop(pack);
 Object.assign(w.data.characters[5].movement,{smearMode:1,smearPart:2,smearStretch:400});
 Object.assign(w.move(5,0),{smearMode:2,smearPart:3,smearStretch:400,smearFrame1:3});
 assert.equal(w.changed(5,0),false);
 const restored=new Workshop(pack,JSON.parse(w.export()));assert.deepEqual(restored.data,w.data);
 const record=preview.record(restored.data,5,0);
 assert.deepEqual(record.frames,baseline.frames);assert.deepEqual(record.contacts,baseline.contacts);
});
test('Native WASM and plain-JS projectiles produce the same state through rollback',async()=>{
 const data=structuredClone(pack.defaults);data.characters[5].moves[0].projectileKind=1;data.characters[5].movement.airDashEnabled=1;
 const wasm=new Engine((await WebAssembly.instantiate(await readFile(new URL('../web/generated/fight.wasm',import.meta.url)))).instance),plain=new CombatPreview(pack).engine;
 for(const e of [wasm,plain]){e.loadData(data);e.reset();e.api.fg_preview_begin(0,0);}
 for(let i=0;i<90;i++){const a=i===35?8:i===50?512:0;wasm.step(a,0);plain.step(a,0);assert.equal(wasm.hash,plain.hash);}
 const snapshot=plain.snapshot();for(let i=0;i<30;i++)plain.step(0,0);const hash=plain.hash;plain.restore(snapshot);for(let i=0;i<30;i++)plain.step(0,0);assert.equal(plain.hash,hash);
});
