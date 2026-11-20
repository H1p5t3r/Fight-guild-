import {MOVE_IDS,moveName} from './model.mjs';
import {REGIONS,parameterRange} from '../extensions.mjs';
const labels={policy:'Kit policy',contactKind:'Contact behavior',lowCrushStart:'Low crush begins',lowCrushEnd:'Low crush ends',passStart:'Pass-through begins',passEnd:'Pass-through ends',refaceFrame:'Reface on frame',stopAtBody:'Stop at opponent body',groundedLift:'Authored vertical root',bleedDelay:'Completed ticks after contact',bleedWindowStart:'Cashout cancel opens',bleedWindowEnd:'Cashout cancel closes',captureFreeze:'Capture freeze',pairTicks:'Paired action ticks',releaseFreeze:'Release freeze',ownerRecovery:'Attacker release recovery',victimRecovery:'Defender release recovery',releaseGap:'Release root spacing · px',throwGrace:'Defender throw protection after unlock',techTicks:'Throw-tech window',pairTrack:'Paired root track',friction:'Attack friction · px/tick',bleedDuration:'Bleed duration',bleedInitial:'Initial grey life',bleedGrowth:'Periodic grey gain',bleedInterval:'Ticks between grey gains',bleedBlockPercent:'Base damage stored on ordinary block · %',bleedCap:'Grey-life cap',groundSpeedPercent:'Ground speed while owning bleed · %',airSpeedPercent:'Air-dash speed while owning bleed · %',coastCap:'Post-air-dash coast cap · px/tick',backdashLock:'Committed backdash ticks',halfWidth:'Push half width · px',standingHeight:'Standing push height · px',crouchingHeight:'Crouching push height · px',airBottom:'Air push bottom · px',airTop:'Air push top · px',walkStride:'Distance per walk pose · px',runStride:'Distance per run pose · px'};
const px=new Set(['releaseGap','friction','coastCap','halfWidth','standingHeight','crouchingHeight','airBottom','airTop','walkStride','runStride']);
export function renderExtension({el,character,slot,tab,frame,onChange,onCharacterChange,onSeek,onMove,onError}){
 const m=character.moves[slot],x=m.extensions,c=character.extensions,root=el('section',{class:'form-section extension-editor'});
 const commit=(next,char=false)=>{try{(char?onCharacterChange:onChange)(next);onError('extension','');}catch(error){onError('extension',error.message);}};
 const number=(parent,label,value,change,scale=1,min=-10000,max=10000)=>{
  const wrap=el('label',{class:'field'}),input=el('input',{type:'number',step:scale===1?'1':'0.01',inputmode:min<0?'text':'decimal',min,max});input.value=value/scale;
  wrap.append(el('span',{},label),input);parent.append(wrap);
  input.onchange=()=>{const v=Number(input.value)*scale;if(!input.value.trim()||!Number.isFinite(v)||Math.abs(v-Math.round(v))>1e-6){onError('extension','Enter a whole frame or a distance with at most two decimals.');return;}change(Math.round(v));};
 };
 const params=(object,names,char=false)=>{const grid=el('div',{class:'field-grid'});for(const name of names){const scale=px.has(name)||/^(ground|air)(Left|Right|Bottom|Top)$/.test(name)?100:1,[min,max]=parameterRange(name,char);number(grid,labels[name]||name.replace(/([A-Z])/g,' $1')+(scale===100?' · px':''),object.params[name],v=>{const next=structuredClone(object);next.params[name]=v;commit(next,char);},scale,min/scale,max/scale);}root.append(grid);};
 const rectangles=(track,key,body=false)=>{
  const boxes=body?key.boxes:{push:key.box};
  if(body){const toggles=el('fieldset',{class:'hurt-vulnerability'});toggles.append(el('legend',{},'Body regions at this key'));
   for(const region of REGIONS){const label=el('label',{class:'hurt-toggle'}),check=el('input',{type:'checkbox',checked:!!boxes[region]});label.append(check,document.createTextNode(region==='torsoArms'?'Torso & arms':region));toggles.append(label);
    check.onchange=()=>{const next=structuredClone(x),k=next[track].find(k=>k.frame===key.frame);if(check.checked)k.boxes[region]=structuredClone(c.profiles.ready[region]||c.profiles.ready.torsoArms);else delete k.boxes[region];commit(next);};}root.append(toggles);}
  for(const [region,rect]of Object.entries(boxes)){const grid=el('div',{class:'field-grid'});root.append(el('h3',{},region==='torsoArms'?'Torso & arms':region));
   ['Left','Bottom','Right','Top'].forEach((edge,i)=>number(grid,`${edge} · px`,rect[i],v=>{const next=structuredClone(x),k=next[track].find(k=>k.frame===key.frame);(body?k.boxes[region]:k.box)[i]=v;commit(next);},100));root.append(grid);}
 };
 const trackEditor=(name,title,template,body=false)=>{
  root.append(el('h2',{},title));const keys=x[name],key=keys.findLast(k=>k.frame<=frame)||keys[0];
  const controls=el('div',{class:'track-actions'}),select=el('select',{'aria-label':title+' key'});
  keys.forEach(k=>select.append(el('option',{value:k.frame},`Move frame ${k.frame}`)));if(key)select.value=key.frame;
  select.onchange=()=>onSeek(Number(select.value));
  const add=el('button',{type:'button',disabled:keys.some(k=>k.frame===frame)||keys.length>=(body?32:8)},`Add key at frame ${frame}`);
  add.onclick=()=>{const next=structuredClone(x);if(!next[name].length&&frame>1)next[name].push(structuredClone(template));next[name].push({...structuredClone(key||template),frame});next[name].sort((a,b)=>a.frame-b.frame);commit(next);};
  const remove=el('button',{type:'button',disabled:!key||key.frame===1},'Remove key');remove.onclick=()=>{const next=structuredClone(x);next[name]=next[name].filter(k=>k.frame!==key.frame);commit(next);};
  controls.append(select,add,remove);root.append(controls,el('p',{class:'hint'},'Keys use absolute move frames. Each key holds until the next; missing body regions are disabled. Phase protection masks and timed invulnerability still apply.'));
  if(key)rectangles(name,key,body);
 };
 if(tab==='hurt'&&x){trackEditor('hurtboxes','Body hurtboxes over time',{frame:1,boxes:c.profiles.ready},true);}
 if(tab==='routes'&&x){
  root.append(el('h2',{},'Named cancel routes'),el('p',{},'These exact destinations replace broad button gatlings for this kit. Contact is required. The timing windows below use completed source frames.'));
  root.append(el('p',{class:'hint'},'Wound (5D) routes are hit-only: the source must cause knockdown and the opponent must have landed. Blocking or whiffing never allows this cancel. Wound still needs to reach before wakeup.'));
  for(const [name,label]of [['normal','Normal attacks'],['special','Special & Drive attacks'],['follow','Rekka follow-ups'],['bleed','Bleed cashouts']]){const group=el('fieldset',{class:'extension-routes'});group.append(el('legend',{},label));
   character.moves.forEach((move,i)=>{const linked=move.followFrom===slot||move.followFrom2===slot,follow=move.followFrom>=0||move.followFrom2>=0,kind=move.extensions?.params.contactKind||0;
    const eligible=kind===3?name==='special'&&m.knockdown>0&&!m.air:name==='bleed'?kind===2&&!m.air:name==='follow'?linked:name==='special'?[2,3].includes(move.category)&&!follow&&move.air===m.air:move.category<=1&&!follow&&move.air===m.air;
    if((!move.enabled||!eligible)&&!x.routes[name].includes(i))return;const row=el('label',{class:'hurt-toggle'}),check=el('input',{type:'checkbox',checked:x.routes[name].includes(i)});row.append(check,document.createTextNode(moveName(move)+(kind===3?' · OTG bleed (hit only)':'')));group.append(row);check.onchange=()=>{const next=structuredClone(x);next.routes[name]=check.checked?[...next.routes[name],i].sort((a,b)=>a-b):next.routes[name].filter(v=>v!==i);commit(next);};});
   if(group.children.length===1)group.append(el('p',{class:'hint'},'No destinations for this move.'));root.append(group);}
  params(x,['bleedDelay','bleedWindowStart','bleedWindowEnd']);
 }
 if(tab==='mechanics'&&c){
  root.append(el('h2',{},'Wound → owned bleed → cashout'),el('p',{},'5D captures a downed opponent and applies bleed when the pair releases. 236D / 214D spend that bleed on a confirmed grounded capture. Ordinary throws preserve bleed.'));
  root.append(el('p',{class:'hint'},'Default setups: 2S → 5D, 236S → 6S → 5D, or 236S → 2S → 5D. Press D after the knockdown connects to cancel recovery. These routes are edited on the finisher under Inputs & cancels → Special & Drive attacks.'));
  const navigation=el('div',{class:'track-actions'});for(const index of [13,45,46,23,24]){const button=el('button',{type:'button','data-capture-move':index,'aria-pressed':String(index===slot)},`${moveName(character.moves[index])} · ${character.moves[index].extensions?.art?.name||'Capture'}`);button.onclick=()=>onMove(index);navigation.append(button);}root.append(navigation);
  params(c,['bleedDuration','bleedInitial','bleedGrowth','bleedInterval','bleedBlockPercent','bleedCap','groundSpeedPercent','airSpeedPercent'],true);
  if(x?.params.contactKind){root.append(el('h2',{},`${moveName(m)} · paired capture`));params(x,['captureFreeze','pairTicks','releaseFreeze','ownerRecovery','victimRecovery','releaseGap','throwGrace','techTicks']);
   const select=el('select',{'aria-label':'Paired root track'});['Wound restand','Forward throw','Back throw','Command cashout'].forEach((name,i)=>select.append(el('option',{value:i},name)));select.value=x.params.pairTrack;select.onchange=()=>{const next=structuredClone(x);next.params.pairTrack=Number(select.value);commit(next);};root.append(select);
   root.append(el('p',{class:'hint'},'During the pair both fighters are protected. Release recovery is strike-vulnerable, with independent attacker and defender clocks. Ordinary throws can be teched during C1–C6.'));
   const track=c.pairTracks[x.params.pairTrack];root.append(el('h3',{},'Paired roots · relative to capture'));
   track.forEach((key,i)=>{const grid=el('div',{class:'field-grid'});number(grid,`Key ${i+1} · pair tick`,key.tick,v=>{const next=structuredClone(c);next.pairTracks[x.params.pairTrack][i].tick=v;commit(next,true);},1,0,180);for(const role of ['owner','victim'])['x','y'].forEach((axis,j)=>number(grid,`${role==='owner'?'Attacker':'Defender'} ${axis} · px`,key[role][j],v=>{const next=structuredClone(c);next.pairTracks[x.params.pairTrack][i][role][j]=v;commit(next,true);},100));root.append(grid);});
  }
 }
 if(tab==='hit'&&x){
  root.append(el('h2',{},'Attack movement'),el('p',{},'Attack root motion is separate from incoming run or dash momentum. Bleed changes voluntary movement speed only.'));
  params(x,['friction','lowCrushStart','lowCrushEnd','passStart','passEnd','refaceFrame','stopAtBody','groundedLift']);
  root.append(el('h3',{},'Default grounded / airborne pushbox'));params(x,['groundLeft','groundBottom','groundRight','groundTop','airLeft','airBottom','airRight','airTop']);
  for(const [name,fields]of [['rootTrack',['first','last','dx','dy','collision']],['verticalRootKeys',['frame','y']]]){
   root.append(el('h3',{},name==='rootTrack'?'Root travel segments':'Vertical root keys'));
   x[name].forEach((key,i)=>{const grid=el('div',{class:'field-grid'});fields.forEach(field=>number(grid,`${field}${['dx','dy','y'].includes(field)?' · px':''}`,key[field],v=>{const next=structuredClone(x);next[name][i][field]=v;commit(next);},['dx','dy','y'].includes(field)?100:1));const remove=el('button',{type:'button'},'Remove');remove.onclick=()=>{const next=structuredClone(x);next[name].splice(i,1);commit(next);};grid.append(remove);root.append(grid);});
   const add=el('button',{type:'button',disabled:x[name].length>=8},'Add '+(name==='rootTrack'?'travel segment':'vertical key'));add.onclick=()=>{const next=structuredClone(x),f=name==='rootTrack'?(next[name].at(-1)?.last??0)+1:(next[name].at(-1)?.frame??0)+1;next[name].push(name==='rootTrack'?{first:f,last:f,dx:0,dy:0,collision:0}:{frame:f,y:0});commit(next);};root.append(add);
  }
  trackEditor('pushboxes','Pushbox keys',{frame:1,box:[x.params.groundLeft,x.params.groundBottom,x.params.groundRight,x.params.groundTop]});
 }
 if(tab==='movement'&&c){root.append(el('h2',{},'Fillet movement policy'));params(c,['coastCap','backdashLock','halfWidth','standingHeight','crouchingHeight','airBottom','airTop','walkStride','runStride'],true);}
 root.append(el('p',{id:'error-extension',class:'error','aria-live':'polite'}));return root;
}
