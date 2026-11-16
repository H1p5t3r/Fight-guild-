// Distances stay in the core's integer hundredths of a game pixel. Screen zoom
// only affects projection; none of these measurements use sprite dimensions.
export const pixels=value=>`${Number((value/100).toFixed(2))} px`;
export function measureDistances(players,pushboxes,attackBoxes=[],selectedBox=null){
  const [a,b]=players,roots={from:a.x,to:b.x,value:Math.abs(b.x-a.x)};
  let body=null;
  if(pushboxes[0]&&pushboxes[1]){
    const [left,right]=[...pushboxes].sort((a,b)=>a[0]-b[0]);
    if(left[2]<=right[0])body={from:left[2],to:right[0],value:right[0]-left[2],overlap:false};
    else{const from=Math.max(left[0],right[0]),to=Math.min(left[2],right[2]);body={from,to,value:to-from,overlap:true};}
  }
  const front=attackBoxes.length?Math.max(...attackBoxes.map(box=>box[2])):null;
  return {roots,body,reach:front===null?null:{from:a.x,to:a.x+a.facing*front,value:front,top:a.y+Math.max(...attackBoxes.map(box=>box[3]))},
    selected:selectedBox?{width:selectedBox[2]-selectedBox[0],height:selectedBox[3]-selectedBox[1]}:null};
}
export function distanceSummary(measures){
  const parts=[`Root spacing ${pixels(measures.roots.value)}`];
  if(measures.body)parts.push(`${measures.body.overlap?'Body overlap':'Body gap'} ${pixels(measures.body.value)}`);
  if(measures.reach)parts.push(`Box front ${pixels(measures.reach.value)}`);
  if(measures.selected)parts.push(`Selected box ${pixels(measures.selected.width)} × ${pixels(measures.selected.height)}`);
  return parts.join(' · ');
}
