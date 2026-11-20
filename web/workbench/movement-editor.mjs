const styles=[[0,'Run'],[1,'Step dash'],[2,'Hover dash'],[3,'Teleport']];
export const MOVEMENT_GROUPS=[
 ['Walking','Ground movement and velocity carried into attacks.', [['walkSpeed','Forward walk speed'],['backWalkSpeed','Backward walk speed'],['attackFriction','Attack friction']]],
 ['66 · Forward movement','Choose a movement style, then tune the values that it uses.', [['forwardStyle','66 style',styles],['runSpeed','Forward run speed'],['runAcceleration','Run acceleration'],['stepSpeed','66 burst speed'],['stepFrames','66 burst duration'],['teleportDistance','66 teleport distance']]],
 ['44 · Backward movement','Backward movement has its own style and speed.', [['backStyle','44 style',styles],['backRunSpeed','Backward run speed'],['backSpeed','44 burst speed'],['backFrames','44 burst duration'],['backTeleportDistance','44 teleport distance']]],
 ['Hover & ground teleport','Shared settings for these movement styles.', [['hoverHeight','Ground hover height'],['hoverRiseSpeed','Hover rise speed'],['teleportStartup','Ground teleport startup']]],
 ['Jumping','Launch, steering, gravity and extra jumps.', [['jumpSpeed','Jump upward speed'],['jumpForwardSpeed','Forward jump steering'],['jumpBackSpeed','Backward jump steering'],['gravity','Gravity'],['prejumpFrames','Prejump override (−1 uses match rule)'],['airJumps','Additional air jumps']]],
 ['Air dash','Stops current velocity, pauses, then applies the forward burst.', [['airDashEnabled','Enable air dash','flag'],['airDashStyle','Air forward style',styles],['airDashSpeed','Air forward speed'],['airDashPauseFrames','Air forward pause'],['airDashFrames','Air forward burst duration']]],
 ['Air backdash','Independent backward air movement. Shares the per-jump use allowance.', [['airBackdashEnabled','Enable air backdash','flag'],['airBackdashStyle','Air backward style',styles],['airBackdashSpeed','Air backward speed'],['airBackdashPauseFrames','Air backward pause'],['airBackdashFrames','Air backward burst duration'],['airDashUses','Air dash uses per jump']]],
 ['Pushblock / Faultless Defense','Hold back + FD. −1 inherits match rules. 100 meter units = 1% Momentum.', [['fdEnabled','Enable Faultless Defense','flag'],['fdPushPercent','Pushback multiplier (%)'],['fdDrain','Ground drain per frame'],['fdAirDrain','Air drain per frame'],['fdBlockCost','Base cost per blocked hit']]],
];
export function movementInactiveReason(key,p){
 key=key.replace(/^movement-/, '');
 if(key==='runSpeed'&&p.forwardStyle!==0)return 'Used by a forward Run.';
 if(key==='backRunSpeed'&&p.backStyle!==0)return 'Used by a backward Run.';
 if(key==='runAcceleration'&&p.forwardStyle!==0&&p.backStyle!==0)return 'Used by Run movement.';
 if(key==='stepSpeed'&&![1,2].includes(p.forwardStyle))return 'Used by forward Step dash or Hover dash.';
 if(key==='backSpeed'&&![1,2].includes(p.backStyle))return 'Used by backward Step dash or Hover dash.';
 if(key==='stepFrames'&&p.forwardStyle===0)return 'Run continues while held; burst duration applies to other styles.';
 if(key==='backFrames'&&p.backStyle===0)return 'Run continues while held; burst duration applies to other styles.';
 if(key==='teleportDistance'&&p.forwardStyle!==3&&!(p.airDashEnabled&&p.airDashStyle===3))return 'Used by forward ground or air Teleport.';
 if(key==='backTeleportDistance'&&p.backStyle!==3&&!(p.airBackdashEnabled&&p.airBackdashStyle===3))return 'Used by backward ground or air Teleport.';
 if(key==='teleportStartup'&&p.forwardStyle!==3&&p.backStyle!==3)return 'Used by ground Teleport movement.';
 if(['hoverHeight','hoverRiseSpeed'].includes(key)&&![p.forwardStyle,p.backStyle].includes(2))return 'Used by ground Hover dash movement.';
 if(key==='airDashUses'&&!p.airDashEnabled&&!p.airBackdashEnabled)return 'Enable an air dash direction first.';
 if(['airDashStyle','airDashSpeed','airDashPauseFrames','airDashFrames'].includes(key)&&!p.airDashEnabled)return 'Enable air dash first.';
 if(['airBackdashStyle','airBackdashSpeed','airBackdashPauseFrames','airBackdashFrames'].includes(key)&&!p.airBackdashEnabled)return 'Enable air backdash first.';
 if(key==='airDashSpeed'&&p.airDashStyle===3||key==='airBackdashSpeed'&&p.airBackdashStyle===3)return 'Air teleports use distance rather than burst speed.';
 if(key.startsWith('fd')&&key!=='fdEnabled'&&!p.fdEnabled)return 'Enable Faultless Defense first.';
 return '';
}
const pixels=new Set(['walkSpeed','backWalkSpeed','runSpeed','backRunSpeed','runAcceleration','stepSpeed','backSpeed','attackFriction','jumpSpeed','jumpForwardSpeed','jumpBackSpeed','gravity','airDashSpeed','airBackdashSpeed','hoverHeight','hoverRiseSpeed','teleportDistance','backTeleportDistance']);
export const MOVEMENT_ACTIONS=[['idle','Idle stance'],['crouch','Crouching idle'],['rolling','Tapper rolling stance'],['walk','Walk forward'],['backWalk','Walk backward'],['forward','66 / forward macro'],['back','44 / backward macro'],['jump','Neutral jump'],['forwardJump','Forward jump'],['backJump','Backward jump'],['airForward','Air dash'],['airBack','Air backdash'],['airJump','Air jump'],['fd','Pushblock / FD']];
export function renderMovement({el,panels,profile,limits,onChange,onError,action,onAction}){
 const container=el('div',{class:'movement-editor'}),intro=el('section',{class:'form-section'}),choice=el('select',{id:'movement-action'});
 choice.append(...MOVEMENT_ACTIONS.map(([value,label])=>el('option',{value},label)));choice.value=action;choice.onchange=()=>onAction(choice.value);
 intro.append(el('h2',{},'Character movement'),el('p',{},'All values are per character and included in Download JSON. Use the shared preview to play or scrub the result.'),el('label',{for:'movement-action'},'Preview action'),choice);container.append(intro);
 for(const [index,[title,intro,fields]] of MOVEMENT_GROUPS.entries()){
  const makeField=setting=>{
   const [key,label,type]=fields.find(([key])=>'movement-'+key===setting);
   const field=el('div',{class:'field'}),id='field-movement-'+key,scale=pixels.has(key)?100:1,range=limits[key];let input;
   if(Array.isArray(type)){input=el('select',{id});input.append(...type.map(([v,t])=>el('option',{value:v},t)));input.value=profile[key];}
   else if(type==='flag'){input=el('input',{id,type:'checkbox',checked:!!profile[key]});}
   else {input=el('input',{id,type:'number',min:range.min/scale,max:range.max/scale,step:1/scale,inputmode:range.min<0?'text':scale===1?'numeric':'decimal'});input.value=profile[key]/scale;}
   field.append(el('label',{for:id},label),input);
   if(pixels.has(key))field.append(el('small',{class:'hint'},key.includes('Distance')||key==='hoverHeight'?'px':key==='gravity'||key==='runAcceleration'||key==='attackFriction'?'px/f²':'px/f'));
   if(key.endsWith('Frames')||key==='teleportStartup')field.append(el('small',{class:'hint'},'f · 60 frames per second'));
   field.append(el('span',{id:'error-movement-'+key,class:'error','aria-live':'polite'}));
   const update=()=>{try{const raw=type==='flag'?Number(input.checked):Number(input.value)*scale,value=Math.round(raw);if(input.value===''||!Number.isFinite(raw)||Math.abs(raw-value)>1e-6||value<range.min||value>range.max)throw new Error(`Use ${range.min/scale}–${range.max/scale}.`);onChange(key,value);onError('movement-'+key,'');}catch(e){onError('movement-'+key,e.message);}};
   input.addEventListener(Array.isArray(type)||type==='flag'?'change':'input',update);return field;
  };
  const group={id:'movement-'+index,title,intro,fields:fields.map(([key])=>'movement-'+key),reason:(key,_move,c)=>movementInactiveReason(key,c.movement),active:(_move,c)=>fields.some(([key])=>!movementInactiveReason(key,c.movement))};
  if(panels)container.append(panels.create(group,makeField));
  else {const section=el('section',{class:'form-section'});section.append(el('h2',{},title),...group.fields.map(makeField));container.append(section);}
 }return container;
}
