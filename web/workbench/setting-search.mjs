import {COMBO_RULE_SPECS} from '../combo-rules.mjs';
import {GROUPS,SPECS,TABS,ART_FIELDS} from './specs.mjs';
import {MOVEMENT_GROUPS} from './movement-editor.mjs';

export const SETTING_INDEX=[
 ...COMBO_RULE_SPECS.map(f=>({key:"rule-"+f.key,tab:"timing",label:f.label,group:"Shared combo physics",hint:f.help,id:"field-rule-"+f.key})),
 ...GROUPS.flatMap(group=>group.fields.map(key=>({key,tab:group.tab,label:SPECS[key].label,group:group.title,hint:SPECS[key].hint,id:key.startsWith('hurtMask')?'hurt-enabled-legs':SPECS[key].type==='mask'?`field-${key}${SPECS[key].unified?'-unified':'-0'}`:'field-'+key}))),
 ...MOVEMENT_GROUPS.flatMap(([group,,fields])=>fields.map(([key,label])=>({key:'movement-'+key,tab:'movement',label,group,id:'field-movement-'+key}))),
 ...ART_FIELDS.map(([key,label])=>({key:'note-'+key,tab:'art',label,group:'Art brief',id:'note-'+key})),
 {key:'hit-keys',tab:'hit',label:'Active-frame hitbox keys',group:'Hitboxes & impact',id:'hit-key-select'},
 {key:'body-boxes',tab:'hurt',label:'Body hurtbox size and regions',group:'Hurtboxes & defense',id:'hurt-region'},
];
export function findSettings(query){
 const words=query.toLowerCase().trim().split(/\s+/).filter(Boolean);if(!words.length)return [];
 return SETTING_INDEX.filter(item=>words.every(word=>`${item.key} ${item.label} ${item.group} ${item.hint||''}`.toLowerCase().includes(word)))
  .sort((a,b)=>Number(b.label.toLowerCase().includes(query.toLowerCase()))-Number(a.label.toLowerCase().includes(query.toLowerCase())))
  .slice(0,18);
}
export function createSettingSearch({el,onFind}){
 const input=document.getElementById('setting-search'),results=document.getElementById('setting-results');
 const close=()=>{results.hidden=true;results.replaceChildren();input.value='';};
 input.oninput=()=>{
  results.replaceChildren();const matches=findSettings(input.value);results.hidden=!input.value.trim();
  if(!matches.length){results.append(el('li',{class:'no-settings'},'No matching settings.'));return;}
  for(const entry of matches){
   const li=el('li'),button=el('button',{type:'button','data-setting-result':entry.key});
   button.append(el('strong',{},entry.label),el('span',{},`${TABS.find(t=>t.id===entry.tab).label} · ${entry.group}`));
   button.onclick=()=>{if(onFind(entry)!==false)close();};li.append(button);results.append(li);
  }
 };
 input.onkeydown=event=>{if(event.key==='Escape')close();if(event.key==='ArrowDown'){event.preventDefault();results.querySelector('button')?.focus();}};
 results.onkeydown=event=>{
  if(event.key==='Escape'){close();input.focus();return;}
  if(!['ArrowDown','ArrowUp'].includes(event.key))return;event.preventDefault();
  const buttons=[...results.querySelectorAll('button')],index=buttons.indexOf(document.activeElement),next=index+(event.key==='ArrowDown'?1:-1);
  if(next<0)input.focus();else buttons[Math.min(next,buttons.length-1)]?.focus();
 };
 document.addEventListener('click',event=>{if(!event.target.closest('.setting-search'))results.hidden=true;});
 input.onfocus=()=>{if(input.value.trim())input.oninput();};
}
