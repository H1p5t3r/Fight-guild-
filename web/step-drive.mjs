export const STEP_DRIVE_DEFAULTS={driveDistance:0,drivePlus:4,driveNeutralFrames:12};
export function upgradeStepDrive(data){
  if(data?.schema!==26||data.coreVersion!==26)return data;
  const next=structuredClone(data);
  for(const c of next.characters??[])for(const m of c.moves??[])Object.assign(m,STEP_DRIVE_DEFAULTS);
  next.schema=next.coreVersion=27;
  return next;
}
