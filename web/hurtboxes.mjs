export const HURT_PHASES=['windup','active','recovery'];
export const HURT_REGIONS=['legs','torsoArms','head','extension'];
export const HURT_LABELS={legs:'Legs',torsoArms:'Torso & arms',head:'Head',extension:'Body extension'};
const object=v=>v!==null&&typeof v==='object'&&!Array.isArray(v);
export function validateHurtboxes(profiles){
  if(!object(profiles)||Object.keys(profiles).some(p=>!HURT_PHASES.includes(p)))throw new Error('Hurtboxes need windup, active or recovery phases.');
  for(const [phase,boxes] of Object.entries(profiles)){
    if(!object(boxes)||HURT_REGIONS.slice(0,3).some(r=>!Object.hasOwn(boxes,r))||Object.keys(boxes).some(r=>!HURT_REGIONS.includes(r)))throw new Error(`${phase}: use legs, torso & arms, head, and at most one body extension.`);
    for(const [region,b] of Object.entries(boxes)){
      if(!Array.isArray(b)||b.length!==4||b.some(v=>!Number.isInteger(v)||v< -50000||v>50000)||b[2]-b[0]<100||b[3]-b[1]<100)
        throw new Error(`${HURT_LABELS[region]}: each edge must be within −500 to 500 px, with width and height at least 1 px.`);
    }
  }
  return profiles;
}
export function packHurtboxes(boxes){return [boxes?Object.keys(boxes).length:0,...HURT_REGIONS.flatMap(r=>boxes?.[r]||[0,0,0,0])];}
export function unpackHurtboxes(values){return Object.fromEntries(HURT_REGIONS.slice(0,values[0]).map((r,i)=>[r,values.slice(1+i*4,5+i*4)]));}
export function upgradeHurtboxes(data){
  if(data?.schema===12&&data.coreVersion===12){
    data=structuredClone(data);data.schema=data.coreVersion=13;
    if(Array.isArray(data.characters))for(const c of data.characters)if(Array.isArray(c?.moves))for(const m of c.moves)if(object(m))m.hurtboxes??={};
  }
  return data;
}

// These flags affect vulnerability only; source coordinates and pushboxes stay intact.
export const HURT_MASK_FIELDS={windup:'hurtMaskWindup',active:'hurtMaskActive',recovery:'hurtMaskRecovery'};
export const regionEnabled=(move,phase,region)=>!!((move[HURT_MASK_FIELDS[phase]]??15)&(1<<HURT_REGIONS.indexOf(region)));
export const enabledHurtboxes=(boxes,move,phase)=>Object.fromEntries(Object.entries(boxes).filter(([region])=>regionEnabled(move,phase,region)));
export function upgradeHurtMasks(data){
  if(data?.schema!==15||data.coreVersion!==15)return data;
  const next=structuredClone(data);next.schema=next.coreVersion=16;
  for(const character of next.characters??[])for(const move of character.moves??[]){
    for(const [phase,key]of Object.entries(HURT_MASK_FIELDS))move[key]??=move.id==='6P'&&phase!=='recovery'?1:15;
  }
  return next;
}
