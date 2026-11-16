import {MAX_HIT_KEYS,MAX_HITBOXES,HIT_OVERRIDES,keyAt,makeHitKey} from '../hitboxes.mjs';
import {attackBoxes} from './model.mjs';
const node=(tag,attrs={},text='')=>{const n=document.createElement(tag);for(const [k,v]of Object.entries(attrs)){if(k==='class')n.className=v;else if(k==='checked'||k==='disabled')n[k]=v;else n.setAttribute(k,v);}n.textContent=text;return n;};
export function renderHitEditor({move:m,frame,pack,character,boxIndex,selectedFrame,onChange,onKey,onBox,onError,valid}){
  const section=node('section',{class:'form-section hit-track-editor'});
  section.append(node('h2',{},'Active-frame hitboxes'),node('p',{},'A key holds its shapes until the next key. Active frame 1 is the first frame that can hit. Multiple boxes share one hit unless you enable separate hit numbers.'));
  if(m.category===4){section.append(node('p',{},'Throws use Throw reach and the reserved throw inputs. Their geometry and single-hit behavior are unchanged by hitbox keys.'));return section;}
  const track=m.hitboxTimeline,activeFrame=Math.max(1,Math.min(m.active,frame-m.startup+1)),current=keyAt(m,activeFrame),key=selectedFrame===null?current:track.keys.find(k=>k.frame===selectedFrame),index=track.keys.indexOf(key);
  const change=(next,render=true,group='')=>{onChange(next,render,group);};
  const row=node('label',{class:'track-toggle'}),multi=node('input',{id:'hit-multi',type:'checkbox',checked:track.multiHit});
  row.append(multi,document.createTextNode(' Allow multiple hits'));section.append(row);
  multi.onchange=()=>{if(!valid()){multi.checked=track.multiHit;return;}change({...structuredClone(m.hitboxTimeline),multiHit:multi.checked});};
  section.append(node('p',{class:'hint'},track.multiHit?'Each hit number can connect once per attack. Boxes sharing a number do not stack hits.':'All keys and boxes share one hit for this attack. Hit numbers are kept for later.'));
  const controls=node('div',{class:'track-actions'}),select=node('select',{id:'hit-key-select','aria-label':'Hitbox key'});
  select.append(node('option',{value:-1},'Base geometry · before first key'));
  track.keys.forEach((k,i)=>select.append(node('option',{value:i},`Active ${k.frame} · hit ${k.hit}${k.frame>m.active?' · beyond Active':''}`)));select.value=index;
  select.onchange=()=>{if(!valid()){select.value=index;return;}const k=track.keys[Number(select.value)];onKey(k?.frame??0);};
  const add=node('button',{id:'hit-key-add',type:'button',disabled:track.keys.length>=MAX_HIT_KEYS||current?.frame===activeFrame},`Add key at active ${activeFrame}`);
  add.onclick=()=>{if(!valid())return;const next=structuredClone(m.hitboxTimeline);next.keys.push(makeHitKey(activeFrame,current));next.keys.sort((a,b)=>a.frame-b.frame);change(next);onKey(activeFrame);};
  const remove=node('button',{id:'hit-key-remove',type:'button',disabled:!key},'Remove key');
  remove.onclick=()=>{if(!valid())return;const next=structuredClone(m.hitboxTimeline);next.keys.splice(index,1);change(next);onKey(null);};
  controls.append(select,add,remove);section.append(controls);
  if(!key){section.append(node('p',{class:'hint'},'This frame uses the ordinary hitbox settings below. Add a key to change the shape or hit data from this active frame onward.'));return section;}
  section.append(node('p',{class:'track-current'},`Editing active-frame ${key.frame} key · move frame ${m.startup+key.frame-1}`));
  if(key.frame>m.active)section.append(node('p',{class:'hint'},'This key is beyond the current Active duration. You can edit or remove it here; it has no collision until Active includes its frame.'));
  const grid=node('div',{class:'field-grid'});
  const field=(name,label,value,min,max,step,callback,disabled=false)=>{
    const wrap=node('div',{class:'field'}),id='field-hit-key-'+name,input=node('input',{id,type:'number',min,max,step,disabled,'aria-describedby':'error-hit-key-'+name});input.value=value;
    wrap.append(node('label',{for:id},label),input,node('span',{id:'error-hit-key-'+name,class:'error','aria-live':'polite'}));
    const edit=()=>{try{const value=Number(input.value);if(!input.value.trim()||!Number.isFinite(value)||value<min||value>max||Math.abs(value/step-Math.round(value/step))>1e-6)throw new Error(`Use ${min} to ${max}${step===1?', whole numbers.':', up to two decimals.'}`);callback(value);onError('hit-key-'+name,'');}catch(error){onError('hit-key-'+name,error.message);}};
    if(name==='frame')input.onchange=edit;else input.oninput=edit;
    return wrap;
  };
  const update=(name,value,group='')=>{const next=structuredClone(m.hitboxTimeline);next.keys[index][name]=value;change(next,false,group);if(name==='hit')select.options[index+1].textContent=`Active ${key.frame} · hit ${value}${key.frame>m.active?' · beyond Active':''}`;};
  grid.append(field('frame','Key starts at active frame',key.frame,1,120,1,v=>{const next=structuredClone(m.hitboxTimeline);next.keys[index].frame=v;next.keys.sort((a,b)=>a.frame-b.frame);change(next,true,'key-frame');onKey(v);}),field('hit','Hit number',key.hit,1,32,1,v=>update('hit',v),!track.multiHit));
  HIT_OVERRIDES.forEach((name,i)=>grid.append(field(name,['Hit damage','Hit hitstun','Hit blockstun','Hit hitstop'][i],key[name],-1,[1000,180,180,30][i],1,v=>update(name,v,`hit/${character}/${m.id}/${key.frame}/${name}`))));
  section.append(grid,node('p',{class:'hint'},'−1 inherits the move’s normal damage or timing. Hit numbers matter only with Allow multiple hits enabled. Damage still uses combo scaling.'));
  const geometry=node('div',{class:'track-actions'}),base=node('button',{type:'button',id:'hit-key-base'},'Use base geometry'),blank=node('button',{type:'button',id:'hit-key-gap'},'No hitboxes · gap'),newBox=node('button',{type:'button',id:'hit-box-add',disabled:key.boxes?.length>=MAX_HITBOXES},'Add hitbox');
  base.onclick=()=>{if(valid())update('boxes',null),onBox(0);};blank.onclick=()=>{if(valid())update('boxes',[]),onBox(0);};
  newBox.onclick=()=>{if(!valid())return;const next=structuredClone(m.hitboxTimeline),currentKey=next.keys[index],boxes=currentKey.boxes||attackBoxes({...m,hitboxTimeline:{multiHit:false,keys:[]}},frame,pack.collisions[character].push),b=structuredClone(boxes[boxIndex]||boxes[0]||[0,0,4000,4000]);currentKey.boxes=currentKey.boxes?[...currentKey.boxes,b]:[b];change(next);onBox(next.keys[index].boxes.length-1);};
  geometry.append(base,blank,newBox);section.append(geometry);
  if(key.boxes===null){section.append(node('p',{class:'hint'},'Using base geometry, including the moving spear on hook attacks. Add hitbox starts a custom rectangular profile and replaces that geometry.'));return section;}
  if(!key.boxes.length){section.append(node('p',{class:'hint'},'This key has no collision. The attack remains in its active phase until the next key.'));return section;}
  const selected=Math.min(boxIndex,key.boxes.length-1),box=key.boxes[selected],chooser=node('select',{id:'hit-box-select','aria-label':'Selected hitbox'}),deleteBox=node('button',{type:'button',id:'hit-box-remove'},'Remove selected hitbox');
  key.boxes.forEach((_,i)=>chooser.append(node('option',{value:i},`Hitbox ${i+1}`)));chooser.value=selected;chooser.onchange=()=>{if(valid())onBox(Number(chooser.value));};
  deleteBox.onclick=()=>{if(!valid())return;const next=structuredClone(m.hitboxTimeline);next.keys[index].boxes.splice(selected,1);change(next);onBox(0);};
  section.append(chooser,deleteBox);
  const dimensions=node('div',{class:'field-grid'}),values={left:box[0]/100,bottom:box[1]/100,width:(box[2]-box[0])/100,height:(box[3]-box[1])/100};
  for(const [name,label]of [['left','Hitbox left · px'],['bottom','Hitbox bottom · px'],['width','Hitbox width · px'],['height','Hitbox height · px']])dimensions.append(field(name,label,values[name],['width','height'].includes(name)?1:-500,['width','height'].includes(name)?1000:500,.01,v=>{
    const next=structuredClone(m.hitboxTimeline),b=next.keys[index].boxes[selected],n=Math.round(v*100);
    if(name==='left'){b[2]+=n-b[0];b[0]=n;}else if(name==='bottom'){b[3]+=n-b[1];b[1]=n;}else if(name==='width')b[2]=b[0]+n;else b[3]=b[1]+n;
    change(next,false,`hit/${character}/${m.id}/${key.frame}/${selected}/${name}`);
  }));section.append(dimensions,node('p',{class:'hint'},'Up to four boxes per key and 32 keys per move. Use the orange handles to edit the selected box on an active frame.'));
  return section;
}
