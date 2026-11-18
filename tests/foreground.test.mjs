import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Engine,INPUT} from '../web/engine.mjs';
import {upgradeStartupRules} from '../web/startup-rules.mjs';
const module=await WebAssembly.compile(await readFile('web/generated/fight.wasm'));
const ticks=(e,n,a=0,b=0)=>{while(n-->0)e.step(a,b);};
async function setup(){
  const e=new Engine(await WebAssembly.instantiate(module)),data=e.data();
  for(const c of [4,5])Object.assign(data.characters[c].moves[0],{
    startup:3,active:1,recovery:3,hitstun:6,blockstun:6,hitstop:2,damage:1,
    reach:50000,hitboxBack:0,bottom:0,height:50000,pushback:0,airPushback:0,blockPushback:0,
    counterFreezeFrames:2,counterSlowFrames:0,counterHitstun:0
  });
  e.loadData(data);e.reset([5,4]);place(e);return e;
}
function place(e){e.api.fg_preview_place(0,45000,0,0);e.api.fg_preview_place(1,51000,0,0);}
function strike(e,p,block=false){assert.ok(e.api.fg_preview_begin(p,0));ticks(e,3,block&&p===1?INPUT.left:0,block&&p===0?INPUT.right:0);}

test('Latest confirmed attacker stays in front through whiffs, hitstop and recovery; rollback restores it',async()=>{
  const e=await setup();assert.equal(e.state().foregroundPlayer,-1);
  strike(e,0);assert.equal(e.state().foregroundPlayer,0);ticks(e,50);assert.equal(e.state().foregroundPlayer,0);
  e.api.fg_preview_place(0,10000,0,0);e.api.fg_preview_place(1,90000,0,0);
  strike(e,1);assert.equal(e.state().foregroundPlayer,0,'Whiff must not steal the foreground');ticks(e,30);place(e);
  const snapshot=e.snapshot();strike(e,1,true);
  assert.equal(e.state().players[0].guarding,1);assert.equal(e.state().foregroundPlayer,1);
  const hash=e.hash;e.restore(snapshot);assert.equal(e.state().foregroundPlayer,0);
  strike(e,1,true);assert.equal(e.hash,hash);e.reset([5,4]);assert.equal(e.state().foregroundPlayer,-1);
});

test('Throws, capture starts and projectile hits select the attacker; projectile clashes do not',async()=>{
  const e=await setup();e.api.fg_preview_begin(0,24);ticks(e,2);
  assert.ok(e.state().players[1].health<1000);assert.equal(e.state().foregroundPlayer,0);
  e.reset([3,4]);place(e);e.api.fg_preview_begin(0,13);
  for(let i=0;i<40&&e.state().players[1].reaction!==6;i++)e.step(0,0);
  assert.equal(e.state().players[1].reaction,6);assert.equal(e.state().foregroundPlayer,0);
  const data=e.data();for(const c of [4,5])Object.assign(data.characters[c].moves[0],{
    projectileKind:1,projectileSpawnFrame:3,projectileSpeedX:800,projectileOffsetX:0,projectileOffsetY:7000,
    projectileWidth:8000,projectileHeight:16000,projectileLife:60,projectileHits:1,projectileDurability:1,projectileMelee:0
  });
  e.loadData(data);e.reset([5,4]);place(e);strike(e,0);ticks(e,15);
  assert.ok(e.state().players[1].health<1000);assert.equal(e.state().foregroundPlayer,0);
  e.reset([5,4]);place(e);e.api.fg_preview_begin(0,0);e.api.fg_preview_begin(1,0);ticks(e,15);
  assert.deepEqual(e.state().players.map(f=>f.health),[1000,1000]);assert.equal(e.state().foregroundPlayer,-1);
});

test('Simultaneous trades have a deterministic final contact order',async()=>{
  const e=await setup();e.api.fg_preview_begin(0,0);e.api.fg_preview_begin(1,0);ticks(e,2);
  const snapshot=e.snapshot();e.step(0,0);
  assert.ok(e.state().players.every(f=>f.health<1000));assert.equal(e.state().foregroundPlayer,1);
  const hash=e.hash;e.restore(snapshot);e.step(0,0);assert.equal(e.hash,hash);
});

test('Version 20 drafts retain every authored value and art note when upgrading presentation state',async()=>{
  const e=await setup(),old=e.data();old.schema=old.coreVersion=20;
  old.characters[5].moves[24].startup=7;
  old._moveWorkshop={version:1,notes:{'Fillet/6P+K':{active:'Keep this pose.'}}};
  const expected=structuredClone(old);expected.schema=expected.coreVersion=21;
  assert.deepEqual(upgradeStartupRules(old),expected);assert.equal(old.schema,20);
  e.loadData(old);assert.equal(e.move(5,24).startup,7);assert.equal(e.data().schema,21);
});
