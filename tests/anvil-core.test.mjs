// Exercise the compiled simulation directly. The website/JSON editor remains
// frozen and does not expose Anvil's new native-only controls yet.
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {Engine} from '../web/engine.mjs';
const module=await WebAssembly.compile(readFileSync('web/generated/fight.wasm'));
const ticks=(e,n,a=0,b=0)=>{for(let i=0;i<n;i++)e.step(a,b);};
test('Anvil armor carry and anti-air super replay identically in the shared WASM core',async()=>{
  const e=new Engine(await WebAssembly.instantiate(module));e.reset([0,2]);
  e.api.fg_preview_begin(0,13);ticks(e,6,256);
  assert.equal(e.api.fg_get(0,115),2);
  e.api.fg_preview_begin(0,28);
  assert.equal(e.api.fg_get(0,114),1);assert.equal(e.api.fg_get(0,115),2);
  const armor=e.snapshot();ticks(e,30);const armorHash=e.hash;
  e.restore(armor);ticks(e,30);assert.equal(e.hash,armorHash);
  e.reset([0,2]);e.api.fg_preview_place(0,35000,0,10000);e.api.fg_preview_place(1,56000,16000,0);
  e.api.fg_preview_begin(0,16);
  assert.equal(e.api.fg_get(-1,28),54);assert.equal(e.api.fg_get(0,15),3333);
  const frozen=e.snapshot();ticks(e,54);
  assert.equal(e.api.fg_get(1,1),16000);assert.equal(e.api.fg_get(0,5),0);
  ticks(e,5);assert.equal(e.api.fg_get(-1,22),7);
  ticks(e,150);assert.equal(e.api.fg_get(1,3),667);assert.equal(e.api.fg_get(0,15),3333);
  const hash=e.hash;e.restore(frozen);ticks(e,209);assert.equal(e.hash,hash);
});
