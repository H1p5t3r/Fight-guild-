// Schema 24 adds explicit line actions without changing older status mechanics.
export const LINE_FIELDS = ['tetherDuration','tetherRange','tetherGap'];
export const LINE_DEFAULTS = {tetherDuration:180,tetherRange:45000,tetherGap:6000};
export function upgradeLineDrive(data){
  if(data?.schema!==23||data.coreVersion!==23)return data;
  const next=structuredClone(data);
  for(const c of next.characters??[])for(const m of c.moves??[])Object.assign(m,LINE_DEFAULTS);
  next.schema=next.coreVersion=24;
  return next;
}

// Schema 25 retires the chase role. Preserve authored data and notes in old
// drafts, but disable that slot; its dormant scalars can still be repurposed.
export function upgradePullDrive(data){
  if(data?.schema!==24||data.coreVersion!==24)return data;
  const next=structuredClone(data);
  for(const c of next.characters??[])for(const m of c.moves??[]){
    if(m.mechanic===5){m.mechanic=0;m.enabled=0;}
  }
  next.schema=next.coreVersion=25;
  return next;
}
