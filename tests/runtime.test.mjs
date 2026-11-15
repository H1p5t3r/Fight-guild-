import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {Engine} from '../web/engine.mjs';
import {RollbackSession,rollbackTrial} from '../web/rollback.mjs';
const module=await WebAssembly.compile(await readFile(new URL('../web/generated/fight.wasm',import.meta.url)));
const create=async()=>new Engine(await WebAssembly.instantiate(module));

test('Native C++ and WebAssembly match every frame of a 1200-frame input trace',async()=>{
  const e=await create();e.reset([0,1]);
  const trace=execFileSync(fileURLToPath(new URL('../build/core-tests',import.meta.url)),['--trace'],{encoding:'utf8'}).trim().split('\n');
  assert.equal(trace.length,1200);
  for(const row of trace){const [a,b,hash]=row.split(' ').map(Number);e.step(a,b);assert.equal(e.hash,hash,`frame ${e.frame}`);}
});
test('Snapshot restore reproduces input recognition and combat state',async()=>{
  const e=await create();e.step(4,0);e.step(6,0);const saved=e.snapshot();
  e.step(18,0);const expected=e.hash;assert.equal(e.state().players[0].move,14);
  e.step(0,512);e.restore(saved);e.step(18,0);assert.equal(e.hash,expected);
});
test('Rollback repairs delayed and out-of-order inputs to the authoritative state',async()=>{
  for(const latency of [0,1,4,8,12]) {
    const result=rollbackTrial(await create(),await create(),{frames:1200,latency,jitter:4});
    assert.equal(result.pass,true,JSON.stringify(result));
    assert.ok(result.rollbacks>0);
  }
});
test('Prediction stalls safely and resumes when missing input arrives',async()=>{
  const s=new RollbackSession(await create(),{maxPrediction:3});
  for(let f=0;f<3;++f){s.submit(0,f,2);assert.equal(s.advance(),true);}
  assert.equal(s.advance(),false);const frame=s.engine.frame;
  for(let f=0;f<3;++f)s.submit(1,f,1);
  assert.equal(s.engine.frame,frame);assert.equal(s.advance(),true);
  assert.throws(()=>s.submit(1,0,2),/changed/);
});
test('Old input outside snapshot history is rejected without corrupting state',async()=>{
  const s=new RollbackSession(await create(),{history:10});
  for(let f=0;f<30;++f){s.submit(0,f,0);s.submit(1,f,0);s.advance();}
  const hash=s.engine.hash;
  assert.throws(()=>s.submit(1,0,1),/outside/);assert.equal(s.engine.hash,hash);
});
test('Move data round-trips, fingerprints change, and invalid imports are atomic',async()=>{
  const e=await create(),original=e.data(),hash=e.fingerprint();
  const data=structuredClone(original);data.characters[0].moves[0].damage=177;e.loadData(data);
  assert.equal(e.move(0,0).damage,177);assert.notEqual(e.fingerprint(),hash);
  const peer=await create();peer.loadData(JSON.parse(JSON.stringify(e.data())));assert.equal(peer.fingerprint(),e.fingerprint());
  const invalid=structuredClone(original);invalid.characters[1].moves[21].startup=0;
  assert.throws(()=>e.loadData(invalid),/startup/);assert.equal(e.move(0,0).damage,177);
  assert.equal(e.fingerprint(),peer.fingerprint());
  e.loadData(original);assert.equal(e.fingerprint(),hash);
});
test('Five-frame floor, schema-4 migration and compiled collision API agree',async()=>{
  const e=await create(),original=e.data();e.reset([0,1]);
  for(let startup=0;startup<5;++startup) {
    assert.throws(()=>e.setMove(0,0,'startup',startup),/startup/);
    assert.equal(e.move(0,0).startup,original.characters[0].moves[0].startup);
  }
  const legacy=structuredClone(original);legacy.schema=legacy.coreVersion=4;
  legacy.characters[0].moves[0].counterHitstun=19;
  for(const character of legacy.characters) { character.moves.length=22; for(const move of character.moves) delete move.hitboxBack; }
  e.loadData(legacy);
  assert.equal(e.move(0,0).counterHitstun,19);assert.equal(e.move(0,0).hitboxBack,1200);
  e.loadData(original);
  assert.ok(e.fingerprint().includes((e.api.fg_collision_hash()>>>0).toString(16)));
  assert.equal(e.boxes(0,1).length,1);assert.equal(e.boxes(0,0).length,3);
  for(let tick=1;tick<=e.move(0,0).startup;++tick) {
    e.step(16,0);
    assert.ok([3,4].includes(e.boxes(0,0).length));
    assert.equal(e.boxes(0,2).length,tick===e.move(0,0).startup?1:0);
  }
  assert.equal(e.state().players[0].poseIndex,1);
});

test('Signature moves, movement profiles and schema-6 migration survive the WASM adapter',async()=>{
  const e=await create(),original=e.data(),legacy=structuredClone(original);
  legacy.schema=legacy.coreVersion=6;
  for(const character of legacy.characters) {
    character.moves.length=25;delete character.movement;
    for(const move of character.moves) for(const key of ['enabled','artPose','followFrom','followFrom2','followHit','travelSpeed','inertiaPercent','pullFrames','pullGap','hitAngle']) delete move[key];
  }
  legacy.characters[5].moves[15].damage=137;e.loadData(legacy);
  assert.equal(e.move(5,15).damage,137);assert.equal(e.move(4,28).motion,214);
  assert.equal(e.data().characters[4].movement.forwardStyle,0);
  const changed=e.data();changed.characters[4].movement.runSpeed=1300;e.loadData(changed);
  const fingerprint=e.fingerprint();changed.characters[4].movement.runSpeed=-1;
  assert.throws(()=>e.loadData(changed),/movement/);assert.equal(e.fingerprint(),fingerprint);
  e.loadData(original);e.reset([4,5]);let followed=false,sawPull=false,sawCombo=false,saved;
  const inputs=[];
  for(let frame=0;frame<110;++frame) {
    let input=frame===0?4:frame===1?5:frame===2?65:0, other=frame===12?8:0;
    if(e.state().players[0].contact&&!e.state().hitstop&&!followed) {input=16;followed=true;}
    if(frame===25) saved=e.snapshot();
    inputs.push([input,other]);e.step(input,other);
    sawPull ||= e.state().players[1].reaction===5;sawCombo ||= e.state().players[0].combo===2;
  }
  assert.ok(sawPull&&sawCombo);assert.equal(e.state().players[1].health,948);
  const expected=e.hash;e.restore(saved);for(const input of inputs.slice(25)) e.step(...input);
  assert.equal(e.hash,expected);
});
