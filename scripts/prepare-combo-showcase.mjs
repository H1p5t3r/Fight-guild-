import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
import {Engine} from '../web/engine.mjs';
const json=p=>JSON.parse(readFileSync(p));
const manifest=json('godot/data/workshop/current.json'),data=json('godot/data/workshop/'+manifest.file);
const wasm=readFileSync('web/generated/fight.wasm');
const e=new Engine((await WebAssembly.instantiate(wasm)).instance);e.loadData(data);
const out='build/combo-showcase';mkdirSync(out,{recursive:true});
const clips=[];
for(const name of ['fillet','smoke','shark'])for(const position of ['midscreen','corner']){
 const source=json(`${out}/${name}-${position}.json`),row=source.candidates[0];
 e.reset(source.initial.characters);
 for(let p=0;p<2;p++)e.api.fg_preview_place(p,source.initial.positions[p],0,source.initial.momentum);
 let contacts=0,firstHit=0,ended=false;const hashes=[],events=[];
 for(const [index,input]of row.inputs.entries()){
  assert.ok(!ended,`${source.id}: sequence continued after its combo ended`);
  e.step(...input);const s=e.state(),a=s.players[0],b=s.players[1];hashes.push(e.hash);
  const delta=a.contactCount-contacts;
  assert.ok(delta>=0,`${source.id}: contact counter reset`);
  if(delta){
   assert.notEqual(a.event,2,`${source.id}: blocked follow-up`);
   assert.equal(a.combo,contacts+delta,`${source.id}: combo reset on frame ${index+1}`);
   contacts+=delta;firstHit||=index+1;
   events.push({frame:index+1,hits:contacts,damage:1000-b.health,move:a.lastMove});
  }
  if(contacts&&(s.wallBreakTime||(!s.hitstop&&(b.reaction===2||b.reaction===3||(!b.stun&&b.reaction===0)))))ended=true;
 }
 const end=e.state();assert.equal(1000-end.players[1].health,row.damage);assert.equal(contacts,row.hits);
 const inputs=[...row.inputs],comboEnd=inputs.length;
 let bonus=null;
 if(source.id==='fillet-midscreen'&&[26,27].includes(row.route.at(-1).slot)){
  bonus={startFrame:inputs.length+1,notation:'5D',title:'OTG BLEED RESET',note:'Combo finished. Wound applies bleed; this is a reset, not another combo hit.'};
  let captured=false;
  for(let i=0;i<100;i++){
   const input=i===0?256:0;e.step(input,0);inputs.push([input,0]);hashes.push(e.hash);
   const state=e.state();captured||=state.pairKind===3;
   if(state.players[1].bleedTime>0){assert.ok(captured);break;}
  }
  assert.ok(captured&&e.state().players[1].bleedTime>0,'Fillet follow-up must apply real OTG bleed');
  assert.equal(1000-e.state().players[1].health,row.damage,'Bleed setup adds no combo damage');
  bonus.endFrame=inputs.length;
 }
 // Finish the actual wall transition / knockdown, without attempting another hit.
 for(let i=0;i<185;i++){
  const s=e.state();if(i>=45&&!s.wallBreakTime&&!s.hitstop&&s.players.every(p=>p.move<0&&!p.reaction&&!p.stun))break;
  e.step(0,0);inputs.push([0,0]);hashes.push(e.hash);
 }
 const clip={id:source.id,character:source.character,target:source.target,initial:source.initial,
  title:position==='corner'?'CORNER DAMAGE':'MIDSCREEN DAMAGE',condition:'Normal hit · zero starting Momentum',
  route:row.route,damage:row.damage,hits:row.hits,wallBreak:!!end.wallBreakTime,firstHit,comboEnd,bonus,inputs,hashes,
  search:source.search};
 clips.push(clip);
 console.log(`${clip.id}: verified ${clip.damage} damage / ${clip.hits} continuous hits, ${inputs.length} ticks${clip.wallBreak?' / wall break':''}`);
}
const film={version:1,date:'2026-11-20',fps:60,width:1280,height:720,source:manifest,
 wasmSha256:createHash('sha256').update(wasm).digest('hex'),fingerprint:e.fingerprint(),
 method:'Best routes found by a bounded input search; not a proof of absolute maximum damage. All footage replays ordinary inputs in Godot, with the defender holding down-back after the first hit. No move data, health, hitstun or mid-combo positions were edited.',clips};
writeFileSync(`${out}/film.json`,JSON.stringify(film,null,2)+'\n');
const lines=['# Fight Guild combo showcase','','Current build: November 20, 2026. Normal hits, zero starting Momentum, 1,000 HP targets. Full-speed footage is 60 fps; each replay is explicitly half speed.','',film.method,'',
 '| Fighter / position | Damage | Hits | Route |','| --- | ---: | ---: | --- |',
 ...clips.map(c=>`| ${data.characters[c.character].name} / ${c.title.toLowerCase()} | ${c.damage}${c.wallBreak?' (includes wall break)':''} | ${c.hits} | ${c.route.map(r=>r.notation).join(' → ')} |`),
 '','`[Hs]` / `[D]` means hold the button for the charged version. Repeated moves are separate inputs. Follow-up 6S / 2S after Fillet’s 236S is the rekka branch. The frame-by-frame input traces and engine checksums are saved in `film.json`.',
 '', 'Fillet’s midscreen route also demonstrates the new 5D OTG cancel after the finisher. It is explicitly labelled as a bleed reset and adds no damage or hits to the combo total.',
 '', 'Search limits and target characters are recorded per clip. These are current-build damage examples; launcher loops are shown as found so they can inform later balance work. No counter-hit, preloaded bleed, pre-damaged wall or custom tuning was used.',''];
writeFileSync(`${out}/routes.md`,lines.join('\n'));
