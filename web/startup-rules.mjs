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
  if(data?.schema!==19 || data.coreVersion!==19)return data;
  const next=structuredClone(data);
  for(const character of next.characters??[])for(const move of character.moves??[])
    if(move.category===4 && move.motion===0)move.startup=2;
  next.schema=next.coreVersion=20;
  return next;
}
