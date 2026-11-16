import {phaseAt,attackBoxes,poseAt,effectiveHurtboxes} from './model.mjs';
import {HURT_LABELS} from '../hurtboxes.mjs';

export class Preview {
  constructor(canvas,pack,onDrag,onHurtDrag){
    Object.assign(this,{canvas,pack,onDrag,onHurtDrag,images:new Map(),options:{hit:true,hurt:true,push:false,art:true},handles:[]});
    this.observer=new ResizeObserver(()=>this.draw());this.observer.observe(canvas);
    canvas.addEventListener('pointerdown',event=>this.down(event));
    canvas.addEventListener('pointermove',event=>this.move(event));
    for(const type of ['pointerup','pointercancel','lostpointercapture'])canvas.addEventListener(type,()=>this.up());
  }
  show(record,index,attack,edit={}){Object.assign(this,{record,index,attack,edit});this.draw();}
  clear(){this.record=null;this.handles=[];this.boxPixels=null;this.canvas.getContext('2d').clearRect(0,0,this.canvas.width,this.canvas.height);}
  image(file){
    if(!this.images.has(file)){
      const img=new Image();img.onload=()=>{document.getElementById('preview-empty').hidden=true;this.draw();};img.onerror=()=>{document.getElementById('preview-empty').hidden=false;};
      img.src=this.pack.images[file];this.images.set(file,img);
    }
    return this.images.get(file);
  }
  bounds(){
    const {record,attack:m}=this,signature=JSON.stringify([m.hitboxBack,m.reach,m.bottom,m.height,m.hitAngle,m.active,m.hurtboxes,m.hitboxTimeline]);
    if(this.boundsRecord===record&&this.boundsSignature===signature)return this.fittedBounds;
    const shapes=[...attackBoxes(m,m.startup,this.pack.collisions[record.character].push),...attackBoxes(m,m.startup+m.active-1,this.pack.collisions[record.character].push),...m.hitboxTimeline.keys.flatMap(k=>k.boxes||[]),...Object.values(m.hurtboxes).flatMap(Object.values)];
    const extent=Math.max(100,...shapes.flatMap(b=>[Math.abs(b[0])/100,Math.abs(b[2])/100])),top=Math.max(180,...shapes.map(b=>b[3]/100)),bottom=Math.min(0,...shapes.map(b=>b[1]/100));
    let left=Infinity,right=-Infinity,high=190,low=-20;
    for(const frame of record.frames)frame.state.players.forEach((p,i)=>{
      left=Math.min(left,p.x/100-(i?100:extent)-20);right=Math.max(right,p.x/100+(i?100:extent)+20);
      high=Math.max(high,p.y/100+(i?180:top)+20);low=Math.min(low,p.y/100+(i?0:bottom)-20);
    });
    this.boundsRecord=record;this.boundsSignature=signature;return this.fittedBounds={left,right,top:high,bottom:low};
  }
  draw(){
    const {record,index,attack:m}=this,frame=record?.frames[index];if(!frame)return;
    const canvas=this.canvas,w=canvas.clientWidth,h=canvas.clientHeight;if(w<=40||h<=65)return;
    const dpr=window.devicePixelRatio||1;canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);const ctx=canvas.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);
    const b=this.bounds(),fit=Math.min((w-40)/(b.right-b.left),(h-65)/(b.top-b.bottom));
    const {scale=fit,ox=(w-(b.right-b.left)*fit)/2-b.left*fit,oy=h-25+b.bottom*fit}=this.drag?.view||{};
    const a=frame.state.players[0],moveFrame=frame.selectedFrame,phase=phaseAt(m,moveFrame),localToWorld=box=>{
      const x1=a.x+a.facing*box[0],x2=a.x+a.facing*box[2];return [Math.min(x1,x2),a.y+box[1],Math.max(x1,x2),a.y+box[3]];
    };
    this.view={scale,ox,oy,facing:a.facing};this.hurtEdit=this.edit.hurt;
    const point=(x,y)=>({x:ox+x/100*scale,y:oy-y/100*scale});
    const local=(x,y)=>point(a.x+a.facing*x,a.y+y);
    ctx.fillStyle='#101b22';ctx.fillRect(0,0,w,h);ctx.strokeStyle='#263941';ctx.lineWidth=1;
    for(let x=Math.floor(b.left/50)*50;x<b.right;x+=50){const p=point(x*100,0);ctx.beginPath();ctx.moveTo(p.x,30);ctx.lineTo(p.x,h-25);ctx.stroke();}
    const ground=point(0,0);ctx.strokeStyle='#718086';ctx.beginPath();ctx.moveTo(12,ground.y);ctx.lineTo(w-12,ground.y);ctx.stroke();
    const rect=(box,color,alpha=.1,dashed=false)=>{const p=point(box[0],box[3]);ctx.fillStyle=color;ctx.globalAlpha=alpha;ctx.fillRect(p.x,p.y,(box[2]-box[0])/100*scale,(box[3]-box[1])/100*scale);ctx.globalAlpha=1;ctx.strokeStyle=color;ctx.setLineDash(dashed?[4,4]:[]);ctx.strokeRect(p.x,p.y,(box[2]-box[0])/100*scale,(box[3]-box[1])/100*scale);ctx.setLineDash([]);};
    frame.state.players.forEach((f,i)=>{
      const p=point(f.x,f.y),pose=!i&&record.geometryOnly&&moveFrame?poseAt(m,moveFrame):{phase:['active','windup','block','signature_windup','signature_active'][f.posePhase],index:f.poseIndex};
      const sheet=this.pack.art[f.character][pose.phase],tile=sheet?.frames[pose.index];
      ctx.fillStyle='#050d12';ctx.beginPath();ctx.ellipse(p.x,ground.y,22*scale,5*scale,0,0,Math.PI*2);ctx.fill();
      if(this.options.art&&tile){const img=this.image(sheet.file),s=150/sheet.body_height*scale;if(img.complete&&img.naturalWidth){const [sx,sy,sw,sh]=tile.region;ctx.save();ctx.translate(p.x,p.y);ctx.scale(f.facing,1);ctx.drawImage(img,sx,sy,sw,sh,-tile.pivot[0]*s,-tile.pivot[1]*s,sw*s,sh*s);ctx.restore();}}
      if(this.options.push)frame.boxes[i].push.forEach(box=>rect(box,'#a8ba76'));
      const hurt=!i&&moveFrame&&(record.geometryOnly||m.hurtboxes[phase])?Object.values(effectiveHurtboxes(this.pack,record.character,m,moveFrame)).map(localToWorld):frame.boxes[i].hurt;
      if(this.options.hurt)hurt.forEach(box=>rect(box,'#7bb8d4'));
      const authored=!i&&moveFrame;
      const hits=authored?attackBoxes(m,moveFrame,this.pack.collisions[record.character].push).map(localToWorld):frame.boxes[i].hit;
      if(this.options.hit&&(!authored||phase==='active'||this.edit.hit))hits.forEach(box=>rect(box,'#f1aa66',.12,authored&&phase!=='active'));
      if(f.weaponVisible){const start=point(f.weaponBackX,f.weaponBackY),end=point(f.weaponTipX,f.weaponTipY);ctx.strokeStyle='#e3c79b';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(start.x,start.y);ctx.lineTo(end.x,end.y);ctx.stroke();ctx.lineWidth=1;}
      ctx.fillStyle=i?'#80d2dc':'#e0ba76';ctx.font='12px system-ui';ctx.textAlign=i?'right':'left';ctx.fillText(`${this.pack.art[f.character].name.toUpperCase()} · ${f.health} HP`,i?w-14:14,18);
    });
    this.handles=[];this.boxPixels=null;
    const handles=(box,color,target,extra={},keys=[0,2,3,1])=>{
      rect(localToWorld(box),color,.23);const [l,bt,r,t]=box,lc=local(l,(bt+t)/2),rc=local(r,(bt+t)/2),tc=local((l+r)/2,t),bc=local((l+r)/2,bt);
      this.boxPixels={left:Math.min(lc.x,rc.x),right:Math.max(lc.x,rc.x),top:tc.y,bottom:bc.y};
      this.handles=[lc,rc,tc,bc].map((p,i)=>({...p,key:keys[i],cursor:i<2?'ew-resize':'ns-resize',target,...extra}));
      for(const h of this.handles){ctx.fillStyle=color;ctx.fillRect(h.x-4,h.y-4,8,8);ctx.strokeStyle='#111b20';ctx.strokeRect(h.x-4,h.y-4,8,8);}
    };
    if(moveFrame&&this.edit.hit&&this.options.hit&&phase==='active'&&m.category!==4){
      const selected=this.edit.hitKey;
      if(selected){const box=m.hitboxTimeline.keys[selected.keyIndex]?.boxes?.[selected.boxIndex];if(box)handles(box,'#ffcf89','hit-key',selected);}
      else if(!m.hitAngle){const box=attackBoxes(m,moveFrame,this.pack.collisions[record.character].push)[0];if(box)handles(box,'#ffcf89','base',{},['hitboxBack','reach','height','bottom']);}
    }
    if(moveFrame&&this.edit.hurt?.custom&&this.options.hurt){
      const box=m.hurtboxes[this.edit.hurt.phase]?.[this.edit.hurt.region];
      if(box){handles(box,'#b9e9ff','hurt');const p=local(box[0],box[3]);ctx.fillStyle='#b9e9ff';ctx.font='11px system-ui';ctx.textAlign='left';ctx.fillText(HURT_LABELS[this.edit.hurt.region],p.x,p.y-9);}
    }
    const impact=record.contacts.findLast(c=>c.tick<=index&&index-c.tick<18);
    if(impact){const p=point(impact.x,impact.y),age=index-impact.tick;ctx.strokeStyle=impact.event===2?'#8bd8ed':'#ffcf89';ctx.globalAlpha=1-age/18;ctx.lineWidth=2;ctx.beginPath();ctx.arc(p.x,p.y,8+age*1.5,0,Math.PI*2);ctx.stroke();ctx.fillStyle=ctx.strokeStyle;ctx.textAlign='center';ctx.font='bold 15px system-ui';ctx.fillText(impact.event===2?'BLOCK':`${impact.damage} DAMAGE`,p.x,p.y-24-age);ctx.globalAlpha=1;ctx.lineWidth=1;}
    ctx.textAlign='left';ctx.fillStyle='#b9c7ce';ctx.font='11px system-ui';ctx.fillText(record.geometryOnly?'GEOMETRY ONLY':frame.state.hitstop?'IMPACT FREEZE':frame.stage,14,h-10);
  }
  local(event){const r=this.canvas.getBoundingClientRect();return {x:event.clientX-r.left,y:event.clientY-r.top};}
  pick(p){const handle=this.handles.find(h=>Math.hypot(h.x-p.x,h.y-p.y)<14);if(handle)return handle;const b=this.boxPixels;if(this.handles.length&&b&&p.x>b.left&&p.x<b.right&&p.y>b.top&&p.y<b.bottom)return {...this.handles[0],key:'move',cursor:'move'};return null;}
  down(event){if(event.button!==0)return;const p=this.local(event),hit=this.pick(p);if(!hit)return;
    event.preventDefault();this.drag={...hit,start:p,attack:structuredClone(this.attack),view:structuredClone(this.view),hurt:structuredClone(this.hurtEdit)};
    if((hit.target==='hurt'?this.onHurtDrag:this.onDrag)('start')===false){this.drag=null;return;}this.canvas.setPointerCapture(event.pointerId);
  }
  move(event){const p=this.local(event);this.canvas.style.cursor=this.drag?.cursor||this.pick(p)?.cursor||'default';if(!this.drag)return;
    const d=this.drag,m=d.attack,dx=Math.round((p.x-d.start.x)/d.view.scale*100*d.view.facing),dy=Math.round(-(p.y-d.start.y)/d.view.scale*100);let patch={};
    if(d.target==='hurt'||d.target==='hit-key'){
      const box=d.target==='hurt'?m.hurtboxes[d.hurt.phase][d.hurt.region]:m.hitboxTimeline.keys[d.keyIndex].boxes[d.boxIndex],b=[...box];
      if(d.key==='move'){b[0]+=dx;b[2]+=dx;b[1]+=dy;b[3]+=dy;}else b[d.key]+=(d.key===0||d.key===2)?dx:dy;
      if(d.target==='hurt')this.onHurtDrag('change',{...d.hurt,rect:b});else this.onDrag('change',{keyIndex:d.keyIndex,boxIndex:d.boxIndex,rect:b});return;
    }
    if(d.key==='move')patch={hitboxBack:m.hitboxBack+dx,reach:m.reach+dx,bottom:m.bottom+dy};
    else if(d.key==='height')patch={height:m.height+dy};
    else if(d.key==='bottom')patch={bottom:m.bottom+dy,height:m.height-dy};
    else patch={[d.key]:m[d.key]+dx};
    this.onDrag('change',patch);
  }
  up(){if(!this.drag)return;const callback=this.drag.target==='hurt'?this.onHurtDrag:this.onDrag;this.drag=null;callback('end');this.draw();}
}
