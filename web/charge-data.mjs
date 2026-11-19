// New contextual charged slots never become attacks in an older user's draft.
export function upgradeCharges(data,defaults) {
  if(data?.schema!==18||data.coreVersion!==18)return data;
  const next=structuredClone(data);
  next.characters?.forEach((c,i)=>{
    if(c.moves?.length===43)c.moves.push(...structuredClone(defaults.characters[i].moves.slice(43,45)).map(m=>({...m,enabled:0})));
  });
  next.schema=next.coreVersion=19;
  return next;
}
