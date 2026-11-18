import {FIELD_GROUPS} from './field-layout.mjs';
import {inputName} from './model.mjs';

export function driveKit(character){
 const enabled=character.moves.map((move,slot)=>({move,slot})).filter(({move})=>move.enabled);
 return {
  entries:enabled.filter(({move:m})=>m.mechanic||m.stanceChange===1&&m.stanceRequired!==2),
  stance:enabled.filter(({move:m})=>m.stanceRequired===2&&m.stanceChange!==2),
  exits:enabled.filter(({move:m})=>m.stanceChange===2),
  other:enabled.filter(({move:m})=>m.category===3&&!m.mechanic&&!m.stanceChange&&m.stanceRequired!==2),
 };
}

export function renderDrive({el,character,slot,note,panels,field,onMove,onTab,onTest,testMode}){
 const m=character.moves[slot],kit=driveKit(character),rolling=kit.entries.some(({move})=>move.stanceChange===1)||kit.stance.length>0;
 const root=el('div',{class:'drive-editor'}),overview=el('section',{class:'drive-overview','aria-label':`${character.name} Drive setup`});
 overview.append(el('p',{class:'eyebrow'},`${character.name.toUpperCase()} · DRIVE SYSTEM`),el('h2',{},rolling?'Rolling stance':kit.entries.some(({move})=>move.mechanic===2)?'Bleed → cash-out':kit.entries.some(({move})=>move.mechanic===1)?'Tether → pull':'Drive actions'));
 overview.append(el('p',{},rolling?'Choose an entry, stance attack or exit. Rolling stance cannot block or use Faultless Defense.':'Choose an action to edit its attack, status and follow-up.'));
 for(const [key,label]of [['entries',rolling?'Enter / apply':'Apply status'],['stance','While in stance'],['exits','Exit stance'],['other','Other Drive actions']]){
  if(!kit[key].length)continue;
  const row=el('div',{class:'drive-route'});row.append(el('span',{class:'drive-route-label'},label));
  const buttons=el('div',{class:'drive-action-list',role:'group','aria-label':label});
  for(const {move,slot:index}of kit[key]){
   const button=el('button',{type:'button','data-drive-move':index,'aria-current':String(index===slot)},inputName(move));
   button.title=note(index).label||move.id;button.onclick=()=>onMove(index);buttons.append(button);
  }row.append(buttons);overview.append(row);
 }
 if(!Object.values(kit).some(rows=>rows.length))overview.append(el('p',{},'No Drive actions are enabled yet. You can configure the selected move below.'));
 root.append(overview);
 const selected=el('section',{class:'drive-selected'});
 selected.append(el('p',{class:'eyebrow'},'EDITING THIS ACTION'),el('h2',{},`${inputName(m)}${note(slot).label?' · '+note(slot).label:''}`));
 const behavior=m.mechanic===1?`On hit: attach a tether. Repeat ${inputName(m)} while tethered: pull once. The next contact after that pull clears it.`:m.mechanic===2?`On hit: apply bleed and store grey life. Repeat ${inputName(m)} while bleeding: attempt the cash-out grab.`:m.stanceChange===2?'Starts by exiting rolling stance.':m.stanceRequired===2?`Available in rolling stance.${m.stanceChange===1?' A successful hit returns to stance offense.':''}`:m.stanceChange===1?'A successful hit enters rolling stance.':'This move has no conditional status or stance transition configured.';
 selected.append(el('p',{class:'drive-behavior'},behavior));
 const tests=el('div',{class:'drive-test-actions',role:'group','aria-label':'Drive preview'});
 if(m.mechanic){
  for(const [mode,label]of [['single','Test initial attack'],['followup','Test apply → follow-up'],...(m.mechanic===2?[['expire','Test bleed timeout']]:[])]){
   const button=el('button',{type:'button','data-drive-test':mode,'aria-pressed':String(testMode===mode)},label);button.onclick=()=>onTest(mode);tests.append(button);
  }
 }
 const sequence=el('button',{type:'button',class:'quiet'},'Open sequence test');sequence.onclick=()=>onTab('sequence');tests.append(sequence);selected.append(tests);root.append(selected);
 const add=(id,overrides={})=>root.append(panels.create({...FIELD_GROUPS.find(g=>g.id===id),...overrides},field));
 root.append(panels.create({id:'drive-initial',title:m.mechanic?'Initial attack':'Selected action',defaultOpen:false,value:move=>`${move.startup} / ${move.active} / ${move.recovery}f · ${move.damage} dmg`,intro:'Startup / active / recovery and base damage, before any conditional follow-up.',fields:['startup','active','recovery','damage']},field));
 add('drive-type',{title:rolling?'Optional applied status':'Applied status',defaultOpen:false,value:move=>['None','Tether → pull','Bleed → cash-out'][move.mechanic],active:move=>!rolling||!!move.mechanic});
 add('bleed',{contextual:true});
 add('variant-timing',{contextual:true,hideInactiveCount:true,title:m.mechanic===1?'Repeat input · tether pull':'Repeat input · cash-out grab',intro:m.mechanic===1?'Replaces the attack while tethered. Pulls the target toward the owner without dealing damage.':'Replaces the attack while bleeding. A successful grab pays out base damage plus stored grey life.',fields:['variant-timing','tether','cash-out'].flatMap(id=>FIELD_GROUPS.find(g=>g.id===id).fields)});
 add('stance-access',{active:move=>rolling||!!move.stanceChange||move.stanceRequired===2});
 if(rolling||m.actionType||panels.all){
  add('action');add('capture',{contextual:true});
 }
 const links=el('div',{class:'related-settings'});
 for(const [tab,label]of [['routes','Edit inputs & cancels'],['hit','Edit hitboxes & impact'],['stance','Edit action behavior'],['art','Edit sprites & art notes']]){
  const button=el('button',{type:'button',class:'quiet'},label);button.onclick=()=>onTab(tab);links.append(button);
 }root.append(links);
 return root;
}
