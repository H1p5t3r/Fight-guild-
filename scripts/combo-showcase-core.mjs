// Offline recording helper. Load the native CombatModel's validated fixture;
// do not migrate or change the frozen browser editor's JSON adapter.
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
import {Engine,FIELDS,MOVEMENT_FIELDS,INPUT} from '../web/engine.mjs';
export {INPUT};
export const directory=process.env.COMBO_OUTPUT??'build/combo-showcase-current';
export const manifest=JSON.parse(readFileSync('godot/data/workshop/current.json'));
export const data=JSON.parse(readFileSync('godot/data/workshop/'+manifest.file));
export const wasm=readFileSync('web/generated/fight.wasm');
export const sha256=bytes=>createHash('sha256').update(bytes).digest('hex');
export async function createCore(){
 const e=new Engine((await WebAssembly.instantiate(wasm)).instance),a=e.api;
 assert.equal(a.fg_version(),27,'Update the offline fixture reader for a new schema');
 const bytes=readFileSync(`${directory}/configuration.bin`),values=Array.from({length:bytes.length/4},(_,i)=>bytes.readInt32LE(i*4));let at=0;
 const take=n=>{const row=values.slice(at,at+n);at+=n;assert.equal(row.length,n);return row;};
 for(let c=0;c<6;c++)for(let m=0;m<47;m++){
  a.fg_move_set(c,m,FIELDS.indexOf('startup'),120);a.fg_move_set(c,m,FIELDS.indexOf('variantStartup'),120);
  for(const [f,v]of take(FIELDS.length).entries())assert.equal(a.fg_move_set(c,m,f,v),1,`Move ${c}/${m}/${f}`);
 }
 for(let c=0;c<6;c++)for(const [f,v]of take(MOVEMENT_FIELDS.length).entries())assert.equal(a.fg_mobility_set(c,f,v),1);
 for(let c=0;c<6;c++)for(let m=0;m<47;m++)for(let p=0;p<3;p++)assert.equal(a.fg_hurt_set(c,m,p,...take(17)),1);
 for(let c=0;c<6;c++)for(let m=0;m<47;m++){
  const [multi,count]=take(2);assert.equal(a.fg_hit_clear(c,m,multi),1);
  for(let k=0;k<32;k++){const key=take(23);if(k<count)assert.equal(a.fg_hit_add(c,m,...key),1);}
 }
 for(let c=0;c<6;c++)for(let m=-1;m<47;m++){
  const row=take(m<0?947:714);new Int32Array(a.memory.buffer,a.fg_extension_buffer(),row.length).set(row);
  assert.equal(a.fg_extension_commit(c,m),1,`Extension ${c}/${m}`);
 }
 for(let f=0;at<values.length;f++)assert.equal(a.fg_rule_set(f,take(1)[0]),1);
 // Compare the complete round-trip, including unused timeline slots.
 const round=[];
 for(let c=0;c<6;c++)for(let m=0;m<47;m++)for(let f=0;f<FIELDS.length;f++)round.push(a.fg_move_get(c,m,f));
 for(let c=0;c<6;c++)for(let f=0;f<MOVEMENT_FIELDS.length;f++)round.push(a.fg_mobility_get(c,f));
 for(let c=0;c<6;c++)for(let m=0;m<47;m++)for(let p=0;p<3;p++)for(let f=0;f<17;f++)round.push(a.fg_hurt_get(c,m,p,f));
 for(let c=0;c<6;c++)for(let m=0;m<47;m++)for(let f=0;f<738;f++)round.push(a.fg_hit_get(c,m,f));
 for(let c=0;c<6;c++)for(let m=-1;m<47;m++)for(let f=0;f<(m<0?947:714);f++)round.push(a.fg_extension_get(c,m,f));
 for(let f=0;round.length<values.length;f++)round.push(a.fg_rule_get(f));
 assert.deepEqual(round,values,'Offline search differs from native configuration');
 e.reset();return e;
}
export function notation(c,slot){
 const m=data.characters[c].moves[slot],button=['P','K','S','Hs','D'][m.button];
 if(slot===32)return 'c.S';if(slot===2)return 'f.S';
 if(slot===43)return '6[Hs]';if(slot===44)return '5[D]';
 if(m.actionType===9)return '[4]6Hs';
 return (m.stanceRequired===2?'st.':m.air?'j.':'')+(m.air&&!m.motion&&m.direction===5?'':m.motion||m.direction)+button;
}
