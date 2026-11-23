import {COMBO_RULE_SPECS} from '../combo-rules.mjs';
import {renderExtension} from './extension-editor.mjs';
import {renderMovement} from './movement-editor.mjs';
import {moveFieldLimit} from '../startup-rules.mjs';
import {Workshop,validate,parseField,totalFrames,blockAdvantage,phaseAt,phaseStart,effectiveHurtboxes,inputName,moveName,geometryWarnings,CHARACTERS,MOVE_IDS,clone,META} from './model.mjs';
import {HURT_PHASES,HURT_REGIONS,HURT_LABELS,HURT_MASK_FIELDS,regionEnabled,validateHurtboxes} from '../hurtboxes.mjs';
import {SPECS,GROUPS,TABS,ART_FIELDS,GUILDS,COLORS,KINDS} from './specs.mjs';
import {Preview} from './preview.mjs';
import {prepareReference,MAX_REFERENCES,MAX_IMPORT_BYTES,REFERENCE_PHASES} from './references.mjs';
import {validateHitTimeline,keyAt} from '../hitboxes.mjs';
import {renderHitEditor} from './hit-editor.mjs';
import {CombatPreview,describeInput} from './simulation.mjs';
import {cursorAnchor,cursorIndex} from './cursor.mjs';
import {createLayout} from './layout.mjs';
import {FieldPanels} from './field-panels.mjs';
import {renderDrive} from './drive-editor.mjs';
import {createSettingSearch} from './setting-search.mjs';
import {renderSequence,showSequenceResult} from './sequence-editor.mjs';
const $=id=>document.getElementById(id),pack=globalThis.FIGHT_WORKSHOP_DATA;
const STORAGE='fight-guild.move-workshop.v1';
let model,character=5,slot=0,tab='timing',filter='all',frame=5,playing=false,lastTick=0,saveTimer,toastTimer,dragBefore;
let storageOkay=true,savePending=false,unexported=false,bootLocked=false,recoveryRaw='',referenceBusy=false;
let movementAction='idle';
let hurtPhase='active',hurtRegion='torsoArms',hurtDragBefore;
let hitKeyFrame=null,hitBox=0,testRecord,testIndex=0,testTimer,testSignature='',recordSignature='',previewPending=false,pendingSeek={frame:5};
const combatPreview=new CombatPreview(pack);
const errors=new Map();
function el(tag,attributes={},text){const node=document.createElement(tag);for(const [key,value]of Object.entries(attributes)){if(key==='class')node.className=value;else if(key==='checked')node.checked=value;else node.setAttribute(key,value);}if(text!==undefined)node.textContent=text;return node;}
function announce(text){$('toast').textContent=text;$('toast').hidden=false;clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').hidden=true,4200);}
function download(content,name,type){const url=URL.createObjectURL(new Blob([content],{type})),a=el('a',{href:url,download:name});document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),30000);}
function date(){return new Date().toISOString().slice(0,10);}
function banner(text){$('storage-warning').replaceChildren(document.createTextNode(text));$('storage-warning').hidden=false;}
function save(){
  clearTimeout(saveTimer);savePending=false;
  if(bootLocked)return;
  try {localStorage.setItem(STORAGE,JSON.stringify({format:1,data:model.data,selection:{character,slot,tab},savedAt:Date.now()}));storageOkay=true;$('save-dot').style.background='var(--green)';$('save-status').textContent='Saved in this browser';}
  catch{storageOkay=false;$('save-dot').style.background='var(--gold)';$('save-status').textContent='Download to keep your edits';banner('Browser storage is unavailable or full. Your edits still work; download JSON before closing this page.');}
  refreshActions();
}
function scheduleSave(){unexported=true;savePending=true;$('save-status').textContent='Saving draft…';clearTimeout(saveTimer);saveTimer=setTimeout(save,250);}
function validBeforeLeaving(){if(referenceBusy){announce('The pose reference is still being prepared.');return false;}if(bootLocked){announce('Recover your saved draft or start a new one first.');return false;}if(!errors.size)return true;announce('Fix the highlighted value before changing moves or downloading.');$(errors.keys().next().value)?.focus();return false;}
function move(){return model.move(character,slot);}
function comboRuleForm(){
  const panel=el('details',{class:'field-panel',id:'combo-rules'});
  panel.append(el('summary',{},'Shared combo physics · all fighters'));
  const body=el('div',{class:'panel-body'});panel.append(body);
  body.append(el('p',{class:'panel-intro'},'Separate from damage scaling. Hit speed and bounce strength use decay before this attack. Repeated-attack gravity starts on the configured use, without a hit-count delay.'));
  const grid=el('div',{class:'field-grid'});body.append(grid);
  const extra=[
    {key:'repeatAfter',group:'tuningRules',label:'Repeat penalty from use',help:'3 penalizes the third and later uses of the same move. 0 disables it.'},
    {key:'repeatGravityStep',group:'tuningRules',label:'Repeat gravity +%',help:'Additional gravity for each penalized use; multi-hit attacks count once.'},
    {key:'gravityCap',group:'recoveryRules',label:'Gravity cap %',help:'Maximum combined decay and repeated-attack gravity.'}
  ];
  for(const spec of [...COMBO_RULE_SPECS,...extra]){
    const group=spec.group||'comboRules',key=spec.key,id='rule-'+key;
    const limits=pack.limits.rules[group][key];
    const field=el('div',{class:'field'}),label=el('label',{class:'field-label',for:'field-'+id},spec.label);
    let input;
    if(key==='comboPhysics'){
      input=el('select',{id:'field-'+id});
      for(const [v,t] of [[1,'Decay + velocity (current)'],[0,'Legacy distance + gatlings']])input.append(el('option',{value:v},t));
    }else input=el('input',{id:'field-'+id,type:'number',min:limits.min,max:limits.max,step:1,inputmode:'numeric'});
    input.value=model.data[group][key];input.setAttribute('aria-describedby','help-'+id+' error-'+id);
    field.append(label,input,el('p',{class:'hint',id:'help-'+id},spec.help),el('p',{class:'field-error',id:'error-'+id}));grid.append(field);
    input.onchange=()=>{try{
      if(input.value.trim()==='')throw new Error('Enter a whole number.');
      model.changeRule(group,key,Number(input.value));fieldError(id,'');
      stop();pendingSeek={tick:0};syncSummary();scheduleSave();
    }catch(error){fieldError(id,error.message);}};
  }
  return panel;
}
function fieldError(key,message){const id='field-'+key,node=$(id);if(message)errors.set(id,message);else errors.delete(id);node?.setAttribute('aria-invalid',String(!!message));const messageNode=$('error-'+key);if(messageNode)messageNode.textContent=message||'';refreshActions();}
function refreshActions(){
  $('export').disabled=bootLocked||referenceBusy||errors.size>0;$('undo').disabled=bootLocked||referenceBusy||(!model.undoStack.length&&!errors.size);$('redo').disabled=bootLocked||referenceBusy||!model.redoStack.length||errors.size>0;
  $('reset').disabled=tab==='movement'?bootLocked||referenceBusy:bootLocked||referenceBusy||(!move().hitboxTimeline.keys.length&&!move().hitboxTimeline.multiHit&&!Object.keys(move().hurtboxes).length&&!Object.keys(SPECS).filter(key=>!key.startsWith('smear')).some(key=>move()[key]!==pack.defaults.characters[character].moves[slot][key]));
  if(tab==='sequence')$('reset').disabled=bootLocked||referenceBusy||!model.sequence(character).length;
  $('attack-enabled').disabled=bootLocked||referenceBusy;
  $('import').disabled=referenceBusy;$('fighter').disabled=bootLocked||referenceBusy;
  if(errors.size){$('save-status').textContent='Check the highlighted value';$('save-dot').style.background='var(--danger)';}
}
function syncSummary(){
  const m=move(),adv=blockAdvantage(m),note=model.note(character,slot);
  document.documentElement.style.setProperty('--accent',COLORS[character]);
  $('move-context').textContent=`${CHARACTERS[character].toUpperCase()} / ${GUILDS[character].toUpperCase()}`;
  const movement=tab==='movement',sequence=tab==='sequence';
  document.querySelector('.attack-toggle').hidden=movement||sequence;document.querySelector('.summary').hidden=movement||sequence;
  for(const id of ['test-behavior','test-entry','test-gap','test-simple','test-mechanic'])$(id).closest('label').hidden=movement;
  $('test-mechanic').closest('label').hidden=movement||sequence||!m.mechanic||!!m.extensions;
  for(const option of $('test-mechanic').options){option.textContent=m.mechanic>=4?({single:'Without a line',followup:'With an attached line',expire:'Without a line'})[option.value]:m.mechanic===3?({single:'Tag only',followup:'Tag → Reel In',expire:'Tag → timeout'})[option.value]:({single:'Apply status',followup:'Apply → follow-up',expire:'Apply → wait for timeout'})[option.value];option.hidden=m.mechanic>=4&&option.value==='expire';}
  $('test-bleed').closest('label').hidden=movement||!model.data.characters[character].extensions;
  $('reset').textContent=sequence?'Clear queue':movement?'Reset movement':'Reset move';
  $('move-kind').hidden=movement||sequence;$('actual-input').hidden=movement||sequence;$('move-enabled').hidden=movement||sequence;
  $('move-title').textContent=sequence?'Sequence test':movement?'Movement & defense':moveName(m);$('move-label').textContent=movement||sequence?'':note.label||'';
  $('move-kind').textContent=KINDS[m.category];$('actual-input').textContent=`Input ${inputName(m)}`;
  $('move-enabled').textContent=m.enabled?'● Enabled':'○ Unused slot';$('move-enabled').style.color=m.enabled?'#a8cbaa':'var(--muted)';
  $('attack-enabled').checked=!!m.enabled;
  $('stat-startup').replaceChildren(document.createTextNode(m.startup),el('small',{},' f'));
  $('stat-damage').textContent=[4,5].includes(m.mechanic)?0:m.damage;$('stat-block').textContent=[4,5].includes(m.mechanic)||m.category===4||[1,2].includes(m.actionType)?'—':(adv>0?'+':'')+adv+' f';$('stat-block').className=[4,5].includes(m.mechanic)||m.category===4||[1,2].includes(m.actionType)?'':adv>0?'positive':adv<0?'negative':'';
  $('stat-total').replaceChildren(document.createTextNode(totalFrames(m)),el('small',{},' f'));
  const profiles=model.data.characters.filter((c,i)=>Object.keys(c.movement).some(key=>!key.startsWith('smear')&&c.movement[key]!==pack.defaults.characters[i].movement[key])).length;
  $('changed-count').textContent=`${model.changes().length} edited move${model.changes().length===1?'':'s'}${profiles?' · '+profiles+' movement profile'+(profiles===1?'':'s'):''}`;
  $('guild').textContent=GUILDS[character];$('roster-count').textContent=`${model.data.characters[character].moves.filter(m=>m.enabled).length} moves`;
  layout.update(CHARACTERS[character],moveName(m),model.note(character,slot).label);
  if($('slash-description'))$('slash-description').textContent=slashDescription();
  if($('slash-warning'))$('slash-warning').hidden=!!model.move(character,32).enabled&&model.move(character,2).proximityMove===32;
  const warnings=geometryWarnings(m);$('move-warnings').replaceChildren(...warnings.map(w=>el('p',{},w)));$('move-warnings').hidden=!warnings.length;
  refreshActions();syncPreview();
}
function listMoves(){
  const text=$('search').value.trim().toLowerCase(),list=$('move-list'),fragment=document.createDocumentFragment();let matches=0;
  model.data.characters[character].moves.forEach((m,i)=>{
    const note=model.note(character,i),matchesText=`${m.id} ${inputName(m)} ${note.label||''}`.toLowerCase().includes(text);
    const matchesFilter=filter==='all'||filter==='normal'&&[0,1,3,4].includes(m.category)&&!m.air||filter==='special'&&m.category===2||filter==='air'&&m.air;
    if((!m.enabled&&!$('show-unused').checked&&i!==slot)||!matchesText||!matchesFilter)return;
    const button=el('button',{type:'button',class:'move-row'+(!m.enabled?' off':''),'aria-current':String(i===slot),'data-move':i,'aria-label':`${moveName(m)}${note.label?' '+note.label:''}, ${m.startup} startup, ${m.active} active, ${m.recovery} recovery${!m.enabled?', unused slot':''}`});
    button.append(el('strong',{},moveName(m)),el('span',{class:'move-dots','aria-label':model.changed(character,i)?'Edited':''},model.changed(character,i)?'●':''),el('small',{class:'move-category'},note.label||(!m.enabled?'Unused slot':`${m.air?'Air · ':''}${KINDS[m.category]}`)),el('span',{class:'frames'},`${m.startup} / ${m.active} / ${m.recovery}`));
    button.addEventListener('click',()=>{if(!validBeforeLeaving())return;slot=i;frame=move().startup;pendingSeek=tab==='sequence'?{tick:0}:{frame};stop();render();if($('move-dialog').open)layout.closeMoves();else document.querySelector(`[data-move="${i}"]`)?.focus({preventScroll:true});saveSelection();});fragment.append(button);matches++;
  });
  if(!matches)fragment.append(el('p',{class:'empty'},'No moves match. Try another filter or show unused slots.'));
  const scroll=list.scrollTop,left=list.scrollLeft;list.replaceChildren(fragment);list.scrollTop=scroll;list.scrollLeft=left;
}
function saveSelection(){if(storageOkay&&!bootLocked){clearTimeout(saveTimer);saveTimer=setTimeout(save,200);}}
function optionsFor(key){
  if(['followFrom','followFrom2','holdFollow','guardFollow','proximityMove'].includes(key))return [[-1,'None'],...MOVE_IDS.map((name,i)=>[i,`${moveName(model.move(character,i))}${!model.move(character,i).enabled?' · unused':''}`])];
  if(key==='artPose'||key==='finishArtPose')return [[0,key==='artPose'?'Button poses':'Same pose'],...Array.from({length:pack.limits.moves[character].artPose.max},(_,i)=>[i+1,`${i+1} · ${pack.art[character].signature_active?.frames[i]?.name??'Action '+(i+1)}`])];
  return SPECS[key].options;
}
function commit(key,value){
  const rebuild=tab==='mechanics'&&['mechanic','actionType','stanceRequired','stanceChange','enabled'].includes(key);
  if(rebuild&&!validBeforeLeaving()){if($('field-'+key))$('field-'+key).value=move()[key];return false;}
  try{model.change(character,slot,key,value);fieldError(key,'');syncSummary();listMoves();scheduleSave();
    for(const timing of ['startup','variantStartup'])if($('field-'+timing))$('field-'+timing).min=moveFieldLimit(move(),timing,pack.limits.moves[character]).min;
    if(rebuild){
      const focus=document.activeElement?.id;renderForm();$(focus)?.focus({preventScroll:true});
    }else panels.update();
    return true;
  }catch(error){fieldError(key,error.message);return false;}
}
function numberField(key){
  const spec=SPECS[key],limit=moveFieldLimit(move(),key,pack.limits.moves[character]),field=el('div',{class:'field'}),id='field-'+key;
  const label=el('label',{for:id},spec.label),wrap=el('div',{class:'input-wrap'}),input=el('input',{id,type:'number',min:limit.min/spec.scale,max:limit.max/spec.scale,step:1/spec.scale,inputmode:limit.min<0?'text':spec.scale===1?'numeric':'decimal','aria-describedby':`hint-${key} error-${key}`});
  input.value=move()[key]/spec.scale;wrap.append(input);if(spec.unit)wrap.append(el('span',{class:'unit'},spec.unit));field.append(label,wrap);
  if(spec.hint)field.append(el('small',{class:'hint',id:'hint-'+key},spec.hint));
  field.append(el('span',{class:'error',id:'error-'+key,'aria-live':'polite'}));
  input.addEventListener('input',()=>{try{const value=parseField(key,input.value,moveFieldLimit(move(),key,pack.limits.moves[character]));commit(key,value);}catch(error){fieldError(key,error.message);}});
  input.addEventListener('change',()=>{if(!errors.has(id))input.value=move()[key]/spec.scale;});
  return field;
}
function selectField(key){
  const spec=SPECS[key],field=el('div',{class:'field'}),id='field-'+key,select=el('select',{id});
  select.append(...optionsFor(key).map(([value,label])=>el('option',{value},label)));select.value=move()[key];
  field.append(el('label',{for:id},spec.label),select);if(spec.hint)field.append(el('small',{class:'hint',id:'hint-'+key},spec.hint));
  field.append(el('span',{class:'error',id:'error-'+key,'aria-live':'polite'}));
  select.addEventListener('change',()=>{if(commit(key,Number(select.value))&&['category','artPose','air'].includes(key))syncPreview();});return field;
}
function flagField(key){
  const spec=SPECS[key],field=el('div',{class:'field flag'}),id='field-'+key,input=el('input',{id,type:'checkbox',checked:!!move()[key]});
  field.append(input,el('label',{for:id},spec.label));if(spec.hint)field.append(el('small',{class:'hint'},spec.hint));input.addEventListener('change',()=>commit(key,Number(input.checked)));return field;
}
function maskField(key){
  const spec=SPECS[key],field=el('fieldset',{class:'field mask'});field.append(el('legend',{class:'field-label'},spec.label));const choices=el('div',{class:'mask-options'});field.style.borderTop=field.style.borderLeft=field.style.borderRight='0';field.style.paddingLeft=field.style.paddingRight='0';field.style.margin='0';
  const inputs=[];let unified;
  if(spec.unified){unified=el('input',{type:'checkbox',id:'field-'+key+'-unified',checked:move()[key]===-1});const label=el('label',{class:'unified-option'},'');label.append(unified,document.createTextNode('Unified'));choices.append(label);unified.addEventListener('change',()=>{commit(key,unified.checked?-1:0);for(const item of inputs){item.disabled=unified.checked;item.checked=false;}});}
  spec.mask.forEach((name,i)=>{const input=el('input',{type:'checkbox',id:`field-${key}-${i}`,checked:move()[key]>=0&&!!(move()[key]&(1<<i))});input.disabled=move()[key]===-1;const label=el('label');label.append(input,document.createTextNode(name));choices.append(label);inputs.push(input);input.addEventListener('change',()=>commit(key,inputs.reduce((mask,n,i)=>mask|(n.checked?1<<i:0),0)));});field.append(choices);if(spec.hint)field.append(el('small',{class:'hint'},spec.hint));return field;
}
function fieldControl(key){
  const type=SPECS[key].type;
  return type==='number'?numberField(key):type==='select'?selectField(key):type==='flag'?flagField(key):maskField(key);
}

