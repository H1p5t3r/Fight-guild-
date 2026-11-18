import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Engine,INPUT} from '../web/engine.mjs';
import {upgradeStartupRules} from '../web/startup-rules.mjs';
const module=await WebAssembly.compile(await readFile('web/generated/fight.wasm'));
const create=async()=>new Engine(await WebAssembly.instantiate(module));

test('Standard throws connect on frame 2; P normals support 3f/4f; other attacks retain 5f',async()=>{
  const e=await create();
  for(let c=0;c<6;++c)for(const m of e.data().characters[c].moves){
    if(m.category===4&&!m.motion)assert.equal(m.startup,2,`${c}/${m.id}`);
  }
  for(const air of [false,true])for(const facing of [1,-1])for(const slot of air?[41,42]:[23,24]){
    e.reset([3,4]);e.api.fg_preview_place(0,facing===1?45000:51000,air?10000:0,0);e.api.fg_preview_place(1,facing===1?51000:45000,air?10000:0,0);e.step(0,0);
    e.api.fg_preview_begin(0,slot);
    e.step(0,0);assert.equal(e.state().players[1].health,1000);
    const snapshot=e.snapshot();e.step(0,0);
    assert.ok(e.state().players[1].health<1000||e.state().players[1].reaction===6,`${air}/${facing}/${slot} missed frame 2`);
    const hash=e.hash;e.restore(snapshot);e.step(0,0);assert.equal(e.hash,hash);
  }
  for(const startup of [3,4]){
    e.setMove(5,0,'startup',startup);e.reset([5,4]);e.api.fg_preview_place(0,45000,0,0);e.api.fg_preview_place(1,51000,0,0);
    for(let tick=1;tick<=startup;tick++){
      e.step(tick===1?INPUT.P:0,0);
      assert.equal(e.state().players[1].health<1000,tick===startup);
    }
  }
  assert.throws(()=>e.setMove(5,0,'startup',2));
  assert.throws(()=>e.setMove(5,0,'button',1)); // Cannot disguise a 4f P as a kick.
  for(const slot of [1,2,13,14,22])assert.throws(()=>e.setMove(5,slot,'startup',4));
  e.setMove(3,40,'startup',2);assert.throws(()=>e.setMove(3,40,'startup',1));
  e.setMove(5,13,'variantStartup',2);assert.throws(()=>e.setMove(5,13,'mechanic',1));
  assert.throws(()=>e.setMove(4,13,'variantStartup',4));
});

test('Schema 19 migration changes only standard throws and preserves notes; current edits round trip atomically',async()=>{
  const e=await create(),legacy=e.data();legacy.schema=legacy.coreVersion=19;
  legacy._moveWorkshop={version:1,notes:{'Fillet/4P+K':{active:'Keep this collar pose.'}}};
  legacy.futureMetadata={keep:true};
  for(const c of legacy.characters)for(const m of c.moves)if(m.category===4&&!m.motion)m.startup=9;
  const before=structuredClone(legacy),next=upgradeStartupRules(legacy),expected=structuredClone(legacy);
  expected.schema=expected.coreVersion=20;
  for(const c of expected.characters)for(const m of c.moves)if(m.category===4&&!m.motion)m.startup=2;
  assert.deepEqual(next,expected);assert.deepEqual(legacy,before);
  e.loadData(legacy);assert.equal(e.move(5,24).startup,2);
  assert.equal(e.move(3,40).startup,before.characters[3].moves[40].startup);
  const tuned=e.data();tuned.characters[5].moves[24].startup=7;
  // Whole-data imports may reclassify a fast throw or a fast cash-out safely.
  tuned.characters[5].moves[23].category=0;tuned.characters[5].moves[23].button=0;tuned.characters[5].moves[23].startup=3;
  e.setMove(5,13,'variantStartup',2);tuned.characters[5].moves[13].mechanic=1;
  e.loadData(tuned);assert.deepEqual(e.data(),tuned);
  const invalid=structuredClone(tuned);invalid.characters[5].moves[23].button=1;
  assert.throws(()=>e.loadData(invalid));assert.deepEqual(e.data(),tuned);
});
