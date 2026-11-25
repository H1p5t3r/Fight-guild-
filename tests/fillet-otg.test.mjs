import {frozenBrowserData,frozenBrowserEngine} from './legacy-data.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {Engine,INPUT} from '../web/engine.mjs';

const json=path=>JSON.parse(readFileSync(path));
const manifest=json('godot/data/workshop/current.json');
const current=frozenBrowserData(json('godot/data/workshop/'+manifest.file));
const wasm=await WebAssembly.compile(readFileSync('web/generated/fight.wasm'));
const create=async()=>frozenBrowserEngine(new Engine(await WebAssembly.instantiate(wasm)));

test('OTG revision preserves every prior value and art brief except three explicit named routes',async()=>{
 const before=json('godot/data/workshop/2026-11-19-shark-v2/FightGuild-Shark-v2.json');
 const revision=json('godot/data/workshop/2026-11-20-fillet-otg/FightGuild-Fillet-OTG.json');
 const expected=structuredClone(before);
 for(const slot of [6,26,27])expected.characters[5].moves[slot].extensions.routes.special.push(13);
 expected._moveWorkshop.filletOtgRevision=revision._moveWorkshop.filletOtgRevision;
 assert.deepEqual(revision,expected);
 assert.equal(createHash('sha256').update(readFileSync('godot/data/workshop/'+manifest.file)).digest('hex'),manifest.sha256);
 const e=await create();
 for(const slot of [6,26,27])assert.deepEqual(e.data().characters[5].moves[slot].extensions.routes.special,[13]);
 e.loadData(current);const {_moveWorkshop,...gameplay}=current;assert.deepEqual(e.data(),gameplay);
 // Importing an older authored draft is never an implicit balance update.
 e.loadData(before);for(const slot of [6,26,27])assert.deepEqual(e.data().characters[5].moves[slot].extensions.routes.special,[]);
});

test('WASM performs the real sweep cancel with confirmation delay, and disabling it restores the old failed link',async()=>{
 for(const enabled of [true,false])for(const facing of [-1,1]){
  const data=structuredClone(current);if(!enabled)data.characters[5].moves[6].extensions.routes.special=[];
  const e=await create();e.loadData(data);e.reset([5,4]);e.api.fg_preview_place(0,50000,0,0);e.api.fg_preview_place(1,50000+facing*10000,0,0);
  e.step(INPUT.down|INPUT.S,0);
  while(!e.state().players[0].contactCount&&e.frame<60)e.step(0,0);
  assert.equal(e.state().players[0].contactCount,1);
  while(e.state().hitstop)e.step(0,0);
  for(let n=0;n<6;++n)e.step(0,0);
  e.step(INPUT.D,0);
  assert.equal(e.state().players[0].move,enabled?13:6);
  // Also try the old after-recovery link if this file has the route disabled.
  if(!enabled){while(e.state().players[0].move>=0)e.step(0,0);e.step(INPUT.D,0);}
  let captured=false;
  for(let n=0;n<70;++n){e.step(0,0);captured||=e.state().pairKind===3;}
  assert.equal(captured,enabled);
  assert.equal(e.state().players[1].bleedTime>0,enabled);
 }
});
