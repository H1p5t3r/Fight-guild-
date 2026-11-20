import metadata from '../godot/data/combo_physics.json' with {type:'json'};
export const COMBO_FIELDS=metadata.moves;
export const COMBO_RULE_SPECS=metadata.rules;
export const COMBO_RULES=metadata.rules.map(f=>f.key);
export const COMBO_DEFAULTS=Object.fromEntries(metadata.rules.map(f=>[f.key,f.default]));
export const comboMoveDefaults=m=>({comboDecay:5,starterDecay:0,groundHitSpeed:Math.ceil(m.pushback/6),airHitSpeed:Math.ceil(m.airPushback/6)});
// Upgrade physics without rewriting authored routes, notes, geometry or artwork.
export function upgradeComboPhysics(data){
  if(data?.schema!==25||data.coreVersion!==25)return data;
  const next=structuredClone(data);
  next.comboRules={...COMBO_DEFAULTS};
  for(const c of next.characters??[])for(const m of c.moves??[]){
    Object.assign(m,comboMoveDefaults(m));
  }
  next.schema=next.coreVersion=26;
  return next;
}