function referenceSection(){
  const section=el('section',{class:'pose-references field wide','aria-labelledby':'reference-title'}),refs=model.note(character,slot).references||[];
  const heading=el('div',{class:'reference-heading'});heading.append(el('h3',{id:'reference-title'},'Pose references'),el('span',{class:'reference-count'},`${refs.length} / ${MAX_REFERENCES}`));
  section.append(heading,el('p',{},'Add a photo or pose sketch, then describe what to borrow from it. Images are included in Download JSON.'));
  const gallery=el('div',{class:'reference-gallery'});
  for(const ref of refs){
    const card=el('article',{class:'reference-card','data-reference':ref.id}),view=el('button',{type:'button',class:'reference-thumbnail','aria-label':`Enlarge pose reference: ${ref.name}`});
    const img=el('img',{src:ref.src,alt:ref.caption||ref.name});view.append(img);
    view.onclick=()=>{const current=(model.note(character,slot).references||[]).find(r=>r.id===ref.id);if(!current)return;$('reference-photo').src=current.src;$('reference-photo').alt=current.caption||current.name;$('reference-photo-caption').textContent=current.caption||current.name;$('reference-dialog').showModal();};
    const phaseId='reference-phase-'+ref.id,captionId='reference-caption-'+ref.id,phase=el('select',{id:phaseId,'data-reference-phase':ref.id}),caption=el('textarea',{id:captionId,rows:'2',maxlength:'1000',placeholder:'e.g. Borrow the shoulder angle and rear-foot placement.','data-reference-caption':ref.id});
    phase.append(...REFERENCE_PHASES.map(([value,label])=>el('option',{value},label)));phase.value=ref.phase;caption.value=ref.caption;
    const update=(key,value)=>{try{model.editReference(character,slot,ref.id,key,value);syncSummary();listMoves();scheduleSave();img.alt=key==='caption'?value||ref.name:img.alt;}catch(error){announce(error.message);const current=model.note(character,slot).references.find(r=>r.id===ref.id);phase.value=current.phase;caption.value=current.caption;}};
    phase.onchange=()=>update('phase',phase.value);caption.oninput=()=>update('caption',caption.value);
    const remove=el('button',{type:'button',class:'reference-remove','aria-label':`Remove pose reference: ${ref.name}`},'Remove photo');remove.onclick=()=>{if(referenceBusy)return;model.removeReference(character,slot,ref.id);renderForm();syncSummary();listMoves();scheduleSave();announce('Pose reference removed. Undo is available.');};
    card.append(view,el('span',{class:'reference-name',title:ref.name},ref.name),el('label',{for:phaseId},'Use for'),phase,el('label',{for:captionId},'Pose notes'),caption,remove);gallery.append(card);
  }
  if(refs.length)section.append(gallery);
  const file=el('input',{id:'reference-file',type:'file',accept:'image/png,image/jpeg,image/webp',multiple:'',hidden:''}),add=el('button',{id:'add-reference',type:'button',class:'reference-add'},'+ Add pose photo');add.disabled=refs.length>=MAX_REFERENCES;add.onclick=()=>file.click();
  const status=el('p',{id:'reference-status',class:'reference-status',role:'status'});
  file.onchange=async()=>{
    const files=Array.from(file.files||[]);if(!files.length||referenceBusy)return;
    if(refs.length+files.length>MAX_REFERENCES){status.textContent='Choose up to three references for this move.';file.value='';return;}
    referenceBusy=true;add.disabled=true;refreshActions();section.querySelectorAll('select,textarea,.reference-remove').forEach(node=>node.disabled=true);status.textContent='Preparing your pose reference…';
    try{
      const prepared=[];for(const photo of files)prepared.push(await prepareReference(photo));
      model.addReferences(character,slot,prepared);scheduleSave();announce(`${prepared.length===1?'Pose reference':'Pose references'} added. Download JSON includes the image${prepared.length===1?'':'s'}.`);
    }catch(error){status.textContent=error.message;announce(error.message);}
    finally{referenceBusy=false;refreshActions();add.disabled=(model.note(character,slot).references||[]).length>=MAX_REFERENCES;section.querySelectorAll('select,textarea,.reference-remove').forEach(node=>node.disabled=false);file.value='';}
    if((model.note(character,slot).references||[]).length>refs.length){renderForm();syncSummary();listMoves();}
  };
  section.append(add,file,el('small',{class:'reference-help'},'JPG, PNG or WebP · up to 3 per move. A smaller copy is embedded; your original stays unchanged.'),status);return section;
}
function hurtValues(rect){return {left:rect[0]/100,bottom:rect[1]/100,width:(rect[2]-rect[0])/100,height:(rect[3]-rect[1])/100};}
function visibleHurtboxes(){
  const m=move(),phase=phaseAt(m,frame),recorded=testRecord?.frames[testIndex];
  if(m.hurtboxes[phase]||m[HURT_MASK_FIELDS[phase]]!==15||!matchingRecord()||previewPending||testRecord.geometryOnly||recorded?.selectedFrame!==frame)return effectiveHurtboxes(pack,character,m,frame);
  const a=recorded.state.players[0];
  return Object.fromEntries(recorded.boxes[0].hurt.map((b,i)=>[HURT_REGIONS[i],a.facing===1?[b[0]-a.x,b[1]-a.y,b[2]-a.x,b[3]-a.y]:[a.x-b[2],b[1]-a.y,a.x-b[0],b[3]-a.y]]));
}
function syncHurtFields(){
  if(tab!=='hurt')return;const rect=visibleHurtboxes()[hurtRegion];if(!rect)return;
  for(const [key,value]of Object.entries(hurtValues(rect))){const input=$('field-hurt-'+key);if(input&&document.activeElement!==input)input.value=value;}
}
function extensionForm(section=tab){return renderExtension({el,character:model.data.characters[character],slot,tab:section,frame,
  onError:fieldError,onSeek:value=>{seekMove(value);renderForm();},
  onMove:index=>{if(!validBeforeLeaving())return;slot=index;frame=move().startup;pendingSeek={frame};stop();render();saveSelection();},
  onChange:next=>{model.change(character,slot,'extensions',next,'');stop();renderForm();syncSummary();listMoves();scheduleSave();},
  onCharacterChange:next=>{const before=model.snapshot();model.data.characters[character].extensions=next;try{validate(model.data,pack);}catch(e){model.data=before;throw e;}model.remember(before);stop();renderForm();syncSummary();scheduleSave();}
});}
function hurtForm(){
  const m=move();hurtPhase=phaseAt(m,frame);const custom=!!m.hurtboxes[hurtPhase],boxes=visibleHurtboxes();
  if(!boxes[hurtRegion])hurtRegion='torsoArms';
  const section=el('section',{class:'form-section hurt-editor'});section.append(el('h2',{},'Body hurtboxes'),el('p',{},'Edit this attack’s body coverage for each phase. Other moves that share its sprite keep their own boxes.'));
  const phase=el('select',{id:'hurt-phase'});phase.append(...HURT_PHASES.map(p=>{const option=el('option',{value:p},p==='windup'?`Windup · ${m.startup-1}f`:p==='active'?`Active · ${m.active}f`:`Recovery · ${m.recovery}f`);option.disabled=p==='recovery'&&!m.recovery;return option;}));phase.value=hurtPhase;
  phase.onchange=()=>{if(!validBeforeLeaving()){phase.value=hurtPhase;return;}seekMove(phaseStart(m,phase.value));saveSelection();};
  const enable=el('input',{id:'hurt-custom',type:'checkbox',checked:custom}),enableRow=el('div',{class:'hurt-toggle'});enableRow.append(enable,el('label',{for:'hurt-custom'},'Custom boxes for this phase'));
  enable.onchange=()=>{if(!validBeforeLeaving()){enable.checked=custom;return;}stop();model.setHurtPhase(character,slot,hurtPhase,enable.checked?visibleHurtboxes():null);renderForm();syncSummary();listMoves();scheduleSave();};
  section.append(el('label',{for:'hurt-phase',class:'field-label'},'Attack phase'),phase,enableRow,el('p',{class:'hurt-status'},custom?'Custom profile · saved with this move':'Using the sprite pose. Enable custom boxes to make changes.'));
  const vulnerability=el('fieldset',{class:'hurt-vulnerability',id:'hurt-vulnerability'});vulnerability.append(el('legend',{},'Regions that can be hit'));
  for(const region of HURT_REGIONS){
    const id='hurt-enabled-'+region,check=el('input',{id,type:'checkbox',checked:regionEnabled(m,hurtPhase,region)}),row=el('div',{class:'hurt-toggle'});
    check.disabled=!boxes[region];row.append(check,el('label',{for:id},HURT_LABELS[region]));vulnerability.append(row);
    check.onchange=()=>{if(!validBeforeLeaving()){check.checked=regionEnabled(m,hurtPhase,region);return;}stop();const field=HURT_MASK_FIELDS[hurtPhase],bit=1<<HURT_REGIONS.indexOf(region);model.change(character,slot,field,check.checked?move()[field]|bit:move()[field]&~bit,'');renderForm();syncSummary();listMoves();scheduleSave();};
  }
  vulnerability.append(el('p',{class:'hurt-guidance'},'Uncheck a region to protect it during this phase. Its size is kept. 6P starts with only Legs enabled during windup and active frames; recovery restores the full body.'));
  section.append(vulnerability);
  const region=el('select',{id:'hurt-region'});region.append(...HURT_REGIONS.filter(r=>boxes[r]).map(r=>el('option',{value:r},HURT_LABELS[r])));region.value=hurtRegion;
  region.onchange=()=>{if(!validBeforeLeaving()){region.value=hurtRegion;return;}stop();hurtRegion=region.value;renderForm();syncPreview();};
  section.append(el('label',{for:'hurt-region',class:'field-label'},'Selected body box'),region);
  const grid=el('div',{class:'field-grid hurt-grid'}),values=hurtValues(boxes[hurtRegion]);
  for(const [key,label]of [['left','Left position'],['bottom','Bottom position'],['width','Width'],['height','Height']]){
    const id='field-hurt-'+key,field=el('div',{class:'field'}),wrap=el('div',{class:'input-wrap'}),input=el('input',{id,type:'number',min:key==='width'||key==='height'?1:-500,max:key==='width'||key==='height'?1000:500,step:'0.01',inputmode:key==='width'||key==='height'?'decimal':'text','aria-describedby':'error-hurt-'+key});input.value=values[key];input.disabled=!custom;
    wrap.append(input,el('span',{class:'unit'},'px'));field.append(el('label',{for:id},label),wrap,el('span',{id:'error-hurt-'+key,class:'error','aria-live':'polite'}));grid.append(field);
    input.oninput=()=>{
      try{
        if(!input.value.trim())throw new Error('Enter a coordinate or size.');
        const raw=Number(input.value)*100,value=Math.round(raw);if(!Number.isFinite(raw)||Math.abs(raw-value)>1e-6)throw new Error('Use up to two decimal places.');
        const next=clone(move().hurtboxes[hurtPhase]),b=next[hurtRegion];
        if(key==='left'){b[2]+=value-b[0];b[0]=value;}else if(key==='bottom'){b[3]+=value-b[1];b[1]=value;}else if(key==='width')b[2]=b[0]+value;else b[3]=b[1]+value;
        stop();model.setHurtPhase(character,slot,hurtPhase,next,`hurt/${character}/${slot}/${hurtPhase}/${hurtRegion}/${key}`);fieldError('hurt-'+key,'');syncSummary();listMoves();scheduleSave();
      }catch(error){fieldError('hurt-'+key,error.message);}
    };
  }
  const extension=el('input',{id:'hurt-extension',type:'checkbox',checked:!!boxes.extension});extension.disabled=!custom;const extensionRow=el('div',{class:'hurt-toggle'});extensionRow.append(extension,el('label',{for:'hurt-extension'},'Include body extension · fourth box'));
  extension.onchange=()=>{if(!validBeforeLeaving()){extension.checked=!!boxes.extension;return;}stop();const next=clone(move().hurtboxes[hurtPhase]);if(extension.checked){next.extension=[...next.torsoArms];hurtRegion='extension';}else{delete next.extension;if(hurtRegion==='extension')hurtRegion='torsoArms';}model.setHurtPhase(character,slot,hurtPhase,next);renderForm();syncSummary();listMoves();scheduleSave();};
  section.append(grid,extensionRow,el('p',{class:'hurt-guidance'},'Keep legs, torso & arms, and head on the body. The optional extension starts over the torso; move it onto an extended limb. Weapon reach adds no hurtbox. Disable custom boxes to restore the sprite profile for this phase.'));
  section.addEventListener('focusin',()=>{if(playing){stop();syncPreview();}});return section;
}
function artForm(){
  const container=el('section',{class:'form-section'});container.append(el('h2',{},'Give the attack a direction.'),el('p',{class:'art-intro'},'These notes travel with your JSON. Use them to brief new windup and active poses after the move feels right.'));
  const grid=el('div',{class:'field-grid'}),note=model.note(character,slot);
  for(const [key,label,placeholder,max] of ART_FIELDS){
    const id='note-'+key,field=el('div',{class:'field wide'}),input=el(key==='label'?'input':'textarea',{id,...(key==='label'?{type:'text'}:{rows:'3'}),placeholder,maxlength:max});input.value=note[key]||'';field.append(el('label',{for:id},label),input);grid.append(field);
    input.addEventListener('input',()=>{try{model.setNote(character,slot,key,input.value);syncSummary();if(key==='label')listMoves();scheduleSave();}catch(error){input.value=model.note(character,slot)[key]||'';announce(error.message);}});
    if(key==='intent')grid.append(referenceSection());
  }
  const exportBrief=el('button',{type:'button',class:'art-export'},'Download art brief');exportBrief.addEventListener('click',()=>download(model.brief(),'FightGuild-art-brief-'+date()+'.md','text/markdown;charset=utf-8'));container.append(grid,exportBrief);return container;
}
function renderForm(){
  panels.begin();buildForm();panels.update();$('field-view').value=panels.all?'all':'relevant';$('field-view').hidden=tab==='sequence';
}
function slashDescription(){return `c.S at root spacing ≤ ${model.move(character,2).proximityRange/100} px; f.S beyond it. c.S → f.S or 2S on contact with unified routes. The close attack must be enabled.`;}
function slashForm(){
  const far=model.move(character,2),close=model.move(character,32),view=el('section',{class:'slash-pair form-section','aria-label':'Close and far Slash'});
  view.append(el('h2',{},'Standing S · close / far'),el('p',{id:'slash-description'},slashDescription()));
  const actions=el('div',{class:'track-actions slash-actions'});
  const choose=index=>{slot=index;frame=move().startup;pendingSeek={frame};stop();render();saveSelection();};
  for(const [index,name]of [[32,'c.S'],[2,'f.S']]){
    const edit=el('button',{type:'button','data-slash-edit':index},`Edit ${name}`);edit.onclick=()=>{if(validBeforeLeaving())choose(index);};actions.append(edit);
    const test=el('button',{type:'button','data-slash-test':index},`Test ${name} spacing`);test.onclick=()=>{
      if(!validBeforeLeaving())return;
      const target=Number($('test-target').value),body=pack.collisions[character].push.halfWidth+pack.collisions[target].push.halfWidth;
      const gap=(far.proximityRange-body)/100;
      $('test-gap').value=Math.max(0,index===32?Math.floor(gap)-1:Math.floor(gap)+1);
      $('test-entry').value='standing';choose(index);$('test-gap').dispatchEvent(new Event('change'));
    };actions.append(test);
  }
  view.append(actions);
  const warning=el('p',{id:'slash-warning',class:'hint'},'Enable c.S and select it as the close-distance version of f.S to use the pair.');
  warning.hidden=!!close.enabled&&far.proximityMove===32;view.append(warning);
  if(slot===32)view.append(el('p',{class:'hint'},'The proximity threshold belongs to f.S under Inputs & cancels → Close-distance version.'));
  return view;
}
function buildForm(){
  if(tab==='sequence'){
    $('form').setAttribute('aria-labelledby','tab-sequence');
    $('form').replaceChildren(renderSequence({el,moves:model.data.characters[character].moves,queue:model.sequence(character),slot,valid:validBeforeLeaving,onError:fieldError,
      onChange:(queue,render=true,group='')=>{
        try{model.setSequence(character,queue,group);}catch(error){announce(error.message);renderForm();return;}
        stop();pendingSeek=render?{tick:0}:{tick:testIndex};if(render)renderForm();syncSummary();scheduleSave();
      },
      onSeek:i=>{const tick=testRecord?.steps?.[i]?.start;if(tick===undefined)return;stop();testIndex=tick;drawTest();}
    }));if(matchingRecord())showSequenceResult(testRecord,testIndex);return;
  }
  if(tab==='movement'){
    $('form').setAttribute('aria-labelledby','tab-movement');
    $('form').replaceChildren(renderMovement({el,panels,profile:model.data.characters[character].movement,limits:pack.limits.movement[character],onError:fieldError,action:movementAction,onAction:value=>{if(!validBeforeLeaving())return;movementAction=value;pendingSeek={tick:0};stop();syncPreview();},onChange:(key,value)=>{model.changeMovement(character,key,value);syncSummary();panels.update();scheduleSave();}}));if(model.data.characters[character].extensions)$('form').append(extensionForm());return;
  }
  const form=$('form');form.setAttribute('aria-labelledby','tab-'+tab);
  const ignored=move().extensions?['normalRoutes','commandRoutes','specialCancel','whiffCancel','selfCancel','advance','semiAirStart','semiAirEnd']:[];
  const groups=TABS.find(t=>t.id===tab).groups.map(id=>GROUPS.find(g=>g.id===id)).map(g=>({...g,fields:g.fields.filter(f=>!ignored.includes(f))})).filter(g=>g.fields.length);
  if(tab==='art'){form.replaceChildren(...groups.map(g=>panels.create(g,fieldControl)),artForm());return;}
  if(tab==='hurt'){form.replaceChildren(move().extensions?extensionForm():hurtForm(),...groups.filter(g=>g.id!=='vulnerability').map(g=>panels.create(g,fieldControl)));return;}
  if(tab==='mechanics'&&model.data.characters[character].extensions){form.replaceChildren(extensionForm());return;}
  if(tab==='mechanics'){
    form.replaceChildren(renderDrive({el,character:model.data.characters[character],slot,note:index=>model.note(character,index),panels,field:fieldControl,
      onMove:index=>{if(!validBeforeLeaving())return;slot=index;frame=move().startup;pendingSeek={frame};stop();render();saveSelection();document.querySelector(`[data-drive-move="${index}"]`)?.focus({preventScroll:true});},
      onTab:selectTab,testMode:$('test-mechanic').value,onTest:mode=>{if(!validBeforeLeaving())return;$('test-mechanic').value=mode;$('test-mechanic').dispatchEvent(new Event('change'));}
    }));return;
  }
  const nodes=groups.map(group=>panels.create(group,fieldControl));
  if(tab==='timing')nodes.push(comboRuleForm());
  if(move().extensions&&['routes','hit'].includes(tab))nodes.unshift(extensionForm());
  if(['timing','routes'].includes(tab)&&[2,32].includes(slot))nodes.unshift(slashForm());
  if(tab==='hit'&&move().mechanic!==4)nodes.unshift(renderHitEditor({move:move(),frame,pack,character,boxIndex:hitBox,selectedFrame:hitKeyFrame,
    valid:validBeforeLeaving,onError:fieldError,onKey:value=>{hitKeyFrame=value;seekMove(value===null?frame:move().startup+Math.min(Math.max(1,value),move().active)-1);},
    onBox:value=>{hitBox=value;renderForm();syncPreview();},
    onChange:(track,render=true,group='')=>{model.setHitTimeline(character,slot,track,group);stop();if(render)renderForm();syncSummary();listMoves();scheduleSave();}
  }));
  if(move().mechanic===4&&['hit','projectiles'].includes(tab))nodes.unshift(el('p',{class:'panel-intro'},'Reel In has no strike hitbox or projectile. Set its duration, range and stopping gap in Drive system. The opponent can act unless already in hitstun or blockstun.'));
  if(move().mechanic===5&&['hit','projectiles'].includes(tab))nodes.unshift(el('p',{class:'panel-intro'},'Break Step has no strike or projectile. Edit its travel, enhanced-normal bonus and reset in Drive system.'));
  form.replaceChildren(...nodes);
}
function selectTab(id){
  if(!validBeforeLeaving()){$('section-picker').value=tab;return;}
  stop();tab=id;hitKeyFrame=null;if(tab==='sequence')pendingSeek={tick:0};
  if(tab==='hurt'){preview.options.hurt=true;$('show-hurt').checked=true;}
  renderTabs();renderForm();syncSummary();saveSelection();
  (matchMedia('(max-width: 1000px)').matches?$('section-picker'):$('tab-'+tab)).focus({preventScroll:true});
}
function renderTabs(){
  $('section-picker').replaceChildren(...TABS.map(t=>el('option',{value:t.id},t.label)));$('section-picker').value=tab;
  $('tabs').replaceChildren(...TABS.map(t=>{const button=el('button',{id:'tab-'+t.id,type:'button',role:'tab','aria-selected':String(t.id===tab),'aria-controls':'form',tabindex:t.id===tab?'0':'-1'},t.label);
    button.addEventListener('click',()=>selectTab(t.id));
    button.addEventListener('keydown',event=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;event.preventDefault();const index=TABS.indexOf(t),next=event.key==='Home'?0:event.key==='End'?TABS.length-1:(index+(event.key==='ArrowRight'?1:-1)+TABS.length)%TABS.length;$('tab-'+TABS[next].id).click();});return button;}));
}
function render(){hitKeyFrame=null;errors.clear();$('fighter').value=character;listMoves();renderTabs();renderForm();syncSummary();
  const list=$('move-list'),selected=list.querySelector('[aria-current="true"]');if(selected){const r=selected.getBoundingClientRect(),b=list.getBoundingClientRect();
    if(r.top<b.top)list.scrollTop+=r.top-b.top;else if(r.bottom>b.bottom)list.scrollTop+=r.bottom-b.bottom;
    if(r.left<b.left)list.scrollLeft+=r.left-b.left;else if(r.right>b.right)list.scrollLeft+=r.right-b.right;
  }
}
function variantMove(m,variant){return variant?{...m,startup:m.variantStartup,active:m.variantActive,recovery:m.variantRecovery}:m;}
function drawTimeline(m,variant=0){
  $('windup-time').textContent=`Windup ${m.startup-1}f`;$('active-time').textContent=`Active ${m.active}f`;$('recovery-time').textContent=`Recovery ${m.recovery}f`;
  const phases=[['windup',m.startup-1,1],['active',m.active,m.startup],['recovery',m.recovery,m.startup+m.active]];
  $('timeline').hidden=tab==='movement'||tab==='sequence';document.querySelector('.phase-labels').hidden=$('timeline').hidden;
  const key=JSON.stringify([m.startup,m.active,m.recovery,variant]);
  if($('timeline').dataset.timing===key)return;
  $('timeline').dataset.timing=key;
  $('timeline').replaceChildren(...phases.filter(([,length])=>length).map(([name,length,start])=>{const b=el('button',{type:'button',class:name,'aria-label':`Jump to ${name}: ${length} frames`,title:`${name}: ${length}f`});b.style.flex=length;b.addEventListener('click',()=>{if(!validBeforeLeaving())return;hitKeyFrame=null;seekMove(start,variant);});return b;}));
}
function syncPreview(){
  const f=matchingRecord()?testRecord.frames[testIndex]:null,variant=f?.selectedFrame?f.state.players[0].variant:0,m=variantMove(move(),variant);
  frame=Math.max(1,Math.min(totalFrames(m),frame));drawTimeline(m,variant);scheduleTest();
}
function stop(){playing=false;$('play').setAttribute('aria-label',tab==='sequence'?'Play sequence':'Play attack');}
function testOptions(){return {bleed:$('test-bleed').value,mechanic:$('test-mechanic').value,target:Number($('test-target').value),behavior:$('test-behavior').value,entry:$('test-entry').value,gap:Number($('test-gap').value),facing:Number($('test-facing').value),simple:$('test-simple').value==='1',movement:tab==='movement'?movementAction:null,sequence:tab==='sequence'?model.sequence(character):null};}
function matchingRecord(){return testRecord?.character===character&&testRecord?.slot===slot&&!!testRecord.movement===(tab==='movement')&&!!testRecord.sequence===(tab==='sequence');}
function seekMove(value,variant=0){
  stop();frame=Math.max(1,Math.min(totalFrames(variantMove(move(),variant)),value));pendingSeek={frame,variant};
  renderForm();syncPreview();
}
function scheduleTest(){
  if(dragBefore||hurtDragBefore){drawTest();return;}
  const {_moveWorkshop,...gameplay}=model.data,signature=JSON.stringify([character,slot,gameplay,testOptions()]);
  if(signature===recordSignature&&matchingRecord()){
    clearTimeout(testTimer);testSignature=signature;previewPending=false;
    if(pendingSeek){testIndex=cursorIndex(testRecord,pendingSeek);pendingSeek=null;}
    drawTest();return;
  }
  if(signature===testSignature&&previewPending){drawTest();return;}
  pendingSeek??=matchingRecord()?cursorAnchor(testRecord,testIndex):{frame:move().startup};
  stop();clearTimeout(testTimer);testSignature=signature;previewPending=true;
  if(matchingRecord())drawTest();else preview.clear();
  $('play').disabled=true;$('test-readout').textContent='Updating exchange…';
  testTimer=setTimeout(()=>{
    try{
      testRecord=tab==='sequence'?combatPreview.recordSequence(model.data,character,slot,model.sequence(character),testOptions()):tab==='movement'?combatPreview.recordMovement(model.data,character,slot,movementAction,testOptions()):combatPreview.record(model.data,character,slot,testOptions());recordSignature=signature;
      testIndex=cursorIndex(testRecord,pendingSeek||{frame:move().startup});pendingSeek=null;previewPending=false;drawTest();
    }catch(error){testRecord=null;testSignature='';previewPending=false;preview.clear();$('test-readout').textContent='Preview could not run: '+error.message;}
  },80);
}
function drawTest(){
  if(!matchingRecord())return;
  testIndex=Math.min(testIndex,testRecord.frames.length-1);const f=testRecord.frames[testIndex],a=f.state.players[0],target=f.state.players[1],m=testRecord.sequence?testRecord.moves[f.moveSlot]||move():move(),oldFrame=frame;
  if(f.selectedFrame&&!previewPending&&!pendingSeek)frame=f.selectedFrame;
  const displayed=variantMove(m,f.selectedFrame?a.variant:0);drawTimeline(displayed,f.selectedFrame?a.variant:0);
  const phase=phaseAt(displayed,frame),key=keyAt(m,Math.max(1,frame-m.startup+1)),keyIndex=m.hitboxTimeline.keys.indexOf(key);
  if(!previewPending&&!dragBefore&&!hurtDragBefore&&((tab==='hurt'&&hurtPhase!==phase)||(tab==='hit'&&hitKeyFrame===null&&keyAt(m,Math.max(1,oldFrame-m.startup+1))!==key)))renderForm();
  const editable=!a.variant&&tab!=='movement'&&tab!=='sequence'&&!playing&&(!previewPending||dragBefore||hurtDragBefore)&&!!f.selectedFrame;
  preview.show(testRecord,testIndex,m,{
    hit:editable&&m.mechanic<4&&tab==='hit'&&(hitKeyFrame===null||hitKeyFrame===key?.frame),
    hitKey:key&&key.boxes!==null?{keyIndex,boxIndex:Math.min(hitBox,Math.max(0,key.boxes.length-1))}:null,
    hurt:editable&&tab==='hurt'?{phase,region:hurtRegion,custom:!!m.extensions||!!m.hurtboxes[phase]}:null
  });
  $('frame').max=testRecord.frames.length-1;$('frame').value=testIndex;$('frame-label').textContent=`${testIndex} / ${testRecord.frames.length-1}`;
  $('play').disabled=previewPending||testRecord.frames.length<2;
  $('preview-title').textContent=testRecord.sequence?f.stage:testRecord.movement?f.stage:a.grabTime?`${m.finishArtPose&&a.poseIndex===m.finishArtPose-1?'Finish':'Capture'} · ${m.grabFrames-a.grabTime+1} / ${m.grabFrames}f`:f.selectedFrame?`${a.variant===1?'Pull · ':a.variant===2?'Cash-out · ':''}${phase==='windup'?'Windup':phase==='active'?'Active':'Recovery'} · frame ${f.selectedFrame}`:'Attack workspace';
  $('test-readout').textContent=previewPending?'Updating exchange…':`${testRecord.geometryOnly?'Geometry only':`Input ${describeInput(f.input,a.facing)}`} · ${f.selectedFrame?'move frame '+f.selectedFrame:f.stage}${f.state.hitstop?' · freeze '+f.state.hitstop+'f':''} · target ${target.stun}f stun`;
  if(!previewPending){
    if(f.state.pairKind)$('test-readout').textContent+=` · ${['','Throw','Cashout','Wound','Throw-tech gate'][f.state.pairKind]} C${f.state.pairClock}`;
    if(a.pairRecovery||target.pairRecovery)$('test-readout').textContent+=` · release recovery ${a.pairRecovery}/${target.pairRecovery}f`;
    if(target.tetherTime)$('test-readout').textContent+=` · line ${target.tetherTime}f`;
    if(target.linePullTime)$('test-readout').textContent+=` · pull ${target.linePullTime}f · ${target.linePullHeld?'existing stun held':'free to act'}`;
    if(target.bleedTime)$('test-readout').textContent+=` · bleed ${target.bleedTime}f / ${target.greyLife} grey`;
    if(a.captureFailed)$('test-readout').textContent+=' · capture attempt failed';
  }
  const contacts=testRecord.contacts.filter(c=>c.tick<=testIndex),hits=contacts.filter(c=>c.event!==2).length;
  $('test-result').textContent=previewPending?'Recalculating contact…':`${hits} hit${hits===1?'':'s'} · ${contacts.length-hits} blocks · ${1000-target.health} damage · decay ${target.comboDecay} · launch ${target.launchPercent}% · attacker travel ${((a.x-testRecord.frames[0].state.players[0].x)/100).toFixed(1)}px`;
  $('test-warning').textContent=testRecord.warnings.join(' ');$('test-warning').hidden=!testRecord.warnings.length;
  showSequenceResult(testRecord,testIndex);
  $('geometry-help').textContent=testRecord.sequence?'Play or scrub the full sequence, or tap a step’s frame to inspect its start. Edit each attack in its own section; this test uses its current values.':a.variant&&f.selectedFrame?'Follow-up timing is shown here. Edit its range and movement in Drive mechanics; phase hurtboxes inherit from the applying move.':testRecord.movement?'Play or scrub the movement here. Edit the character profile alongside this preview.':playing?'Pause or scrub to edit boxes directly on the fighter.':!f.selectedFrame?'Use Windup, Active or Recovery to jump to an editable attack frame.':tab==='hurt'?'Enable custom boxes, choose a body region and drag its blue handles. Changes update this same exchange.':tab==='hit'&&m.mechanic===5?'Break Step has no hitbox. Edit movement and pressure reward in Drive system.':tab==='hit'&&m.mechanic===4?'Reel In has no hitbox. Edit pull duration, range and gap in Drive system.':tab==='hit'?'On active frames, drag the selected orange box or its edges. Edits keep this move frame while recalculating contact.':'Play, pause or scrub here. Open Hit & movement or Hurtboxes to edit directly on the fighter.';
}
function animate(time){
  if(playing&&testRecord&&!previewPending){if(!lastTick)lastTick=time;const step=1000/(60*Number($('test-speed').value)),advance=Math.floor((time-lastTick)/step);if(advance){testIndex=Math.min(testRecord.frames.length-1,testIndex+advance);lastTick+=advance*step;if(testIndex===testRecord.frames.length-1)stop();drawTest();}}
  requestAnimationFrame(animate);
}
function syncVisibleFields(){for(const [key,spec]of Object.entries(SPECS)){const input=$('field-'+key);if(input&&spec.type==='number'&&document.activeElement!==input)input.value=move()[key]/spec.scale;}}
const preview=new Preview($('preview'),pack,(phase,patch)=>{
  if(phase==='start'){if(!validBeforeLeaving())return false;dragBefore=model.snapshot();stop();}
  if(phase==='change'&&dragBefore){
    if(patch.keyIndex!==undefined){
      const track=clone(move().hitboxTimeline);track.keys[patch.keyIndex].boxes[patch.boxIndex]=patch.rect;
      try{validateHitTimeline(track);}catch{return;}
      move().hitboxTimeline=track;
      const b=patch.rect,values={left:b[0]/100,bottom:b[1]/100,width:(b[2]-b[0])/100,height:(b[3]-b[1])/100};
      for(const [key,value]of Object.entries(values))if($('field-hit-key-'+key))$('field-hit-key-'+key).value=value;
      syncSummary();return;
    }
    const limits=pack.limits.moves[character];for(const [key,value]of Object.entries(patch))if(value<limits[key].min||value>limits[key].max)return;
    const candidate={...move(),...patch};if(candidate.hitboxBack>=candidate.reach||candidate.height<100)return;
    Object.assign(move(),patch);syncVisibleFields();syncSummary();
  }
  if(phase==='end'&&dragBefore){model.remember(dragBefore);dragBefore=null;listMoves();refreshActions();scheduleSave();syncPreview();}
},(stage,patch)=>{
  if(stage==='start'){if(!validBeforeLeaving())return false;hurtDragBefore=model.snapshot();stop();}
  if(stage==='change'&&hurtDragBefore){
    if(move().extensions){const next=clone(move().extensions),key=next.hurtboxes.findLast(k=>k.frame<=frame);if(!key)return;key.boxes[patch.region]=patch.rect;move().extensions=next;syncHurtFields();syncSummary();return;}
    const next=clone(move().hurtboxes[patch.phase]);next[patch.region]=patch.rect;
    try{validateHurtboxes({[patch.phase]:next});}catch{return;}
    move().hurtboxes[patch.phase]=next;syncHurtFields();syncSummary();
  }
  if(stage==='end'&&hurtDragBefore){model.remember(hurtDragBefore);hurtDragBefore=null;listMoves();refreshActions();scheduleSave();syncPreview();}
});
function start(data=pack.draft?.data??pack.defaults,selection={}){
  model=new Workshop(pack,data);character=Number.isInteger(selection.character)&&selection.character>=0&&selection.character<6?selection.character:5;
  slot=Number.isInteger(selection.slot)&&selection.slot>=0&&selection.slot<MOVE_IDS.length?selection.slot:0;tab=TABS.some(t=>t.id===selection.tab)?selection.tab:'timing';frame=move().startup;pendingSeek=tab==='sequence'?{tick:0}:{frame};
  $('fighter').replaceChildren(...[5,4,0,1,2,3].map(i=>el('option',{value:i},CHARACTERS[i])));$('fighter').disabled=false;render();
  $('save-status').textContent=data===pack.draft?.data?pack.draft.label+' · work in progress':storageOkay?'Saved on this device only':'Download to keep your edits';
}
function initialize(){
  try{
    const raw=localStorage.getItem(STORAGE);
    if(raw){try{const saved=JSON.parse(raw);if(saved.format!==1)throw new Error('Unknown saved-draft format');validate(saved.data,pack);start(saved.data,saved.selection);return;}catch(error){
      recoveryRaw=raw;bootLocked=true;start();$('fighter').disabled=true;$('form').inert=true;
      banner('The saved draft could not be opened. Download it for recovery, or explicitly start a new draft.');
      const recover=el('button',{type:'button'},'Download saved draft');recover.onclick=()=>download(recoveryRaw,'FightGuild-draft-recovery-'+date()+'.json','application/json');
      const reset=el('button',{type:'button'},'Start a new draft');reset.onclick=()=>{bootLocked=false;$('form').inert=false;$('storage-warning').hidden=true;start();save();};$('storage-warning').append(recover,reset);refreshActions();return;
    }}
  }catch{storageOkay=false;}
  start();if(!storageOkay)banner('Browser storage is unavailable. Download JSON to keep your work before closing the page.');
}
$('fighter').addEventListener('change',()=>{if(!validBeforeLeaving()){$('fighter').value=character;return;}character=Number($('fighter').value);slot=0;frame=move().startup;pendingSeek=tab==='sequence'?{tick:0}:{frame};stop();$('search').value='';render();saveSelection();});
$('search').addEventListener('input',listMoves);$('show-unused').addEventListener('change',listMoves);
for(const button of document.querySelectorAll('[data-filter]'))button.addEventListener('click',()=>{filter=button.dataset.filter;for(const b of document.querySelectorAll('[data-filter]')){b.classList.toggle('selected',b===button);b.setAttribute('aria-pressed',String(b===button));}listMoves();});
$('undo').onclick=()=>{stop();if(errors.size){errors.clear();render();announce('Invalid input discarded.');return;}if(model.undo()){frame=Math.min(frame,totalFrames(move()));render();scheduleSave();announce('Edit undone.');}};
$('redo').onclick=()=>{if(!validBeforeLeaving())return;if(model.redo()){stop();render();scheduleSave();announce('Edit restored.');}};
$('reset').onclick=()=>{errors.clear();if(tab==='sequence')model.setSequence(character,[]);else if(tab==='movement')model.resetMovement(character);else model.resetMove(character,slot);stop();frame=move().startup;pendingSeek=tab==='sequence'?{tick:0}:{frame};render();scheduleSave();announce(tab==='sequence'?'Sequence cleared. Undo is available.':'Move stats, hitbox keys and hurtboxes reset. Art notes are kept. Undo is available.');};
$('import').onclick=()=>{if(validBeforeLeaving())$('import-file').click();};
$('import-file').onchange=async event=>{
  const file=event.target.files[0];if(!file)return;
  try{if(file.size>MAX_IMPORT_BYTES)throw new Error('Choose a move JSON file smaller than 32 MB.');const data=JSON.parse(await file.text());model.import(data);bootLocked=false;$('form').inert=false;$('fighter').disabled=false;errors.clear();stop();frame=move().startup;pendingSeek=tab==='sequence'?{tick:0}:{frame};render();scheduleSave();announce('Move data imported. Undo returns to your previous draft.');}
  catch(error){announce('Import stopped: '+error.message);}finally{event.target.value='';}
};
$('export').onclick=()=>{if(!validBeforeLeaving())return;try{download(model.export(),'FightGuild-moves-'+date()+'.json','application/json');save();unexported=false;announce('JSON downloaded. Import it in the Godot move editor or send it back for the sprite pass.');}catch(error){announce(error.message);}};
$('frame').addEventListener('input',()=>{if(!validBeforeLeaving()){$('frame').value=testIndex;return;}stop();hitKeyFrame=null;const tick=Number($('frame').value);if(previewPending)pendingSeek={tick};else{testIndex=tick;drawTest();}renderForm();});
$('play').onclick=()=>{if(!validBeforeLeaving()||!testRecord||previewPending)return;if(testIndex===testRecord.frames.length-1)testIndex=0;playing=!playing;hitKeyFrame=null;lastTick=0;$('play').setAttribute('aria-label',(playing?'Pause ':'Play ')+(tab==='sequence'?'sequence':'attack'));drawTest();};
$('restart').onclick=()=>{if(!validBeforeLeaving())return;stop();hitKeyFrame=null;pendingSeek={tick:0};syncPreview();renderForm();};
$('form').addEventListener('focusin',()=>{if(playing){stop();drawTest();}});
for(const key of ['hit','hurt','push','art','distances'])$('show-'+key).onchange=()=>{preview.options[key]=$('show-'+key).checked;if(key==='distances')$('preview').classList.toggle('with-distances',preview.options.distances);preview.draw();};
$('help').onclick=()=>{$('help-dialog').showModal();};$('close-help').onclick=()=>{$('help-dialog').close();};
$('close-reference').onclick=()=>$('reference-dialog').close();
$('reference-dialog').addEventListener('close',()=>{$('reference-photo').removeAttribute('src');});
$('help-dialog').addEventListener('click',event=>{if(event.target===$('help-dialog')){const r=event.target.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)event.target.close();}});
window.addEventListener('keydown',event=>{if((event.ctrlKey||event.metaKey)&&event.key.toLowerCase()==='s'){event.preventDefault();$('export').click();}if((event.ctrlKey||event.metaKey)&&event.key.toLowerCase()==='z'&&!['INPUT','TEXTAREA','SELECT'].includes(event.target.tagName)){event.preventDefault();$(event.shiftKey?'redo':'undo').click();}});
window.addEventListener('pagehide',()=>{if(savePending)save();});
window.addEventListener('beforeunload',event=>{if(referenceBusy||errors.size||!storageOkay&&unexported){event.preventDefault();event.returnValue='';}});
window.addEventListener('storage',event=>{if(event.key===STORAGE&&event.newValue){banner('This draft was saved in another tab. Download your current JSON before switching tabs to keep both versions.');}});
// Read-only inspection used by browser integration checks and JSON round trips.
globalThis.moveWorkshop={data:()=>model.snapshot(),selection:()=>({character,slot,tab}),version:pack.defaults.coreVersion};
$('test-target').append(...CHARACTERS.map((name,i)=>el('option',{value:i},name)));$('test-target').value='4';
$('attack-enabled').onchange=()=>{if(!validBeforeLeaving()){$('attack-enabled').checked=!!move().enabled;return;}commit('enabled',Number($('attack-enabled').checked));if($('field-enabled'))$('field-enabled').checked=!!move().enabled;};
for(const id of ['test-target','test-behavior','test-entry','test-gap','test-facing','test-simple','test-mechanic','test-bleed'])$(id).onchange=()=>{if(!validBeforeLeaving())return;const gap=Number($('test-gap').value);if(!Number.isInteger(gap)||gap<0||gap>450){$('test-gap').value='24';announce('Use a whole starting gap from 0 to 450 px.');}layout.update(CHARACTERS[character],moveName(move()),model.note(character,slot).label);testSignature='';scheduleTest();for(const button of document.querySelectorAll('[data-drive-test]'))button.setAttribute('aria-pressed',String(button.dataset.driveTest===$('test-mechanic').value));};
globalThis.moveWorkshop.preview=()=>testRecord;
globalThis.moveWorkshop.cursor=()=>({index:testIndex,frame:testRecord?.frames[testIndex]?.selectedFrame||0,pending:previewPending});
globalThis.moveWorkshop.geometry=()=>({handles:clone(preview.handles),view:clone(preview.view||{}),measurements:clone(preview.measurements||null),measurementLabels:clone(preview.measurementLabels||[])});
const panels=new FieldPanels({el,move,character:()=>model.data.characters[character],context:()=>`${character}/${slot}/${tab}`,valid:validBeforeLeaving});
const layout=createLayout({canNavigate:validBeforeLeaving,onOpenMoves:stop,onSection:selectTab});
$('field-view').onchange=()=>{if(!validBeforeLeaving()){$('field-view').value=panels.all?'all':'relevant';return;}panels.setAll($('field-view').value==='all');renderForm();};
createSettingSearch({el,onFind:entry=>{
  if(!validBeforeLeaving())return false;selectTab(entry.tab);
  if(entry.key?.startsWith('hurtMask')){const phase=entry.key==='hurtMaskWindup'?'windup':entry.key==='hurtMaskActive'?'active':'recovery';seekMove(phaseStart(move(),phase));}
  panels.reveal(entry.key);
  if(entry.key.startsWith('rule-'))$('combo-rules').open=true;
  const target=$(entry.id)||document.querySelector(`[data-setting="${entry.key}"] input,[data-setting="${entry.key}"] select`);
  const box=target?.closest('.field,[data-panel],.hurt-vulnerability')||target;
  target?.focus({preventScroll:true});box?.scrollIntoView({block:'center'});box?.classList.add('setting-focus');setTimeout(()=>box?.classList.remove('setting-focus'),1800);return true;
}});
initialize();requestAnimationFrame(animate);
