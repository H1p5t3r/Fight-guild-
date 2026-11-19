import {MAX_SEQUENCE_STEPS,MAX_SEQUENCE_DELAY} from './sequences.mjs';
import {inputName,moveName} from './model.mjs';

export function renderSequence({el,moves,queue,slot,valid,onChange,onError,onSeek}){
 const section=el('section',{class:'form-section sequence-editor'});
 section.append(el('h2',{},'Sequence test'),el('p',{},'Queue moves to test real cancels, links and spacing. Each input uses the first legal opportunity, plus your delay. Hitstop does not consume delay frames.'));
 const choices=selected=>moves.flatMap((m,i)=>m.enabled||i===selected?[el('option',{value:i},`${moveName(m)}${inputName(m)!==moveName(m)?' · '+inputName(m):''}${m.enabled?'':' · disabled'}`)]:[]);
 const list=el('ol',{class:'sequence-list',id:'sequence-list','aria-label':'Queued moves'});
 queue.forEach((step,i)=>{
  const row=el('li',{'data-sequence-step':i,class:'sequence-row'}),controls=el('div',{class:'sequence-fields'});
  const move=el('select',{id:`sequence-move-${i}`,'aria-label':`Step ${i+1} move`});move.append(...choices(step.move));move.value=step.move;
  move.onchange=()=>{if(!valid()){move.value=step.move;return;}const next=structuredClone(queue);next[i].move=Number(move.value);onChange(next);};
  const delay=el('input',{id:`field-sequence-delay-${i}`,type:'number',min:0,max:MAX_SEQUENCE_DELAY,step:1,inputmode:'numeric','aria-label':`Step ${i+1} delay frames`,'aria-describedby':`error-sequence-delay-${i}`});delay.value=step.delay;
  delay.oninput=()=>{
   const n=Number(delay.value);
   if(!delay.value.trim()||!Number.isInteger(n)||n<0||n>MAX_SEQUENCE_DELAY){onError(`sequence-delay-${i}`,`Use 0–${MAX_SEQUENCE_DELAY} whole frames.`);return;}
   onError(`sequence-delay-${i}`,'');const next=structuredClone(queue);next[i].delay=n;queue=next;onChange(next,false,`sequence/delay/${i}`);
  };
  const delayLabel=el('label',{},'Delay +f');delayLabel.append(delay);
  controls.append(el('span',{class:'sequence-number','aria-hidden':'true'},String(i+1)),move,delayLabel);
  const actions=el('div',{class:'sequence-actions'}),seek=el('button',{type:'button','data-sequence-seek':i,disabled:''},'Waiting for test');seek.onclick=()=>{if(valid())onSeek(i);};actions.append(seek);
  for(const [label,delta]of [['↑',-1],['↓',1]]){
   const button=el('button',{type:'button','aria-label':`Move step ${i+1} ${delta<0?'up':'down'}`},label);button.disabled=i+delta<0||i+delta>=queue.length;
   button.onclick=()=>{if(!valid())return;const next=structuredClone(queue);[next[i],next[i+delta]]=[next[i+delta],next[i]];onChange(next);};actions.append(button);
  }
  const remove=el('button',{type:'button',class:'quiet','aria-label':`Remove step ${i+1}`},'×');remove.onclick=()=>{if(valid())onChange(queue.filter((_,j)=>i!==j));};actions.append(remove);
  row.append(controls,el('span',{class:'error',id:`error-sequence-delay-${i}`,'aria-live':'polite'}),actions);list.append(row);
 });
 section.append(list);
 if(!queue.length)section.append(el('p',{class:'empty'},'Add a move below to start your sequence.'));
 const addRow=el('div',{class:'sequence-add'}),choice=el('select',{id:'sequence-add-move','aria-label':'Move to add'});choice.append(...choices(slot));choice.value=slot;
 const add=el('button',{id:'sequence-add',type:'button',class:'primary'},'Add move');add.disabled=queue.length>=MAX_SEQUENCE_STEPS;
 add.onclick=()=>{if(valid())onChange([...queue,{move:Number(choice.value),delay:0}]);};addRow.append(choice,add);section.append(addRow);
 section.append(el('p',{id:'sequence-result',class:'sequence-result',role:'status'},'Add moves, then play or scrub the shared preview.'),el('p',{class:'hint'},'Up to 12 moves per fighter. Queues travel with your workshop JSON. The sequence stops if an input cannot start its requested move; it never forces a cancel. Air attacks insert a jump when needed.'));
 return section;
}

export function showSequenceResult(record,index){
 if(!record?.sequence)return;
 const current=record.frames[index]?.sequenceStep;
 for(const row of document.querySelectorAll('[data-sequence-step]')){
  const n=Number(row.dataset.sequenceStep),step=record.steps[n],button=row.querySelector('[data-sequence-seek]');
  row.classList.toggle('current',n===current);row.classList.toggle('failed',!!step?.error);
  if(n===current)row.setAttribute('aria-current','step');else row.removeAttribute('aria-current');
  button.disabled=step?.start===undefined;button.textContent=step?.error?'Input unavailable':step?.start!==undefined?`Frame ${step.start} · ${step.route}`:'Not reached';
 }
 const status=document.getElementById('sequence-result');
 const summary=record.steps.length?`${record.steps.filter(s=>s.start!==undefined).length} / ${record.steps.length} moves started · ${record.contacts.filter(c=>c.event!==2).length} hits · max combo ${record.maxCombo} · ${record.totalDamage} damage${record.warnings.length?' · '+record.warnings.join(' '):''}`:'Add a move to start the test.';
 if(status&&status.textContent!==summary)status.textContent=summary;
}
