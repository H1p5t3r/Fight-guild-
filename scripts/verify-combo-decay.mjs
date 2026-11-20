// Replay the exact previously filmed inputs through legacy and current rules.
// Damage after a gap is not counted as part of the opening combo.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import assert from 'node:assert/strict';
import {Engine} from '../web/engine.mjs';
const json=p=>JSON.parse(readFileSync(p));
const film=json('exports/FightGuild-Combo-Routes.json');
const current=json('godot/data/workshop/current.json');
const data=json('godot/data/workshop/'+current.file);
const old=json('godot/data/workshop/'+film.source.file);
const wasm=await WebAssembly.compile(readFileSync('web/generated/fight.wasm'));
async function replay(clip,source,legacy){
 const e=new Engine(await WebAssembly.instantiate(wasm));e.loadData(source);
 if(legacy)e.api.fg_rule_set(38,0);
 e.reset(clip.initial.characters);
 clip.initial.positions.forEach((x,p)=>e.api.fg_preview_place(p,x,0,clip.initial.momentum));
 let contacts=0,ended=false,lastHealth=1000,hits=0,bounces=0,damage=0,endFrame=0;const events=[],hashes=[];
 let previous=e.state();const halfway=Math.floor(clip.comboEnd/2);let snapshot;
 for(let i=0;i<clip.comboEnd;i++){
  if(i===halfway)snapshot=e.snapshot();
  e.step(...clip.inputs[i]);hashes.push(e.hash);
  const s=e.state(),a=s.players[0],b=s.players[1],delta=a.contactCount-contacts;
  if(!ended&&delta>0){
   if(a.event===2||a.combo!==hits+delta){ended=true;endFrame=i+1;}
   else{hits+=delta;damage=1000-b.health;events.push({frame:i+1,move:a.lastMove,hits,damage,decay:b.comboDecay,pushPercent:b.pushPercent,launchPercent:b.launchPercent,gravity:b.gravityPercent});}
  }
  if(!ended&&previous.players[1].groundBounce>0&&!b.groundBounce&&b.y===1&&b.vy>0)bounces++;
  if(hits&&!ended&&(s.wallBreakTime||(!s.hitstop&&([2,3].includes(b.reaction)||(!b.stun&&b.reaction===0))))){ended=true;endFrame=i+1;}
  contacts=a.contactCount;lastHealth=b.health;previous=s;
 }
 e.restore(snapshot);
 for(let i=halfway;i<clip.comboEnd;i++){e.step(...clip.inputs[i]);assert.equal(e.hash,hashes[i],`${clip.id} rollback / ${i}`);}
 if(legacy){assert.equal(damage,clip.damage,clip.id+' legacy damage');assert.equal(hits,clip.hits,clip.id+' legacy hits');}
 return {damage,hits,bounces,endFrame,totalDamageIncludingLaterResets:1000-lastHealth,events};
}
const results=[];
for(const clip of film.clips){const before=await replay(clip,old,true),after=await replay(clip,data,false);results.push({id:clip.id,before,after});console.log(`${clip.id}: ${before.damage}/${before.hits}, ${before.bounces} bounces -> ${after.damage}/${after.hits}, ${after.bounces} bounces`);}
assert.ok(results.find(r=>r.id==='smoke-midscreen').after.bounces<6);
assert.ok(results.find(r=>r.id==='shark-midscreen').after.hits<12);
mkdirSync('build/combo-decay',{recursive:true});
writeFileSync('build/combo-decay/replay-comparison.json',JSON.stringify({source:current,note:'Identical recorded inputs; current results are not newly optimized routes. Rollback checked at every replayed frame.',results},null,2)+'\n');
