import {FIELD_GROUPS} from './field-layout.mjs';
import {inputName} from './model.mjs';

export function driveKit(character){
 const enabled=character.moves.map((move,slot)=>({move,slot})).filter(({move})=>move.enabled);
 return {
  entries:enabled.filter(({move:m})=>(m.mechanic>0&&m.mechanic<=3||m.mechanic===5)||m.stanceChange===1&&m.stanceRequired!==2),
  spends:enabled.filter(({move:m})=>m.mechanic===4),
  stance:enabled.filter(({move:m})=>m.stanceRequired===2&&m.stanceChange!==2),
  exits:enabled.filter(({move:m})=>m.stanceChange===2),
  other:enabled.filter(({move:m})=>m.category===3&&!m.mechanic&&!m.stanceChange&&m.stanceRequired!==2),
 };
}

export function renderDrive({el,character,slot,note,panels,field,onMove,onTab,onTest,testMode}){
 const m=character.moves[slot],kit=driveKit(character),rolling=kit.entries.some(({move})=>move.stanceChange===1)||kit.stance.length>0;
 const root=el('div',{class:'drive-editor'}),overview=el('section',{class:'drive-overview','aria-label':`${character.name} Drive setup`});
 overview.append(el('p',{class:'eyebrow'},`${character.name.toUpperCase()} · DRIVE SYSTEM`),el('h2',{},kit.entries.some(({move})=>move.mechanic===5)?'Break Step':rolling?'Rolling stance':kit.entries.some(({move})=>move.mechanic===3)?'Tag → pull':kit.entries.some(({move})=>move.mechanic===2)?'Bleed → cash-out':kit.entries.some(({move})=>move.mechanic===1)?'Tether → pull':'Drive actions'));
 overview.append(el('p',{},rolling?'Choose an entry, stance attack or exit. Rolling stance cannot block or use Faultless Defense.':'Choose an action to edit its attack, status and follow-up.'));
 for(const [key,label]of [['entries',kit.entries.some(({move})=>move.mechanic===5)?'Movement Drive':rolling?'Enter / apply':'Apply status'],['spends','Pull the opponent'],['stance','While in stance'],['exits','Exit stance'],['other','Other Drive actions']]){
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
 const behavior=m.mechanic===5?`One use per string. Any special can cancel into this after its first active frame, including on whiff. During the burst, cancel into any grounded normal: +${m.drivePlus}f block advantage and 100% dash velocity carry, then normal attack friction. Refreshes after ${m.driveNeutralFrames} consecutive neutral frames. Distance: ${m.driveDistance?(m.driveDistance/100)+' px override':'automatic, from longest grounded normal + normal block pushback to point blank'}. It has no strike, projectile, armor or invulnerability.`:m.mechanic===3?'On an unblocked hit: attach a timed line. Follow with 2D Reel In. The line expires, breaks at range, or breaks when its owner is hit.':m.mechanic===4?'Spend the line on the first active frame. The pull ignores guard and moves the target horizontally without damage, hitstop or new stun. A free target can attack, jump, dash and guard throughout. Existing hitstun or blockstun pauses until the pull ends. Without a line, this action whiffs.':m.mechanic===1?`On hit: attach a tether. Repeat ${inputName(m)} while tethered: pull once. The next contact after that pull clears it.`:m.mechanic===2?`On hit: apply bleed and store grey life. Repeat ${inputName(m)} while bleeding: attempt the cash-out grab.`:m.stanceChange===2?'Starts by exiting rolling stance.':m.stanceRequired===2?`Available in rolling stance.${m.stanceChange===1?' A successful hit returns to stance offense.':''}`:m.stanceChange===1?'A successful hit enters rolling stance.':'This move has no conditional status or stance transition configured.';
 selected.append(el('p',{class:'drive-behavior'},behavior));
 const tests=el('div',{class:'drive-test-actions',role:'group','aria-label':'Drive preview'});
 if(m.mechanic&&m.mechanic<3){
  for(const [mode,label]of [['single','Test initial attack'],['followup','Test apply → follow-up'],...(m.mechanic===2?[['expire','Test bleed timeout']]:[])]){
   const button=el('button',{type:'button','data-drive-test':mode,'aria-pressed':String(testMode===mode)},label);button.onclick=()=>onTest(mode);tests.append(button);
  }
 }
 if(m.mechanic===5){
  for(const [mode,label]of [['single','Test travel'],['followup','Test dash → close normal']]){const b=el('button',{type:'button','data-drive-test':mode,'aria-pressed':String(testMode===mode)},label);b.onclick=()=>onTest(mode);tests.append(b);}
 }
 if(m.mechanic===3||m.mechanic===4){
  const choices=m.mechanic===3?[['single','Test tag'],['followup','Test tag → reel'],['expire','Watch line expire']]:[['single','Test without line'],['followup','Test with line']];
  for(const [mode,label]of choices){const b=el('button',{type:'button','data-drive-test':mode,'aria-pressed':String(testMode===mode)},label);b.onclick=()=>onTest(mode);tests.append(b);}
 }
 const sequence=el('button',{type:'button',class:'quiet'},'Open sequence test');sequence.onclick=()=>onTab('sequence');tests.append(sequence);selected.append(tests);root.append(selected);
 const add=(id,overrides={})=>root.append(panels.create({...FIELD_GROUPS.find(g=>g.id===id),...overrides},field));
 root.append(panels.create({id:'drive-initial',title:m.mechanic===5?'Load / burst / recovery':m.mechanic===4?'Pull timing':m.mechanic?'Initial attack':'Selected action',defaultOpen:false,value:move=>`${move.startup} / ${move.active} / ${move.recovery}f${move.mechanic===4?'':` · ${move.damage} dmg`}`,intro:m.mechanic===4?'The pull starts on the first active frame. It has no strike hitbox or impact payload.':'Startup / active / recovery and base damage, before any conditional follow-up.',fields:[4,5].includes(m.mechanic)?['startup','active','recovery']:['startup','active','recovery','damage']},field));
 add('drive-type',{title:rolling?'Optional applied status':'Applied status',defaultOpen:false,value:move=>['None','Legacy tether','Bleed → cash-out','Attach line','Reel In','Break Step'][move.mechanic],active:move=>!rolling||!!move.mechanic});
 add('step-drive',{contextual:true,hideInactiveCount:true,defaultOpen:true});
 add('bleed',{contextual:true});
 add('line',{contextual:true,hideInactiveCount:true,fields:['tetherDuration','tetherRange','tetherGap',...(m.mechanic===4?['tetherFrames']:[])]});
 add('variant-timing',{contextual:true,hideInactiveCount:true,title:m.mechanic===1?'Repeat input · tether pull':'Repeat input · cash-out grab',intro:m.mechanic===1?'Replaces the attack while tethered. Pulls the target toward the owner without dealing damage.':'Replaces the attack while bleeding. A successful grab pays out base damage plus stored grey life.',fields:['variant-timing','tether','cash-out'].flatMap(id=>FIELD_GROUPS.find(g=>g.id===id).fields).filter(key=>key!=='tetherFrames'||m.mechanic!==4)});
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
