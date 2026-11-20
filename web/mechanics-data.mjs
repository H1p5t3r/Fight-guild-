export const MECHANIC_FIELDS = ["mechanic", "tetherSpeed", "tetherFrames", "bleedInitial", "bleedTickDamage", "bleedTickFrames", "bleedDuration", "bleedBlockPercent", "bleedCap", "variantStartup", "variantActive", "variantRecovery", "variantDamage", "variantRange", "variantSpeed", "variantLift", "variantHitstun", "variantKnockdown"];
export function upgradeMechanics(data,defaults) {
  if(data?.schema!==16||data.coreVersion!==16)return data;
  const next=structuredClone(data);
  next.characters?.forEach((c,i)=>c.moves?.forEach((m,j)=>{for(const key of MECHANIC_FIELDS)m[key]=defaults.characters[i].moves[j][key];}));
  next.schema=next.coreVersion=17;return next;
}
