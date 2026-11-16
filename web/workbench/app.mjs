import {Workshop,validate,parseField,totalFrames,blockAdvantage,phaseAt,inputName,geometryWarnings,CHARACTERS,MOVE_IDS,clone,META} from './model.mjs';
import {SPECS,GROUPS,TABS,ART_FIELDS,GUILDS,COLORS,KINDS} from './specs.mjs';
import {Preview} from './preview.mjs';
const $=id=>document.getElementById(id),pack=globalThis.FIGHT_WORKSHOP_DATA;
const STORAGE='fight-guild.move-workshop.v1';
let model,character=5,slot=0,tab='timing',filter='all',frame=5,playing=false,lastTick=0,saveTimer,toastTimer,dragBefore;
let storageOkay=true,savePending=false,unexported=false,bootLocked=false,recoveryRaw='';
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
function validBeforeLeaving(){if(bootLocked){announce('Recover your saved draft or start a new one first.');return false;}if(!errors.size)return true;announce('Fix the highlighted value before changing moves or downloading.');$(errors.keys().next().value)?.focus();return false;}
function move(){return model.move(character,slot);}
function fieldError(key,message){const id='field-'+key,node=$(id);if(message)errors.set(id,message);else errors.delete(id);node?.setAttribute('aria-invalid',String(!!message));const messageNode=$('error-'+key);if(messageNode)messageNode.textContent=message||'';refreshActions();}
function refreshActions(){
  $('export').disabled=bootLocked||errors.size>0;$('undo').disabled=bootLocked||(!model.undoStack.length&&!errors.size);$('redo').disabled=bootLocked||!model.redoStack.length||errors.size>0;
  $('reset').disabled=bootLocked||!Object.keys(SPECS).some(key=>move()[key]!==pack.defaults.characters[character].moves[slot][key]);
  if(errors.size){$('save-status').textContent='Check the highlighted value';$('save-dot').style.background='var(--danger)';}
}
function syncSummary(){
  const m=move(),adv=blockAdvantage(m),note=model.note(character,slot);
  document.documentElement.style.setProperty('--accent',COLORS[character]);
  $('move-context').textContent=`${CHARACTERS[character].toUpperCase()} / ${GUILDS[character].toUpperCase()}`;
  $('move-title').textContent=m.id;$('move-label').textContent=note.label||'';
  $('move-kind').textContent=KINDS[m.category];$('actual-input').textContent=`Input ${inputName(m)}`;
  $('move-enabled').textContent=m.enabled?'● Enabled':'○ Unused slot';$('move-enabled').style.color=m.enabled?'#a8cbaa':'var(--muted)';
  $('stat-startup').replaceChildren(document.createTextNode(m.startup),el('small',{},' f'));
  $('stat-damage').textContent=m.damage;$('stat-block').textContent=(adv>0?'+':'')+adv+' f';$('stat-block').className=adv>0?'positive':adv<0?'negative':'';
  $('stat-total').replaceChildren(document.createTextNode(totalFrames(m)),el('small',{},' f'));
  $('changed-count').textContent=`${model.changes().length} edited move${model.changes().length===1?'':'s'}`;
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
    button.addEventListener('click',()=>{if(!validBeforeLeaving())return;slot=i;frame=move().startup;stop();render();document.querySelector(`[data-move="${i}"]`)?.focus({preventScroll:true});saveSelection();});fragment.append(button);matches++;
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
function artForm(){
  const container=el('section',{class:'form-section'});container.append(el('h2',{},'Give the attack a direction.'),el('p',{class:'art-intro'},'These notes travel with your JSON. Use them to brief new windup and active poses after the move feels right.'));
  const grid=el('div',{class:'field-grid'}),note=model.note(character,slot);
  for(const [key,label,placeholder,max] of ART_FIELDS){
    const id='note-'+key,field=el('div',{class:'field wide'}),input=el(key==='label'?'input':'textarea',{id,...(key==='label'?{type:'text'}:{rows:'3'}),placeholder,maxlength:max});input.value=note[key]||'';field.append(el('label',{for:id},label),input);grid.append(field);
    input.addEventListener('input',()=>{model.setNote(character,slot,key,input.value);syncSummary();if(key==='label')listMoves();scheduleSave();});
  }
  const exportBrief=el('button',{type:'button',class:'art-export'},'Download art brief');exportBrief.addEventListener('click',()=>download(model.brief(),'FightGuild-art-brief-'+date()+'.md','text/markdown;charset=utf-8'));container.append(grid,exportBrief);return container;
}
function renderForm(){
  const form=$('form');form.setAttribute('aria-labelledby','tab-'+tab);
  if(tab==='art'){form.replaceChildren(artForm());return;}
  const groups=TABS.find(t=>t.id===tab).groups.map(id=>GROUPS.find(g=>g.id===id)),nodes=groups.map((group,i)=>{
    const view=section(group);if(i===0||tab==='hit')return view;
    const details=el('details',{class:'section-divider'});details.append(el('summary',{},group.title),view);return details;
  });form.replaceChildren(...nodes);
}
function renderTabs(){
  $('tabs').replaceChildren(...TABS.map(t=>{const button=el('button',{id:'tab-'+t.id,type:'button',role:'tab','aria-selected':String(t.id===tab),'aria-controls':'form',tabindex:t.id===tab?'0':'-1'},t.label);
    button.addEventListener('click',()=>{if(!validBeforeLeaving())return;tab=t.id;renderTabs();renderForm();syncPreview();saveSelection();$('tab-'+tab).focus();});
    button.addEventListener('keydown',event=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;event.preventDefault();const index=TABS.indexOf(t),next=event.key==='Home'?0:event.key==='End'?TABS.length-1:(index+(event.key==='ArrowRight'?1:-1)+TABS.length)%TABS.length;$('tab-'+TABS[next].id).click();});return button;}));
}
function render(){errors.clear();$('fighter').value=character;listMoves();renderTabs();renderForm();syncSummary();
  const list=$('move-list'),selected=list.querySelector('[aria-current="true"]');if(selected){const r=selected.getBoundingClientRect(),b=list.getBoundingClientRect();
    if(r.top<b.top)list.scrollTop+=r.top-b.top;else if(r.bottom>b.bottom)list.scrollTop+=r.bottom-b.bottom;
    if(r.left<b.left)list.scrollLeft+=r.left-b.left;else if(r.right>b.right)list.scrollLeft+=r.right-b.right;
  }
}
function syncPreview(){
  const m=move(),total=totalFrames(m);frame=Math.max(1,Math.min(total,frame));$('frame').max=total;$('frame').value=frame;$('frame-label').textContent=`${frame} / ${total}`;
  const phase=phaseAt(m,frame);$('preview-title').textContent=phase==='windup'?'Windup pose':phase==='active'?'Active frame':'Recovery · idle placeholder';
  $('windup-time').textContent=`Windup ${m.startup-1}f`;$('active-time').textContent=`Active ${m.active}f`;$('recovery-time').textContent=`Recovery ${m.recovery}f`;
  const phases=[['windup',m.startup-1,1],['active',m.active,m.startup],['recovery',m.recovery,m.startup+m.active]];
  $('timeline').replaceChildren(...phases.filter(([,length])=>length).map(([name,length,start])=>{const b=el('button',{type:'button',class:name,'aria-label':`Preview ${name}: ${length} frames`,title:`${name}: ${length}f`});b.style.flex=length;b.addEventListener('click',()=>{stop();frame=start;syncPreview();});return b;}));
  $('geometry-help').textContent=tab==='hit'&&!m.hitAngle&&m.category!==4?'On an active frame, drag the orange edges to resize the hitbox or drag its center to move it. Numeric fields give precise control.':m.hitAngle?'The dotted line is the hook path; orange segments are the moving spear hitboxes. Edit the path and thickness in Hit & movement.':m.category===4?'Throw geometry uses the fighter’s pushbox plus Throw reach. The usual hitbox fields do not change its size.':'Current pose artwork stays fixed while you tune the attack. Match timing and movement should be tested in game.';
  preview.show(character,m,frame,tab==='hit'&&!playing);
}
function stop(){playing=false;$('play').setAttribute('aria-label','Play move preview');}
function animate(time){
  if(playing){if(!lastTick)lastTick=time;const advance=Math.floor((time-lastTick)/(1000/30));if(advance){frame=(frame-1+advance)%totalFrames(move())+1;lastTick+=advance*(1000/30);syncPreview();}}
  requestAnimationFrame(animate);
}
function syncVisibleFields(){for(const [key,spec]of Object.entries(SPECS)){const input=$('field-'+key);if(input&&spec.type==='number'&&document.activeElement!==input)input.value=move()[key]/spec.scale;}}
const preview=new Preview($('preview'),pack,(phase,patch)=>{
  if(phase==='start'){if(!validBeforeLeaving())return;dragBefore=model.snapshot();stop();}
  if(phase==='change'&&dragBefore){
    const limits=pack.limits.moves[character];for(const [key,value]of Object.entries(patch))if(value<limits[key].min||value>limits[key].max)return;
    const candidate={...move(),...patch};if(candidate.hitboxBack>=candidate.reach||candidate.height<100)return;
    Object.assign(move(),patch);syncVisibleFields();syncSummary();
  }
  if(phase==='end'&&dragBefore){model.remember(dragBefore);dragBefore=null;listMoves();refreshActions();scheduleSave();}
});
function start(data=pack.defaults,selection={}){
  model=new Workshop(pack,data);character=Number.isInteger(selection.character)&&selection.character>=0&&selection.character<6?selection.character:5;
  slot=Number.isInteger(selection.slot)&&selection.slot>=0&&selection.slot<32?selection.slot:0;tab=TABS.some(t=>t.id===selection.tab)?selection.tab:'timing';frame=move().startup;
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
$('fighter').addEventListener('change',()=>{if(!validBeforeLeaving()){$('fighter').value=character;return;}character=Number($('fighter').value);slot=0;frame=move().startup;stop();$('search').value='';render();saveSelection();});
$('search').addEventListener('input',listMoves);$('show-unused').addEventListener('change',listMoves);
for(const button of document.querySelectorAll('[data-filter]'))button.addEventListener('click',()=>{filter=button.dataset.filter;for(const b of document.querySelectorAll('[data-filter]')){b.classList.toggle('selected',b===button);b.setAttribute('aria-pressed',String(b===button));}listMoves();});
$('undo').onclick=()=>{stop();if(errors.size){errors.clear();render();announce('Invalid input discarded.');return;}if(model.undo()){frame=Math.min(frame,totalFrames(move()));render();scheduleSave();announce('Edit undone.');}};
$('redo').onclick=()=>{if(!validBeforeLeaving())return;if(model.redo()){stop();render();scheduleSave();announce('Edit restored.');}};
$('reset').onclick=()=>{errors.clear();model.resetMove(character,slot);stop();frame=move().startup;render();scheduleSave();announce('This move’s stats were reset. Art notes are kept. Undo is available.');};
$('import').onclick=()=>{if(validBeforeLeaving())$('import-file').click();};
$('import-file').onchange=async event=>{
  const file=event.target.files[0];if(!file)return;
  try{if(file.size>5*1024*1024)throw new Error('Choose a move JSON file smaller than 5 MB.');const data=JSON.parse(await file.text());model.import(data);bootLocked=false;$('form').inert=false;$('fighter').disabled=false;errors.clear();stop();frame=move().startup;render();scheduleSave();announce('Move data imported. Undo returns to your previous draft.');}
  catch(error){announce('Import stopped: '+error.message);}finally{event.target.value='';}
};
$('export').onclick=()=>{if(!validBeforeLeaving())return;try{download(model.export(),'FightGuild-moves-'+date()+'.json','application/json');save();unexported=false;announce('JSON downloaded. Import it in the Godot move editor or send it back for the sprite pass.');}catch(error){announce(error.message);}};
$('frame').addEventListener('input',()=>{stop();frame=Number($('frame').value);syncPreview();});
$('play').onclick=()=>{playing=!playing;lastTick=0;$('play').setAttribute('aria-label',playing?'Pause move preview':'Play move preview');$('play').title='Preview plays at half speed';syncPreview();};
for(const key of ['hit','hurt','push','art'])$('show-'+key).onchange=()=>{preview.options[key]=$('show-'+key).checked;preview.draw();};
$('help').onclick=()=>{$('help-dialog').showModal();};$('close-help').onclick=()=>{$('help-dialog').close();};
$('help-dialog').addEventListener('click',event=>{if(event.target===$('help-dialog')){const r=event.target.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)event.target.close();}});
window.addEventListener('keydown',event=>{if((event.ctrlKey||event.metaKey)&&event.key.toLowerCase()==='s'){event.preventDefault();$('export').click();}if((event.ctrlKey||event.metaKey)&&event.key.toLowerCase()==='z'&&!['INPUT','TEXTAREA','SELECT'].includes(event.target.tagName)){event.preventDefault();$(event.shiftKey?'redo':'undo').click();}});
window.addEventListener('pagehide',()=>{if(savePending)save();});
window.addEventListener('beforeunload',event=>{if(errors.size||!storageOkay&&unexported){event.preventDefault();event.returnValue='';}});
window.addEventListener('storage',event=>{if(event.key===STORAGE&&event.newValue){banner('This draft was saved in another tab. Download your current JSON before switching tabs to keep both versions.');}});
// Read-only inspection used by browser integration checks and JSON round trips.
globalThis.moveWorkshop={data:()=>model.snapshot(),selection:()=>({character,slot,tab}),version:pack.defaults.coreVersion};
initialize();requestAnimationFrame(animate);
