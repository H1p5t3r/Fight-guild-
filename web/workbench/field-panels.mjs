import {groupEnabled,inactiveReason} from './field-layout.mjs';

const STORAGE='fight-guild.workshop-layout.v2';
export class FieldPanels{
 constructor({el,move,character,context,valid}){
  Object.assign(this,{el,move,character,context,valid});this.groups=new Map();
  try{this.preferences=JSON.parse(localStorage.getItem(STORAGE))||{};}catch{this.preferences={};}
  if(typeof this.preferences!=='object'||Array.isArray(this.preferences))this.preferences={};
  for(const key of ['panels','reveal','help'])if(!this.preferences[key]||typeof this.preferences[key]!=='object'||Array.isArray(this.preferences[key]))this.preferences[key]={};
 }
 get all(){return this.preferences.all===true;}
 save(){try{localStorage.setItem(STORAGE,JSON.stringify(this.preferences));}catch{}}
 key(group){return `${this.all?'all':'relevant'}/${this.context()}/${group.id}`;}
 begin(){this.groups.clear();}
 create(group,field){
  const {el}=this,key=this.key(group),panel=el('details',{class:'field-panel','data-panel':group.id}),summary=el('summary'),title=el('span',{class:'panel-title'},group.title),count=el('span',{class:'panel-count'});
  summary.append(title,count);panel.append(summary);
  const body=el('div',{class:'panel-body'});if(group.intro)body.append(el('p',{class:'panel-intro'},group.intro));
  const grid=el('div',{class:'field-grid'});
  for(const setting of group.fields){
   const node=field(setting);node.dataset.setting=setting;
   const hint=node.querySelector('.hint'),label=node.querySelector('label,legend');
   if(hint&&label&&hint.textContent.length>24&&!setting.startsWith('movement-')){
    hint.id||='hint-'+setting;
    const help=el('button',{type:'button',class:'field-help','aria-label':`Help: ${label.textContent}`,'aria-controls':hint.id,'aria-expanded':String(!!this.preferences.help[setting])},'?');
    hint.hidden=!this.preferences.help[setting];
    help.onclick=()=>{hint.hidden=!hint.hidden;help.setAttribute('aria-expanded',String(!hint.hidden));this.preferences.help[setting]=!hint.hidden;this.save();};
    if(label.tagName==='LEGEND'){label.classList.add('field-heading');label.append(help);}
    else{const heading=el('div',{class:'field-heading'});label.replaceWith(heading);heading.append(label,help);}
   }
   grid.append(node);
  }
  const show=el('button',{type:'button',class:'show-inactive'});
  show.onclick=()=>{if(!this.valid())return;this.preferences.reveal[key]=!this.preferences.reveal[key];this.save();this.update();};
  body.append(grid,show);panel.append(body);
  const item={group,panel,summary,count,grid,show,key};this.groups.set(group.id,item);
  summary.onclick=event=>{
   event.preventDefault();if(panel.open&&!this.valid())return;
   this.preferences.panels[key]=!panel.open;panel.open=!panel.open;this.save();
  };
  return panel;
 }
 update(){
  const move=this.move(),character=this.character();
  for(const item of this.groups.values()){
   const {group,panel,count,grid,show,key}=item,active=groupEnabled(group,move,character);
   let inactive=0,hidden=0;
   for(const node of grid.children){
    const reason=group.reason?group.reason(node.dataset.setting,move,character):inactiveReason(node.dataset.setting,move);if(reason)inactive++;
    const error=!!node.querySelector('[aria-invalid="true"]'),focused=node.contains(document.activeElement);
    node.hidden=!!reason&&!this.all&&!this.preferences.reveal[key]&&!error&&!focused;
    if(node.hidden)hidden++;
    node.classList.toggle('inactive-setting',!!reason);node.dataset.inactiveReason=reason;
    let hint=node.querySelector('.inactive-reason');
    if(reason&&!hint){hint=this.el('p',{class:'inactive-reason'});node.append(hint);}
    if(hint){hint.textContent=reason;hint.hidden=!reason;}
   }
   const enabled=group.fields.length-inactive;
   count.textContent=group.value?group.value(move,character):active?`${enabled} field${enabled===1?'':'s'}${inactive&&!group.hideInactiveCount?' · '+inactive+' inactive':''}`:inactive===group.fields.length?'Inactive':'Optional';
   panel.classList.toggle('inactive-panel',!active);
   show.hidden=!inactive||this.all||!!group.hideInactiveCount;show.textContent=hidden?`Show ${hidden} inactive field${hidden===1?'':'s'}`:'Hide inactive fields';
   // If every field is inactive, opening its labelled group should still let
   // the user inspect retained values without another reveal click.
   if(!enabled){for(const node of grid.children)node.hidden=false;show.hidden=true;}
   const mustStayOpen=!!grid.querySelector('[aria-invalid="true"]')||grid.contains(document.activeElement);
   panel.hidden=!!group.contextual&&!this.all&&!active&&!this.preferences.reveal[key]&&!mustStayOpen;
   panel.open=mustStayOpen||(this.preferences.panels[key]??(this.all||(group.defaultOpen??active)));
  }
 }
 setAll(value){this.preferences.all=value;this.save();}
 reveal(setting){
  for(const {group,panel,key}of this.groups.values())if(group.fields.includes(setting)){
   this.preferences.panels[key]=true;this.preferences.reveal[key]=true;panel.open=true;this.save();this.update();return true;
  }
  return false;
 }
}
