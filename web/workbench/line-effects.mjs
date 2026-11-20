// The line and seal are presentation of saved simulation state, never collision.
export function drawLineEffect(ctx,{owner,target,art,image,point,scale}){
 const active=target.tetherSource||target.linePullTime;
 if(!active)return;
 const from=point(owner.x,owner.y+8500),to=point(target.x,target.y+7000),dx=to.x-from.x,dy=to.y-from.y;
 const sheet=art.line_fx,texture=sheet&&image(sheet.file),cord=sheet?.frames[4],seal=sheet?.frames[3];
 ctx.save();ctx.translate(from.x,from.y);ctx.rotate(Math.atan2(dy,dx));
 const length=Math.hypot(dx,dy),width=Math.max(2,3.3*scale);
 if(texture?.complete&&texture.naturalWidth&&cord)ctx.drawImage(texture,...cord.region,0,-width/2,length,width);
 else{ctx.strokeStyle='#79d3df';ctx.lineWidth=width;ctx.beginPath();ctx.moveTo(0,0);ctx.lineTo(length,0);ctx.stroke();}
 ctx.restore();
 if(target.tetherSource&&texture?.complete&&texture.naturalWidth&&seal){
  const size=26*scale;ctx.save();ctx.globalAlpha=.86;ctx.drawImage(texture,...seal.region,to.x-size/2,to.y-size/2,size,size);ctx.restore();
 }
}
