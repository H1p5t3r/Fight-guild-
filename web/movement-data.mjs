// Schema 15 adds movement and projectile authoring. Older edits remain authoritative.
// Former smear fields are retained as inactive compatibility data.
export function upgradeMovement(data,defaults){
  if(data?.schema!==14||data.coreVersion!==14)return data;
  const next=structuredClone(data);
  next.characters?.forEach((c,i)=>{
    c.movement={...defaults.characters[i].movement,...c.movement};
    c.moves?.forEach((m,j)=>{for(const [key,value] of Object.entries(defaults.characters[i].moves[j]))if(!(key in m))m[key]=structuredClone(value);});
  });
  next.schema=next.coreVersion=15;
  return next;
}
