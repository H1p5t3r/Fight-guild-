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

// Version 22 adds the universal air-dash pause; all earlier tuning stays intact.
export function upgradeAirDash(data,defaults){
  if(data?.schema!==21||data.coreVersion!==21)return data;
  const next=structuredClone(data);
  next.characters?.forEach((c,i)=>{
    if(!c.movement)return;
    for(const key of ['airDashPauseFrames','airBackdashPauseFrames'])
      c.movement[key]=defaults.characters[i].movement[key];
  });
  next.schema=next.coreVersion=22;
  return next;
}
