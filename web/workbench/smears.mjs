const phases=['active','windup','block','signature_windup','signature_active','ready','walk','run'];
// Rectangles sample only a moving part from the source image. World coordinates
// are pixels, y up. No generated asset is resampled or rewritten on disk.
function patch(pack,f,part){
 const phase=phases[f.posePhase],sheet=pack.art[f.character][phase],tile=sheet?.frames[f.poseIndex],body=pack.collisions[f.character].poses[phase]?.[f.poseIndex];
 if(!tile||!body)return null;
 let r;
 if(part===2){r=[...body.hurt.legs];r[1]+=(r[3]-r[1])*.4;}
 else if(part===3){r=body.strike?[...body.strike]:[tile.bounds[0]+(tile.bounds[2]-tile.bounds[0])*.65,body.hurt.head[3],tile.bounds[2],body.hurt.legs[1]+(body.hurt.legs[3]-body.hurt.legs[1])*.4];}
 else {r=[...(body.hurt.extension??body.hurt.torsoArms)];if(!body.hurt.extension)r[0]+=(r[2]-r[0])*.6;r[1]=Math.max(r[1],body.hurt.head[3]);}
 r=[Math.max(0,r[0]),Math.max(0,r[1]),Math.min(tile.region[2],r[2]),Math.min(tile.region[3],r[3])];
 if(r[2]-r[0]<2||r[3]-r[1]<2)return null;
 const k=150/sheet.body_height,world=(x,y)=>[f.x/100+f.facing*(x-tile.pivot[0])*k,f.y/100-(y-tile.pivot[1])*k];
 return {file:tile.file??sheet.file,source:[tile.region[0]+r[0],tile.region[1]+r[1],r[2]-r[0],r[3]-r[1]],center:world((r[0]+r[2])/2,(r[1]+r[3])/2),corners:[[r[0],r[1]],[r[2],r[1]],[r[2],r[3]],[r[0],r[3]]].map(([x,y])=>world(x,y))};
}
export function smearPlan(pack,previous,current,config){
 if(!previous||!current||previous.character!==current.character||previous.facing!==current.facing||current.teleported)return null;
 const changed=previous.posePhase!==current.posePhase||previous.poseIndex!==current.poseIndex;
 const move=current.move>=0?config.moves[current.move]:previous.move>=0?config.moves[previous.move]:null,settings=move??config.movement;
 if(!settings.smearMode)return null;
 const custom=move&&settings.smearMode===2;
 if(custom?![1,2,3,4].some(i=>settings['smearFrame'+i]>0&&current.move>=0&&current.age===settings['smearFrame'+i]&&previous.age!==current.age):!changed)return null;
 const part=settings.smearPart||(!move&&[6,7].includes(current.posePhase)?2:1);
 const from=patch(pack,previous,part),to=patch(pack,current,part);if(!from||!to)return null;
 const delta=to.center.map((v,i)=>v-from.center[i]),length=Math.hypot(...delta),axis=length>1?delta.map(v=>v/length):[current.facing,0];
 const span=Math.max(8,Math.hypot(from.corners[1][0]-from.corners[0][0],from.corners[1][1]-from.corners[0][1]));
 const stretch=Math.min(4,1+length/span)*settings.smearStretch/100;
 const center=from.center.map((v,i)=>(v+to.center[i])/2);
 const points=from.corners.map(p=>{const d=p.map((v,i)=>v-from.center[i]),along=d[0]*axis[0]+d[1]*axis[1];return d.map((v,i)=>center[i]+v+axis[i]*along*(stretch-1));});
 return {...from,points,part};
}
export function drawSmear(ctx,plan,img,point){
 if(!plan||!img?.complete||!img.naturalWidth)return;
 const [x,y,w,h]=plan.source,pts=plan.points.map(([x,y])=>point(x*100,y*100)),a=pts[0],b=pts[1],d=pts[3];
 ctx.save();ctx.transform((b.x-a.x)/w,(b.y-a.y)/w,(d.x-a.x)/h,(d.y-a.y)/h,a.x,a.y);ctx.drawImage(img,x,y,w,h,0,0,w,h);ctx.restore();
}
