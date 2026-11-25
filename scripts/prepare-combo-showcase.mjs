// Validate ordinary-input routes against the native fixture. No editor writes.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import assert from 'node:assert/strict';
import {createCore,directory as out,manifest,data,wasm,sha256,notation} from './combo-showcase-core.mjs';
const json=p=>JSON.parse(readFileSync(p)),e=await createCore();
mkdirSync(out,{recursive:true});
const selections=[
 ['fillet-midscreen',0,'MIDSCREEN ROUTE'],['fillet-corner',0,'CORNER BREAK'],
 ['smoke-midscreen',0,'CHARGED DRIVE CONFIRM'],['smoke-corner',1,'POISON SWORD FINISH'],
 ['shark-midscreen',0,'HOOK ROUTE + PULL'],['shark-corner',0,'CORNER BREAK'],
 ['tapper-midscreen',0,'FRONT STANCE CONFIRM'],['tapper-stance',2,'DEMPSEY STANCE ROUTE'],
 ['hammer-midscreen',0,'DRIVE DASH EXTENSION'],['hammer-corner',0,'CORNER BREAK'],
 ['anvil-midscreen',1,'CHARGE CONFIRM'],['anvil-corner',0,'LAUNCH INTO SKY FOUNDRY']
];
const clips=[];
for(const [id,index,title] of selections){
 const source=json(`${out}/${id}.json`),row=source.candidates[index];
 assert.ok(row,`Missing selected route: ${id}/${index}`);
 const initial=structuredClone(source.initial);
 if(id==='anvil-midscreen')initial.momentum=0;
 const reset=()=>{
  e.reset(initial.characters);
  for(let p=0;p<2;p++)e.api.fg_preview_place(p,initial.positions[p],0,initial.momentum);
  for(const input of initial.setupInputs??[])e.step(...input);
 };
 reset();
 const base=e.state(),healthBase=base.players[1].health,contactBase=base.players[0].contactCount;
 assert.equal(healthBase,initial.baseHealth??1000);assert.equal(contactBase,initial.contactBase??0);
 let contacts=contactBase,hits=0,firstHit=0,ended=false;
 const hashes=[],events=[],inputs=structuredClone(row.inputs);
 for(const [index,input]of inputs.entries()){
  assert.ok(!ended,`${id}: sequence continued after its combo ended`);
  e.step(...input);const s=e.state(),a=s.players[0],b=s.players[1];hashes.push(e.hash);
  const delta=a.contactCount-contacts;assert.ok(delta>=0,`${id}: contact counter reset`);
  if(delta){
   assert.notEqual(a.event,2,`${id}: blocked follow-up`);
   hits+=delta;assert.equal(a.combo,hits,`${id}: combo reset on frame ${index+1}`);
   contacts+=delta;firstHit||=index+1;
   events.push({frame:index+1,hits,damage:healthBase-b.health,move:a.lastMove});
  }
  if(hits&&(s.wallBreakTime||(!s.hitstop&&(b.reaction===2||b.reaction===3||(!b.stun&&b.reaction===0)))))ended=true;
 }
 const end=e.state();assert.equal(healthBase-end.players[1].health,row.damage,`${id}: damage changed`);assert.equal(hits,row.hits);
 const comboEnd=inputs.length;
 for(let i=0;i<220;i++){
  const s=e.state();if(i>=45&&!s.wallBreakTime&&!s.hitstop&&s.players.every(p=>p.move<0&&!p.reaction&&!p.stun&&!p.pairRecovery))break;
  e.step(0,0);inputs.push([0,0]);hashes.push(e.hash);
 }
 // Replay and midpoint restore before the independent native frame check.
 reset();let snapshot;
 const middle=Math.floor(inputs.length/2);
 for(const [i,input]of inputs.entries()){
  e.step(...input);assert.equal(e.hash,hashes[i],`${id}: repeat mismatch at ${i}`);
  if(i===middle)snapshot=e.snapshot();
 }
 e.restore(snapshot);
 for(let i=middle+1;i<inputs.length;i++){e.step(...inputs[i]);assert.equal(e.hash,hashes[i],`${id}: restored mismatch at ${i}`);}
 let condition='Normal hit / 0% starting Momentum';
 if(id==='anvil-midscreen')condition+=' / hold back 30f before the starter';
 if(id==='anvil-corner')condition='Normal hit / 50% starting Momentum / Sky Foundry costs 50%';
 if(id==='tapper-stance')condition='Normal hit / Dempsey stance earned with 5D / setup damage excluded';
 const clip={id,character:source.character,target:source.target,initial:{...initial,baseHealth:healthBase,contactBase},title,condition,
  route:row.route.map(r=>({...r,notation:notation(source.character,r.slot)})),damage:row.damage,hits:row.hits,wallBreak:!!end.wallBreakTime,
  firstHit,comboEnd,inputs,hashes,events,search:source.search};
 clips.push(clip);console.log(`${id}: verified ${clip.damage} damage / ${hits} continuous hits, ${inputs.length} ticks${clip.wallBreak?' / wall break':''}`);
}
const film={version:2,date:'2026-11-25',fps:60,width:1280,height:720,source:manifest,
 wasmSha256:sha256(wasm),configurationSha256:sha256(readFileSync(`${out}/configuration.bin`)),
 artSha256:sha256(readFileSync('godot/assets/fighters/manifest.json')),fingerprint:e.fingerprint(),
 method:'Strong routes found by a bounded ordinary-input search, not proof of absolute maximum damage. The defender guards after the first hit. All contacts must remain in one combo. No mid-combo position, health, hitstun, wall damage or tuning edits. Tapper stance is earned through an input prelude; its setup damage is excluded. Anvil’s super example starts with 50% Momentum. Native recording verifies every simulation checksum.',clips};
writeFileSync(`${out}/film.json`,JSON.stringify(film,null,2)+'\n');
const lines=['# Fight Guild combo showcase — 25 November 2026','',film.method,'',
 'Two examples per fighter, shown at 60 fps and repeated at half speed without interpolating animation frames. Updated Anvil art, magma shield effects and throw depth tracks are included.','',
 '| Fighter / example | Damage | Hits | Route |','| --- | ---: | ---: | --- |',
 ...clips.map(c=>`| ${data.characters[c.character].name} / ${c.title.toLowerCase()} | ${c.damage}${c.wallBreak?' (wall break)':''} | ${c.hits} | ${c.route.map(r=>r.notation).join(' → ')} |`),
 '', 'Conditions: normal hits against 1,000 maximum HP, fresh walls and no preloaded status effects. Tapper’s stance example starts after a real 5D setup at 935 remaining HP; only the following 265 damage counts. Anvil’s charge confirm starts at 0% Momentum, with 30 frames of back charge before the starter. His Sky Foundry example starts at 50%. All other examples start at 0%.',
 '', '`[D]` means hold the button for the charged version; `[4]6Hs` means charge back then forward + Hs. `st.` marks Dempsey stance. Repeated attacks are separate inputs. Hammer’s 5D is a dash, and Shark’s 5D is a pull, so those actions add no hit by themselves.',
 '', 'The film JSON contains setup inputs, ordinary frame-by-frame inputs, per-contact results and replay checksums. Search limits and target character are recorded per example. These are useful current-build damage routes, not a claim of tournament optimization. Some routes expose repeated-launcher balance opportunities.', ''];
writeFileSync(`${out}/routes.md`,lines.join('\n'));
