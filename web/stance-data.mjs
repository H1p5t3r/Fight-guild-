export const STANCE_DEFAULTS = {"stanceRequired": 0, "stanceChange": 0, "actionType": 0, "holdFollow": -1, "holdFrame": 0, "holdButton": 2, "guardFollow": -1, "proximityMove": -1, "proximityRange": 8000, "startupTravel": 0, "diveSpeedX": 0, "diveSpeedY": -1100, "groundBounce": 0, "wallBounce": 0, "crumpleFrames": 0, "airCounterKnockdown": 0, "hurtWindowStart": 0, "hurtWindowEnd": 0, "hurtWindowMask": 15, "semiAirStart": 0, "semiAirEnd": 0, "armorFrames": 0, "armorHits": 0, "grabFrames": 0, "finishArtPose": 0, "finishArtFrame": 0};
export function upgradeStances(data,defaults) {
  if(data?.schema!==17||data.coreVersion!==17)return data;
  const next=structuredClone(data);
  next.characters?.forEach((c,i)=>{
    c.moves?.forEach((m,j)=>{Object.assign(m,STANCE_DEFAULTS);if(j>=32)m.enabled=0;});
    if(c.moves?.length===32)c.moves.push(...structuredClone(defaults.characters[i].moves.slice(32)).map(m=>({...m,enabled:0})));
  });
  next.schema=next.coreVersion=18;return next;
}
