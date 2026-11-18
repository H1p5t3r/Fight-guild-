// Responsive presentation only. The same controls, canvas and draft are kept
// when the viewport changes; nothing is copied into a separate mobile editor.
export function createLayout({canNavigate,onOpenMoves,onSection}){
 const $=id=>document.getElementById(id),compact=matchMedia('(max-width: 1000px)'),dialog=$('move-dialog'),options=$('preview-options-dialog');
 const closeMoves=()=>{if(dialog.open)dialog.close();};
 let pinned=false;
 try{pinned=localStorage.getItem('fight-guild.preview-pin')==='true';}catch{}
 document.documentElement.classList.toggle('preview-pinned',pinned);$('preview-pin').setAttribute('aria-pressed',String(pinned));
 function adapt(){
  closeMoves();
  if(options.open)options.close();
  (compact.matches?$('picker-dialog-home'):$('picker-home')).append($('move-browser'));
  (compact.matches?$('preview-options-dialog-home'):$('preview-options-home')).append($('preview-options'));
  (compact.matches?$('mobile-history-home'):$('history-home')).append(document.querySelector('.history-actions'));
  (compact.matches?$('mobile-status-home'):$('save-home')).append(document.querySelector('.save-state'));
  $('preview-settings').open=!compact.matches;
  if(!compact.matches){$('preview-visual').hidden=false;$('preview-collapse').setAttribute('aria-expanded','true');$('preview-collapse').textContent='Minimize';$('preview-collapse').setAttribute('aria-label','Minimize preview');}
  measure();
 }
 function measure(){
  const root=document.documentElement;
  root.style.setProperty('--topbar-height',`${document.querySelector('.topbar').getBoundingClientRect().height}px`);
  root.style.setProperty('--preview-height',`${$('preview-core').getBoundingClientRect().height}px`);
  root.style.setProperty('--editor-nav-height',`${document.querySelector('.editor-navigation').getBoundingClientRect().height}px`);
 }
 $('choose-move').onclick=()=>{
  if(!canNavigate())return;
  onOpenMoves();dialog.showModal();document.body.classList.add('picker-open');
  const selected=$('move-list').querySelector('[aria-current="true"]');
  (selected||$('close-moves')).focus({preventScroll:true});
  selected?.scrollIntoView({block:'nearest'});
 };
 $('close-moves').onclick=closeMoves;
 $('preview-options-open').onclick=()=>{if(!canNavigate())return;onOpenMoves();options.showModal();document.body.classList.add('picker-open');$('preview-settings').open=true;};
 $('close-preview-options').onclick=()=>options.close();
 options.addEventListener('close',()=>document.body.classList.remove('picker-open'));
 dialog.addEventListener('close',()=>document.body.classList.remove('picker-open'));
 dialog.addEventListener('click',event=>{
  if(event.target!==dialog)return;
  const r=dialog.getBoundingClientRect();
  if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)closeMoves();
 });
 $('section-picker').onchange=()=>onSection($('section-picker').value);
 $('preview-pin').onclick=()=>{
  pinned=!pinned;document.documentElement.classList.toggle('preview-pinned',pinned);$('preview-pin').setAttribute('aria-pressed',String(pinned));
  try{localStorage.setItem('fight-guild.preview-pin',String(pinned));}catch{}
 };
 $('go-preview').onclick=()=>{if(!canNavigate())return;$('preview-core').scrollIntoView({block:'start'});};
 $('preview-collapse').onclick=()=>{
  const hidden=!$('preview-visual').hidden;$('preview-visual').hidden=hidden;
  $('preview-collapse').textContent=hidden?'Expand':'Minimize';
  $('preview-collapse').setAttribute('aria-expanded',String(!hidden));
  $('preview-collapse').setAttribute('aria-label',hidden?'Expand preview':'Minimize preview');
  measure();
 };
 function keyboard(){
  const input=document.activeElement,editing=input?.matches('input:not([type=checkbox]):not([type=range]),textarea,select');
  const small=!!editing&&compact.matches&&(window.visualViewport?.height??innerHeight)<500;
  document.documentElement.classList.toggle('keyboard-open',small);
 }
 window.visualViewport?.addEventListener('resize',keyboard);
 document.addEventListener('focusin',keyboard);document.addEventListener('focusout',()=>requestAnimationFrame(keyboard));
 const observer=new ResizeObserver(measure);observer.observe(document.querySelector('.topbar'));observer.observe($('preview-core'));observer.observe(document.querySelector('.editor-navigation'));
 compact.addEventListener('change',adapt);adapt();
 return {
  closeMoves,
  update(character,id,label){
   $('chosen-move').textContent=id;
   $('choose-move').setAttribute('aria-label',`Choose move: ${id}${label?' · '+label:''}`);
   $('move-picker-title').textContent=character+' moves';
   const reaction=$('test-behavior').selectedOptions[0]?.textContent??'';
   $('setup-summary').textContent=`${reaction} · ${$('test-gap').value} px`;
  }
 };
}
