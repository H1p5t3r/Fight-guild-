import {renderMovement} from './movement-editor.mjs';
import {Workshop,validate,parseField,totalFrames,blockAdvantage,phaseAt,phaseStart,effectiveHurtboxes,inputName,geometryWarnings,CHARACTERS,MOVE_IDS,clone,META} from './model.mjs';
import {HURT_PHASES,HURT_REGIONS,HURT_LABELS,validateHurtboxes} from '../hurtboxes.mjs';
import {SPECS,GROUPS,TABS,ART_FIELDS,GUILDS,COLORS,KINDS} from './specs.mjs';
import {Preview} from './preview.mjs';
import {prepareReference,MAX_REFERENCES,MAX_IMPORT_BYTES,REFERENCE_PHASES} from './references.mjs';
import {validateHitTimeline,keyAt} from '../hitboxes.mjs';
import {renderHitEditor} from './hit-editor.mjs';
import {CombatPreview,describeInput} from './simulation.mjs';
import {cursorAnchor,cursorIndex} from './cursor.mjs';
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
function fieldError(key,message){const id='field-'+key,node=$(id);if(message)errors.set(id,message);else errors.delete(id);node?.setAttribute('aria-invalid',String(!!message));const messageNode=$('error-'+key);if(messageNode)messageNode.textContent=message||'';refreshActions();}
function refreshActions(){
  $('export').disabled=bootLocked||referenceBusy||errors.size>0;$('undo').disabled=bootLocked||referenceBusy||(!model.undoStack.length&&!errors.size);$('redo').disabled=bootLocked||referenceBusy||!model.redoStack.length||errors.size>0;
  $('reset').disabled=tab==='movement'?bootLocked||referenceBusy:bootLocked||referenceBusy||(!move().hitboxTimeline.keys.length&&!move().hitboxTimeline.multiHit&&!Object.keys(move().hurtboxes).length&&!Object.keys(SPECS).filter(key=>!key.startsWith('smear')).some(key=>move()[key]!==pack.defaults.characters[character].moves[slot][key]));
  $('attack-enabled').disabled=bootLocked||referenceBusy;
  $('import').disabled=referenceBusy;$('fighter').disabled=bootLocked||referenceBusy;
  if(errors.size){$('save-status').textContent='Check the highlighted value';$('save-dot').style.background='var(--danger)';}
}
function syncSummary(){
  const m=move(),adv=blockAdvantage(m),note=model.note(character,slot);
  document.documentElement.style.setProperty('--accent',COLORS[character]);
  $('move-context').textContent=`${CHARACTERS[character].toUpperCase()} / ${GUILDS[character].toUpperCase()}`;
  const movement=tab==='movement';
  document.querySelector('.attack-toggle').hidden=movement;document.querySelector('.summary').hidden=movement;
  for(const id of ['test-behavior','test-entry','test-gap','test-simple'])$(id).closest('label').hidden=movement;
  $('reset').textContent=movement?'Reset movement':'Reset move';
  $('move-kind').hidden=movement;$('actual-input').hidden=movement;$('move-enabled').hidden=movement;
  $('move-title').textContent=movement?'Movement & defense':m.id;$('move-label').textContent=note.label||'';
  $('move-kind').textContent=KINDS[m.category];$('actual-input').textContent=`Input ${inputName(m)}`;
  $('move-enabled').textContent=m.enabled?'● Enabled':'○ Unused slot';$('move-enabled').style.color=m.enabled?'#a8cbaa':'var(--muted)';
  $('attack-enabled').checked=!!m.enabled;
  $('stat-startup').replaceChildren(document.createTextNode(m.startup),el('small',{},' f'));
  $('stat-damage').textContent=m.damage;$('stat-block').textContent=(adv>0?'+':'')+adv+' f';$('stat-block').className=adv>0?'positive':adv<0?'negative':'';
  $('stat-total').replaceChildren(document.createTextNode(totalFrames(m)),el('small',{},' f'));
  const profiles=model.data.characters.filter((c,i)=>Object.keys(c.movement).some(key=>!key.startsWith('smear')&&c.movement[key]!==pack.defaults.characters[i].movement[key])).length;
  $('changed-count').textContent=`${model.changes().length} edited move${model.changes().length===1?'':'s'}${profiles?' · '+profiles+' movement profile'+(profiles===1?'':'s'):''}`;
  $('guild').textContent=GUILDS[character];$('roster-count').textContent=`${model.data.characters[character].moves.filter(m=>m.enabled).length} moves`;
  const warnings=geometryWarnings(m);$('move-warnings').replaceChildren(...warnings.map(w=>el('p',{},w)));$('move-warnings').hidden=!warnings.length;
  refreshActions();syncPreview();
}
function listMoves(){
  const text=$('search').value.trim().toLowerCase(),list=$('move-list'),fragment=document.createDocumentFragment();let matches=0;
  model.data.characters[character].moves.forEach((m,i)=>{
    const note=model.note(character,i),matchesText=`${m.id} ${inputName(m)} ${note.label||''}`.toLowerCase().includes(text);
    const matchesFilter=filter==='all'||filter==='normal'&&[0,1,3,4].includes(m.category)&&!m.air||filter==='special'&&m.category===2||filter==='air'&&m.air;
    if((!m.enabled&&!$('show-unused').checked&&i!==slot)||!matchesText||!matchesFilter)return;
    const button=el('button',{type:'button',class:'move-row'+(!m.enabled?' off':''),'aria-current':String(i===slot),'data-move':i,'aria-label':`${m.id}${note.label?' '+note.label:''}, ${m.startup} startup, ${m.active} active, ${m.recovery} recovery${!m.enabled?', unused slot':''}`});
    button.append(el('strong',{},m.id),el('span',{class:'move-dots','aria-label':model.changed(character,i)?'Edited':''},model.changed(character,i)?'●':''),el('small',{class:'move-category'},note.label||(!m.enabled?'Unused slot':`${m.air?'Air · ':''}${KINDS[m.category]}`)),el('span',{class:'frames'},`${m.startup} / ${m.active} / ${m.recovery}`));
    button.addEventListener('click',()=>{if(!validBeforeLeaving())return;slot=i;frame=move().startup;pendingSeek={frame};stop();render();document.querySelector(`[data-move="${i}"]`)?.focus({preventScroll:true});saveSelection();});fragment.append(button);matches++;
  });
  if(!matches)fragment.append(el('p',{class:'empty'},'No moves match. Try another filter or show unused slots.'));
  const scroll=list.scrollTop,left=list.scrollLeft;list.replaceChildren(fragment);list.scrollTop=scroll;list.scrollLeft=left;
}
function saveSelection(){if(storageOkay&&!bootLocked){clearTimeout(saveTimer);saveTimer=setTimeout(save,200);}}
function optionsFor(key){
  if(key==='followFrom'||key==='followFrom2')return [[-1,'None'],...MOVE_IDS.map((name,i)=>[i,`${name}${!model.move(character,i).enabled?' · unused':''}`])];
  if(key==='artPose')return [[0,'Button poses'],...Array.from({length:pack.limits.moves[character].artPose.max},(_,i)=>[i+1,`${i+1} · ${(character===5?['Knife spiral','Rekka rise','Rekka stab','Rekka low']:['Ground hook','Air hook','Ground stab','Air stab'])[i]}`])];
  return SPECS[key].options;
}
function commit(key,value){
  try{model.change(character,slot,key,value);fieldError(key,'');syncSummary();listMoves();scheduleSave();}
  catch(error){fieldError(key,error.message);}
}
function numberField(key){
  const spec=SPECS[key],limit=pack.limits.moves[character][key],field=el('div',{class:'field'}),id='field-'+key;
  const label=el('label',{for:id},spec.label),wrap=el('div',{class:'input-wrap'}),input=el('input',{id,type:'number',min:limit.min/spec.scale,max:limit.max/spec.scale,step:1/spec.scale,inputmode:spec.scale===1?'numeric':'decimal','aria-describedby':`hint-${key} error-${key}`});
  input.value=move()[key]/spec.scale;wrap.append(input);if(spec.unit)wrap.append(el('span',{class:'unit'},spec.unit));field.append(label,wrap);
  if(spec.hint)field.append(el('small',{class:'hint',id:'hint-'+key},spec.hint));
  field.append(el('span',{class:'error',id:'error-'+key,'aria-live':'polite'}));
  input.addEventListener('input',()=>{try{const value=parseField(key,input.value,limit);commit(key,value);}catch(error){fieldError(key,error.message);}});
  input.addEventListener('change',()=>{if(!errors.has(id))input.value=move()[key]/spec.scale;});
  return field;
}
function selectField(key){
  const spec=SPECS[key],field=el('div',{class:'field'}),id='field-'+key,select=el('select',{id});
  select.append(...optionsFor(key).map(([value,label])=>el('option',{value},label)));select.value=move()[key];
  field.append(el('label',{for:id},spec.label),select);if(spec.hint)field.append(el('small',{class:'hint',id:'hint-'+key},spec.hint));
  select.addEventListener('change',()=>{commit(key,Number(select.value));if(key==='category'||key==='artPose'||key==='air')syncPreview();});return field;
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
function section(group){
  const node=el('section',{class:'form-section','aria-label':group.title});node.append(el('h2',{},group.title),el('p',{},group.intro));const grid=el('div',{class:'field-grid'});
  for(const key of group.fields){const type=SPECS[key].type;grid.append(type==='number'?numberField(key):type==='select'?selectField(key):type==='flag'?flagField(key):maskField(key));}node.append(grid);return node;
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
  if(m.hurtboxes[phase]||!matchingRecord()||previewPending||testRecord.geometryOnly||recorded?.selectedFrame!==frame)return effectiveHurtboxes(pack,character,m,frame);
  const a=recorded.state.players[0];
  return Object.fromEntries(recorded.boxes[0].hurt.map((b,i)=>[HURT_REGIONS[i],a.facing===1?[b[0]-a.x,b[1]-a.y,b[2]-a.x,b[3]-a.y]:[a.x-b[2],b[1]-a.y,a.x-b[0],b[3]-a.y]]));
}
function syncHurtFields(){
  if(tab!=='hurt')return;const rect=visibleHurtboxes()[hurtRegion];if(!rect)return;
  for(const [key,value]of Object.entries(hurtValues(rect))){const input=$('field-hurt-'+key);if(input&&document.activeElement!==input)input.value=value;}
}
function hurtForm(){
  const m=move();hurtPhase=phaseAt(m,frame);const custom=!!m.hurtboxes[hurtPhase],boxes=visibleHurtboxes();
  if(!boxes[hurtRegion])hurtRegion='torsoArms';
  const section=el('section',{class:'form-section hurt-editor'});section.append(el('h2',{},'Body hurtboxes'),el('p',{},'Edit this attack’s body coverage for each phase. Other moves that share its sprite keep their own boxes.'));
  const phase=el('select',{id:'hurt-phase'});phase.append(...HURT_PHASES.map(p=>{const option=el('option',{value:p},p==='windup'?`Windup · ${m.startup-1}f`:p==='active'?`Active · ${m.active}f`:`Recovery · ${m.recovery}f`);option.disabled=p==='recovery'&&!m.recovery;return option;}));phase.value=hurtPhase;
  phase.onchange=()=>{if(!validBeforeLeaving()){phase.value=hurtPhase;return;}seekMove(phaseStart(m,phase.value));saveSelection();};
  const enable=el('input',{id:'hurt-custom',type:'checkbox',checked:custom}),enableRow=el('div',{class:'hurt-toggle'});enableRow.append(enable,el('label',{for:'hurt-custom'},'Custom boxes for this phase'));
  enable.onchange=()=>{if(!validBeforeLeaving()){enable.checked=custom;return;}stop();model.setHurtPhase(character,slot,hurtPhase,enable.checked?visibleHurtboxes():null);renderForm();syncSummary();listMoves();scheduleSave();};
  section.append(el('label',{for:'hurt-phase',class:'field-label'},'Attack phase'),phase,enableRow,el('p',{class:'hurt-status'},custom?'Custom profile · saved with this move':'Using the sprite pose. Enable custom boxes to make changes.'));
  const region=el('select',{id:'hurt-region'});region.append(...HURT_REGIONS.filter(r=>boxes[r]).map(r=>el('option',{value:r},HURT_LABELS[r])));region.value=hurtRegion;
  region.onchange=()=>{if(!validBeforeLeaving()){region.value=hurtRegion;return;}stop();hurtRegion=region.value;renderForm();syncPreview();};
  section.append(el('label',{for:'hurt-region',class:'field-label'},'Selected body box'),region);
  const grid=el('div',{class:'field-grid hurt-grid'}),values=hurtValues(boxes[hurtRegion]);
  for(const [key,label]of [['left','Left position'],['bottom','Bottom position'],['width','Width'],['height','Height']]){
    const id='field-hurt-'+key,field=el('div',{class:'field'}),wrap=el('div',{class:'input-wrap'}),input=el('input',{id,type:'number',min:key==='width'||key==='height'?1:-500,max:key==='width'||key==='height'?1000:500,step:'0.01',inputmode:'decimal','aria-describedby':'error-hurt-'+key});input.value=values[key];input.disabled=!custom;
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
  if(tab==='movement'){
    $('form').setAttribute('aria-labelledby','tab-movement');
    $('form').replaceChildren(renderMovement({el,profile:model.data.characters[character].movement,limits:pack.limits.movement[character],onError:fieldError,action:movementAction,onAction:value=>{if(!validBeforeLeaving())return;movementAction=value;pendingSeek={tick:0};stop();syncPreview();},onChange:(key,value)=>{model.changeMovement(character,key,value);syncSummary();scheduleSave();}}));return;
  }
  const form=$('form');form.setAttribute('aria-labelledby','tab-'+tab);
  if(tab==='art'){form.replaceChildren(artForm());return;}
  if(tab==='hurt'){form.replaceChildren(hurtForm());return;}
  const groups=TABS.find(t=>t.id===tab).groups.map(id=>GROUPS.find(g=>g.id===id)),nodes=groups.map((group,i)=>{
    const view=section(group);if(i===0||tab==='hit')return view;
    const details=el('details',{class:'section-divider'});details.append(el('summary',{},group.title),view);return details;
  });if(tab==='hit')nodes.unshift(renderHitEditor({move:move(),frame,pack,character,boxIndex:hitBox,selectedFrame:hitKeyFrame,
    valid:validBeforeLeaving,onError:fieldError,onKey:value=>{hitKeyFrame=value;seekMove(value===null?frame:move().startup+Math.min(Math.max(1,value),move().active)-1);},
    onBox:value=>{hitBox=value;renderForm();syncPreview();},
    onChange:(track,render=true,group='')=>{model.setHitTimeline(character,slot,track,group);stop();if(render)renderForm();syncSummary();listMoves();scheduleSave();}
  }));form.replaceChildren(...nodes);
}
function renderTabs(){
  $('tabs').replaceChildren(...TABS.map(t=>{const button=el('button',{id:'tab-'+t.id,type:'button',role:'tab','aria-selected':String(t.id===tab),'aria-controls':'form',tabindex:t.id===tab?'0':'-1'},t.label);
    button.addEventListener('click',()=>{if(!validBeforeLeaving())return;stop();tab=t.id;hitKeyFrame=null;if(tab==='hurt'){stop();preview.options.hurt=true;$('show-hurt').checked=true;}renderTabs();renderForm();syncSummary();saveSelection();$('tab-'+tab).focus();});
    button.addEventListener('keydown',event=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;event.preventDefault();const index=TABS.indexOf(t),next=event.key==='Home'?0:event.key==='End'?TABS.length-1:(index+(event.key==='ArrowRight'?1:-1)+TABS.length)%TABS.length;$('tab-'+TABS[next].id).click();});return button;}));
}
function render(){hitKeyFrame=null;errors.clear();$('fighter').value=character;listMoves();renderTabs();renderForm();syncSummary();
  const list=$('move-list'),selected=list.querySelector('[aria-current="true"]');if(selected){const r=selected.getBoundingClientRect(),b=list.getBoundingClientRect();
    if(r.top<b.top)list.scrollTop+=r.top-b.top;else if(r.bottom>b.bottom)list.scrollTop+=r.bottom-b.bottom;
    if(r.left<b.left)list.scrollLeft+=r.left-b.left;else if(r.right>b.right)list.scrollLeft+=r.right-b.right;
  }
}
function syncPreview(){
  const m=move();frame=Math.max(1,Math.min(totalFrames(m),frame));
  $('windup-time').textContent=`Windup ${m.startup-1}f`;$('active-time').textContent=`Active ${m.active}f`;$('recovery-time').textContent=`Recovery ${m.recovery}f`;
  const phases=[['windup',m.startup-1,1],['active',m.active,m.startup],['recovery',m.recovery,m.startup+m.active]];
  $('timeline').hidden=tab==='movement';
  $('timeline').replaceChildren(...phases.filter(([,length])=>length).map(([name,length,start])=>{const b=el('button',{type:'button',class:name,'aria-label':`Jump to ${name}: ${length} frames`,title:`${name}: ${length}f`});b.style.flex=length;b.addEventListener('click',()=>{if(!validBeforeLeaving())return;hitKeyFrame=null;seekMove(start);});return b;}));
  scheduleTest();
}
function stop(){playing=false;$('play').setAttribute('aria-label','Play attack');}
function testOptions(){return {target:Number($('test-target').value),behavior:$('test-behavior').value,entry:$('test-entry').value,gap:Number($('test-gap').value),facing:Number($('test-facing').value),simple:$('test-simple').value==='1',movement:tab==='movement'?movementAction:null};}
function matchingRecord(){return testRecord?.character===character&&testRecord?.slot===slot&&!!testRecord.movement===(tab==='movement');}
function seekMove(value){
  stop();frame=Math.max(1,Math.min(totalFrames(move()),value));pendingSeek={frame};
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
      testRecord=tab==='movement'?combatPreview.recordMovement(model.data,character,slot,movementAction,testOptions()):combatPreview.record(model.data,character,slot,testOptions());recordSignature=signature;
      testIndex=cursorIndex(testRecord,pendingSeek||{frame:move().startup});pendingSeek=null;previewPending=false;drawTest();
    }catch(error){testRecord=null;testSignature='';previewPending=false;preview.clear();$('test-readout').textContent='Preview could not run: '+error.message;}
  },80);
}
function drawTest(){
  if(!matchingRecord())return;
  testIndex=Math.min(testIndex,testRecord.frames.length-1);const f=testRecord.frames[testIndex],a=f.state.players[0],target=f.state.players[1],m=move(),oldFrame=frame;
  if(f.selectedFrame&&!previewPending&&!pendingSeek)frame=f.selectedFrame;
  const phase=phaseAt(m,frame),key=keyAt(m,Math.max(1,frame-m.startup+1)),keyIndex=m.hitboxTimeline.keys.indexOf(key);
  if(!previewPending&&!dragBefore&&!hurtDragBefore&&((tab==='hurt'&&hurtPhase!==phase)||(tab==='hit'&&hitKeyFrame===null&&keyAt(m,Math.max(1,oldFrame-m.startup+1))!==key)))renderForm();
  const editable=tab!=='movement'&&!playing&&(!previewPending||dragBefore||hurtDragBefore)&&!!f.selectedFrame;
  preview.show(testRecord,testIndex,m,{
    hit:editable&&tab==='hit'&&(hitKeyFrame===null||hitKeyFrame===key?.frame),
    hitKey:key&&key.boxes!==null?{keyIndex,boxIndex:Math.min(hitBox,Math.max(0,key.boxes.length-1))}:null,
    hurt:editable&&tab==='hurt'?{phase,region:hurtRegion,custom:!!m.hurtboxes[phase]}:null
  });
  $('frame').max=testRecord.frames.length-1;$('frame').value=testIndex;$('frame-label').textContent=`${testIndex} / ${testRecord.frames.length-1}`;
  $('play').disabled=previewPending||testRecord.frames.length<2;
  $('preview-title').textContent=testRecord.movement?f.stage:f.selectedFrame?`${phase==='windup'?'Windup':phase==='active'?'Active':'Recovery'} · frame ${f.selectedFrame}`:'Attack workspace';
  $('test-readout').textContent=previewPending?'Updating exchange…':`${testRecord.geometryOnly?'Geometry only':`Input ${describeInput(f.input,a.facing)}`} · ${f.selectedFrame?'move frame '+f.selectedFrame:f.stage}${f.state.hitstop?' · freeze '+f.state.hitstop+'f':''} · target ${target.stun}f stun`;
  const contacts=testRecord.contacts.filter(c=>c.tick<=testIndex),hits=contacts.filter(c=>c.event!==2).length;
  $('test-result').textContent=previewPending?'Recalculating contact…':`${hits} hit${hits===1?'':'s'} · ${contacts.length-hits} blocks · ${1000-target.health} damage · attacker travel ${((a.x-testRecord.frames[0].state.players[0].x)/100).toFixed(1)}px`;
  $('test-warning').textContent=testRecord.warnings.join(' ');$('test-warning').hidden=!testRecord.warnings.length;
  $('geometry-help').textContent=testRecord.movement?'Play or scrub the movement here. Edit the character profile alongside this preview.':playing?'Pause or scrub to edit boxes directly on the fighter.':!f.selectedFrame?'Use Windup, Active or Recovery to jump to an editable attack frame.':tab==='hurt'?'Enable custom boxes, choose a body region and drag its blue handles. Changes update this same exchange.':tab==='hit'?'On active frames, drag the selected orange box or its edges. Edits keep this move frame while recalculating contact.':'Play, pause or scrub here. Open Hit & movement or Hurtboxes to edit directly on the fighter.';
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
    const next=clone(move().hurtboxes[patch.phase]);next[patch.region]=patch.rect;
    try{validateHurtboxes({[patch.phase]:next});}catch{return;}
    move().hurtboxes[patch.phase]=next;syncHurtFields();syncSummary();
  }
  if(stage==='end'&&hurtDragBefore){model.remember(hurtDragBefore);hurtDragBefore=null;listMoves();refreshActions();scheduleSave();syncPreview();}
});
function start(data=pack.defaults,selection={}){
  model=new Workshop(pack,data);character=Number.isInteger(selection.character)&&selection.character>=0&&selection.character<6?selection.character:5;
  slot=Number.isInteger(selection.slot)&&selection.slot>=0&&selection.slot<32?selection.slot:0;tab=TABS.some(t=>t.id===selection.tab)?selection.tab:'timing';frame=move().startup;pendingSeek={frame};
  $('fighter').replaceChildren(...[5,4,0,1,2,3].map(i=>el('option',{value:i},CHARACTERS[i])));$('fighter').disabled=false;render();
  $('save-status').textContent=storageOkay?'Saved on this device only':'Download to keep your edits';
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
$('fighter').addEventListener('change',()=>{if(!validBeforeLeaving()){$('fighter').value=character;return;}character=Number($('fighter').value);slot=0;frame=move().startup;pendingSeek={frame};stop();$('search').value='';render();saveSelection();});
$('search').addEventListener('input',listMoves);$('show-unused').addEventListener('change',listMoves);
for(const button of document.querySelectorAll('[data-filter]'))button.addEventListener('click',()=>{filter=button.dataset.filter;for(const b of document.querySelectorAll('[data-filter]')){b.classList.toggle('selected',b===button);b.setAttribute('aria-pressed',String(b===button));}listMoves();});
$('undo').onclick=()=>{stop();if(errors.size){errors.clear();render();announce('Invalid input discarded.');return;}if(model.undo()){frame=Math.min(frame,totalFrames(move()));render();scheduleSave();announce('Edit undone.');}};
$('redo').onclick=()=>{if(!validBeforeLeaving())return;if(model.redo()){stop();render();scheduleSave();announce('Edit restored.');}};
$('reset').onclick=()=>{errors.clear();if(tab==='movement')model.resetMovement(character);else model.resetMove(character,slot);stop();frame=move().startup;pendingSeek={frame};render();scheduleSave();announce('Move stats, hitbox keys and hurtboxes reset. Art notes are kept. Undo is available.');};
$('import').onclick=()=>{if(validBeforeLeaving())$('import-file').click();};
$('import-file').onchange=async event=>{
  const file=event.target.files[0];if(!file)return;
  try{if(file.size>MAX_IMPORT_BYTES)throw new Error('Choose a move JSON file smaller than 32 MB.');const data=JSON.parse(await file.text());model.import(data);bootLocked=false;$('form').inert=false;$('fighter').disabled=false;errors.clear();stop();frame=move().startup;pendingSeek={frame};render();scheduleSave();announce('Move data imported. Undo returns to your previous draft.');}
  catch(error){announce('Import stopped: '+error.message);}finally{event.target.value='';}
};
$('export').onclick=()=>{if(!validBeforeLeaving())return;try{download(model.export(),'FightGuild-moves-'+date()+'.json','application/json');save();unexported=false;announce('JSON downloaded. Import it in the Godot move editor or send it back for the sprite pass.');}catch(error){announce(error.message);}};
$('frame').addEventListener('input',()=>{if(!validBeforeLeaving()){$('frame').value=testIndex;return;}stop();hitKeyFrame=null;const tick=Number($('frame').value);if(previewPending)pendingSeek={tick};else{testIndex=tick;drawTest();}renderForm();});
$('play').onclick=()=>{if(!validBeforeLeaving()||!testRecord||previewPending)return;if(testIndex===testRecord.frames.length-1)testIndex=0;playing=!playing;hitKeyFrame=null;lastTick=0;$('play').setAttribute('aria-label',playing?'Pause attack':'Play attack');drawTest();};
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
for(const id of ['test-target','test-behavior','test-entry','test-gap','test-facing','test-simple'])$(id).onchange=()=>{if(!validBeforeLeaving())return;const gap=Number($('test-gap').value);if(!Number.isInteger(gap)||gap<0||gap>450){$('test-gap').value='24';announce('Use a whole starting gap from 0 to 450 px.');}testSignature='';scheduleTest();};
globalThis.moveWorkshop.preview=()=>testRecord;
globalThis.moveWorkshop.cursor=()=>({index:testIndex,frame:testRecord?.frames[testIndex]?.selectedFrame||0,pending:previewPending});
globalThis.moveWorkshop.geometry=()=>({handles:clone(preview.handles),view:clone(preview.view||{}),measurements:clone(preview.measurements||null),measurementLabels:clone(preview.measurementLabels||[])});
initialize();requestAnimationFrame(animate);
