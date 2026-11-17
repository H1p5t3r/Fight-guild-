const styles=[[0,'Run'],[1,'Step dash'],[2,'Hover dash'],[3,'Teleport']];
export const MOVEMENT_GROUPS=[
 ['Walk & run','Walking uses the new walk cycle; sustained runs use the run cycle.', [['walkSpeed','Forward walk speed'],['backWalkSpeed','Backward walk speed'],['runSpeed','Forward run speed'],['backRunSpeed','Backward run speed'],['runAcceleration','Run acceleration'],['attackFriction','Attack friction']]],
 ['66 / 44 movement','Double-tap a direction, or use the dash macro. Teleports have startup and recovery, with no added invulnerability.', [['forwardStyle','66 style',styles],['backStyle','44 style',styles],['stepSpeed','66 burst speed'],['stepFrames','66 burst duration'],['backSpeed','44 burst speed'],['backFrames','44 burst duration'],['hoverHeight','Ground hover height'],['hoverRiseSpeed','Hover rise speed'],['teleportDistance','66 teleport distance'],['backTeleportDistance','44 teleport distance'],['teleportStartup','Teleport startup']]],
 ['Jumps & air movement','Forward momentum carries into jumps and attacks. Air action counts reset on landing. A run selected in the air is a timed horizontal burst.', [['jumpSpeed','Jump upward speed'],['jumpForwardSpeed','Forward jump steering'],['jumpBackSpeed','Backward jump steering'],['gravity','Gravity'],['prejumpFrames','Prejump override (−1 uses match rule)'],['airJumps','Additional air jumps'],['airDashEnabled','Enable air dash','flag'],['airBackdashEnabled','Enable air backdash','flag'],['airDashUses','Air dash uses per jump'],['airDashStyle','Air forward style',styles],['airBackdashStyle','Air backward style',styles],['airDashSpeed','Air forward speed'],['airBackdashSpeed','Air backward speed'],['airDashFrames','Air forward duration'],['airBackdashFrames','Air backward duration']]],
 ['Pushblock / Faultless Defense','Hold back + FD. Overrides use −1 to inherit match rules. Costs are meter units: 100 units = 1% Momentum.', [['fdEnabled','Enable Faultless Defense','flag'],['fdPushPercent','Pushback multiplier (%)'],['fdDrain','Ground drain per frame'],['fdAirDrain','Air drain per frame'],['fdBlockCost','Base cost per blocked hit']]],
];
const pixels=new Set(['walkSpeed','backWalkSpeed','runSpeed','backRunSpeed','runAcceleration','stepSpeed','backSpeed','attackFriction','jumpSpeed','jumpForwardSpeed','jumpBackSpeed','gravity','airDashSpeed','airBackdashSpeed','hoverHeight','hoverRiseSpeed','teleportDistance','backTeleportDistance']);
export const MOVEMENT_ACTIONS=[['idle','Idle stance'],['walk','Walk forward'],['backWalk','Walk backward'],['forward','66 / forward macro'],['back','44 / backward macro'],['jump','Neutral jump'],['forwardJump','Forward jump'],['backJump','Backward jump'],['airForward','Air dash'],['airBack','Air backdash'],['airJump','Air jump'],['fd','Pushblock / FD']];
export function renderMovement({el,profile,limits,onChange,onError,action,onAction}){
 const container=el('div',{class:'movement-editor'}),intro=el('section',{class:'form-section'}),choice=el('select',{id:'movement-action'});
 choice.append(...MOVEMENT_ACTIONS.map(([value,label])=>el('option',{value},label)));choice.value=action;choice.onchange=()=>onAction(choice.value);
 intro.append(el('h2',{},'Character movement'),el('p',{},'All values are per character and included in Download JSON. Use the shared preview to play or scrub the result.'),el('label',{for:'movement-action'},'Preview action'),choice);container.append(intro);
 for(const [title,intro,fields] of MOVEMENT_GROUPS){const section=el('section',{class:'form-section'}),grid=el('div',{class:'field-grid'});section.append(el('h2',{},title),el('p',{},intro));
  for(const [key,label,type]of fields){const field=el('div',{class:'field'}),id='field-movement-'+key,scale=pixels.has(key)?100:1,range=limits[key];let input;
   if(Array.isArray(type)){input=el('select',{id});input.append(...type.map(([v,t])=>el('option',{value:v},t)));input.value=profile[key];}
   else if(type==='flag'){input=el('input',{id,type:'checkbox',checked:!!profile[key]});}
   else {input=el('input',{id,type:'number',min:range.min/scale,max:range.max/scale,step:1/scale});input.value=profile[key]/scale;}
   field.append(el('label',{for:id},label),input);
   if(pixels.has(key))field.append(el('small',{class:'hint'},key.includes('Distance')||key==='hoverHeight'?'px':key==='gravity'||key==='runAcceleration'||key==='attackFriction'?'px/f²':'px/f'));
   if(key.endsWith('Frames')||key==='teleportStartup')field.append(el('small',{class:'hint'},'f · 60 frames per second'));
   field.append(el('span',{id:'error-movement-'+key,class:'error','aria-live':'polite'}));
   const update=()=>{try{const raw=type==='flag'?Number(input.checked):Number(input.value)*scale,value=Math.round(raw);if(input.value===''||!Number.isFinite(raw)||Math.abs(raw-value)>1e-6||value<range.min||value>range.max)throw new Error(`Use ${range.min/scale}–${range.max/scale}.`);onChange(key,value);onError('movement-'+key,'');}catch(e){onError('movement-'+key,e.message);}};
   input.addEventListener(Array.isArray(type)||type==='flag'?'change':'input',update);grid.append(field);
  }section.append(grid);container.append(section);
 }return container;
}
