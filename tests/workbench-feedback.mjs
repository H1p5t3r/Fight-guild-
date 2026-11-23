import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {Engine} from '../web/engine.mjs';
import {createCombatCore} from '../web/generated/fight-core.mjs';
import {CombatAudio,soundFor} from '../web/workbench/combat-audio.mjs';
const wasm=await WebAssembly.compile(await readFile('web/generated/fight.wasm'));
const manifest=JSON.parse(await readFile('godot/data/combat_audio.json','utf8'));
test('Contact cues agree across WASM and JS including restored frames',async()=>{
 const a=new Engine({exports:createCombatCore()}),b=new Engine(await WebAssembly.instantiate(wasm));
 for(const engine of [a,b]){engine.reset([5,4]);engine.api.fg_preview_place(0,45000,0,10000);engine.api.fg_preview_place(1,53000,0,10000);}
 let seed=42,contacts=0;
 for(let frame=0;frame<1000;frame++){
  seed=(Math.imul(seed,1664525)+1013904223)>>>0;
  const inputs=frame<50?[frame===0?16:0,0]:[seed&4095,(seed>>>12)&4095],snapshot=a.snapshot();
  a.step(...inputs);b.step(...inputs);
  assert.equal(a.hash,b.hash);assert.deepEqual(a.feedbackEvents(),b.feedbackEvents());
  contacts+=a.feedbackEvents().filter(c=>c.kind>=1&&c.kind<=7).length;
  const expected=a.feedbackEvents(),hash=a.hash;a.restore(snapshot);assert.deepEqual(a.feedbackEvents(),[]);
  a.step(...inputs);assert.equal(a.hash,hash);assert.deepEqual(a.feedbackEvents(),expected);
 }
 assert.ok(contacts>0);
});
test('Audio handles every character/family and skips seek/backlog',async()=>{
 const files=new Set(JSON.parse(await readFile('godot/assets/audio/combat/manifest.json','utf8')).sounds.map(s=>s.file));
 for(let character=0;character<6;character++)for(let move=0;move<47;move++)for(let kind=1;kind<=12;kind++)assert.ok(files.has(soundFor({character,move,kind},manifest)+'.wav'));
 const audio=new CombatAudio({}),heard=[];audio.play=c=>heard.push(c);
 const record={frames:Array.from({length:50},(_,i)=>({cues:[{frame:i}]}))};
 audio.advance(record,4,6);assert.deepEqual(heard.map(c=>c.frame),[5,6]);
 audio.advance(record,6,6);audio.advance(record,6,1);assert.equal(heard.length,2);
 audio.advance(record,6,49);assert.deepEqual(heard.slice(2).map(c=>c.frame),[44,45,46,47,48,49]);
});
