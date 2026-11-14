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
  const e=await create();
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
