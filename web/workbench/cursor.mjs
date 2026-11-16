// Keep edits on the same move frame even when contact adds or removes hitstop.
export function cursorAnchor(record,index){
  const frame=record?.frames[index]?.selectedFrame;
  if(!frame)return {tick:index};
  const first=record.frames.findIndex(f=>f.selectedFrame===frame);
  return {frame,hold:index-first};
}
export function cursorIndex(record,anchor){
  if(!record?.frames.length)return 0;
  if(anchor.frame!==undefined){
    const matches=record.frames.flatMap((f,i)=>f.selectedFrame===anchor.frame?[i]:[]);
    if(matches.length)return matches[Math.min(anchor.hold||0,matches.length-1)];
    let nearest=0,distance=Infinity;
    record.frames.forEach((f,i)=>{if(f.selectedFrame&&Math.abs(f.selectedFrame-anchor.frame)<distance){nearest=i;distance=Math.abs(f.selectedFrame-anchor.frame);}});
    return nearest;
  }
  return Math.min(Math.max(0,anchor.tick||0),record.frames.length-1);
}
