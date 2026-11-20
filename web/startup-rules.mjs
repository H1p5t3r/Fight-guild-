// Startup is the first active tick (2f startup means one windup tick).
export const startupMinimum = move => move.category===4 ? 2
  : move.button===0 && [0,1].includes(move.category) ? 3 : 5;
export const variantStartupMinimum = move => move.mechanic===2 ? 2 : 5;
export function moveFieldLimit(move,key,limits) {
  const limit=limits[key];
  return key==='startup' ? {...limit,min:startupMinimum(move)}
    : key==='variantStartup' ? {...limit,min:variantStartupMinimum(move)} : limit;
}
export function upgradeStartupRules(data) {
  if(![19,20].includes(data?.schema) || data.coreVersion!==data.schema)return data;
  const next=structuredClone(data);
  if(data.schema===19)for(const character of next.characters??[])for(const move of character.moves??[])
    if(move.category===4 && move.motion===0)move.startup=2;
  // Version 21 adds rollback presentation state only; preserve every v20 edit.
  next.schema=next.coreVersion=21;
  return next;
}
