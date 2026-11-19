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
