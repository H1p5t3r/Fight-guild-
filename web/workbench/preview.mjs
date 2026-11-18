import {phaseAt,attackBoxes,poseAt,effectiveHurtboxes} from './model.mjs';
import {HURT_LABELS,enabledHurtboxes,regionEnabled} from '../hurtboxes.mjs';
import {measureDistances,distanceSummary,pixels} from './measurements.mjs';

export class Preview {
  constructor(canvas,pack,onDrag,onHurtDrag){
    Object.assign(this,{canvas,pack,onDrag,onHurtDrag,images:new Map(),options:{hit:true,hurt:true,push:false,art:true,distances:true},handles:[]});
    this.coarse=matchMedia('(pointer: coarse)');this.touchEditing=false;
    document.getElementById('touch-edit').onclick=()=>{this.touchEditing=!this.touchEditing;this.syncTouchControls();};
    this.coarse.addEventListener('change',()=>this.syncTouchControls());
    this.observer=new ResizeObserver(()=>this.draw());this.observer.observe(canvas);
    canvas.addEventListener('pointerdown',event=>this.down(event));
    canvas.addEventListener('pointermove',event=>this.move(event));
    for(const type of ['pointerup','pointercancel','lostpointercapture'])canvas.addEventListener(type,event=>this.up(event));
  }
  show(record,index,attack,edit={}){Object.assign(this,{record,index,attack,edit});this.draw();}
  clear(){this.record=null;this.handles=[];this.boxPixels=null;this.measurements=null;this.measurementLabels=[];this.syncTouchControls();document.getElementById('distance-readout').textContent='';this.canvas.getContext('2d').clearRect(0,0,this.canvas.width,this.canvas.height);}
  image(file){
    if(!this.images.has(file)){
      const img=new Image();img.onload=()=>{document.getElementById('preview-empty').hidden=true;this.draw();};img.onerror=()=>{document.getElementById('preview-empty').hidden=false;};
      img.src=this.pack.images[file];this.images.set(file,img);
    }
    return this.images.get(file);
  }
  bounds(){
    const {record,attack:m}=this,signature=record.sequence?'sequence':JSON.stringify([m.hitboxBack,m.reach,m.bottom,m.height,m.hitAngle,m.active,m.hurtboxes,m.hitboxTimeline]);
    if(this.boundsRecord===record&&this.boundsSignature===signature)return this.fittedBounds;
    const shapes=record.sequence?[]:[...attackBoxes(m,m.startup,this.pack.collisions[record.character].push),...attackBoxes(m,m.startup+m.active-1,this.pack.collisions[record.character].push),...m.hitboxTimeline.keys.flatMap(k=>k.boxes||[]),...Object.values(m.hurtboxes).flatMap(Object.values)];
    const extent=Math.max(100,...shapes.flatMap(b=>[Math.abs(b[0])/100,Math.abs(b[2])/100])),top=Math.max(180,...shapes.map(b=>b[3]/100)),bottom=Math.min(0,...shapes.map(b=>b[1]/100));
    let left=Infinity,right=-Infinity,high=190,low=-20;
    for(const frame of record.frames)frame.state.players.forEach((p,i)=>{
      left=Math.min(left,p.x/100-(i?100:extent)-20);right=Math.max(right,p.x/100+(i?100:extent)+20);
      high=Math.max(high,p.y/100+(i?180:top)+20);low=Math.min(low,p.y/100+(i?0:bottom)-20);
    });
    for(const frame of record.frames)for(const boxes of frame.boxes)for(const q of [...boxes.projectiles??[],...(record.sequence?[...boxes.hit,...boxes.hurt]:[])]){left=Math.min(left,q[0]/100-20);right=Math.max(right,q[2]/100+20);high=Math.max(high,q[3]/100+20);low=Math.min(low,q[1]/100-20);}
    this.boundsRecord=record;this.boundsSignature=signature;return this.fittedBounds={left,right,top:high,bottom:low};
  }
  draw(){
    const {record,index,attack:m}=this,frame=record?.frames[index];if(!frame)return;
    const canvas=this.canvas,w=canvas.clientWidth,h=canvas.clientHeight,compact=matchMedia('(max-width: 1000px)').matches;
    const space=this.options.distances?(compact?44:72):0,topSpace=compact?50:65;if(w<=40||h<=topSpace+space)return;
    const dpr=window.devicePixelRatio||1;canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);const ctx=canvas.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);
    const b=this.bounds(),fit=Math.min((w-40)/(b.right-b.left),(h-topSpace-space)/(b.top-b.bottom));
    const {scale=fit,ox=(w-(b.right-b.left)*fit)/2-b.left*fit,oy=h-25-space+b.bottom*fit}=this.drag?.view||{};
    const a=frame.state.players[0],moveFrame=frame.selectedFrame,phase=phaseAt(m,moveFrame),localToWorld=box=>{
      const x1=a.x+a.facing*box[0],x2=a.x+a.facing*box[2];return [Math.min(x1,x2),a.y+box[1],Math.max(x1,x2),a.y+box[3]];
    };
    this.view={scale,ox,oy,facing:a.facing};this.hurtEdit=this.edit.hurt;
    const point=(x,y)=>({x:ox+x/100*scale,y:oy-y/100*scale});
    const local=(x,y)=>point(a.x+a.facing*x,a.y+y);
    const attackLocal=record.sequence?frame.boxes[0].hit.map(b=>a.facing===1?[b[0]-a.x,b[1]-a.y,b[2]-a.x,b[3]-a.y]:[a.x-b[2],b[1]-a.y,a.x-b[0],b[3]-a.y]):!a.variant&&moveFrame?attackBoxes(m,moveFrame,this.pack.collisions[record.character].push):[];
    ctx.fillStyle='#101b22';ctx.fillRect(0,0,w,h);ctx.strokeStyle='#263941';ctx.lineWidth=1;
    const gridOrigin=this.options.distances?a.x/100:0;
    for(let x=gridOrigin+Math.floor((b.left-gridOrigin)/50)*50;x<b.right;x+=50){const p=point(x*100,0);ctx.beginPath();ctx.moveTo(p.x,30);ctx.lineTo(p.x,h-25-space);ctx.stroke();}
    const ground=point(0,0);ctx.strokeStyle='#718086';ctx.beginPath();ctx.moveTo(12,ground.y);ctx.lineTo(w-12,ground.y);ctx.stroke();
    const rect=(box,color,alpha=.1,dashed=false)=>{const p=point(box[0],box[3]);ctx.fillStyle=color;ctx.globalAlpha=alpha;ctx.fillRect(p.x,p.y,(box[2]-box[0])/100*scale,(box[3]-box[1])/100*scale);ctx.globalAlpha=1;ctx.strokeStyle=color;ctx.setLineDash(dashed?[4,4]:[]);ctx.strokeRect(p.x,p.y,(box[2]-box[0])/100*scale,(box[3]-box[1])/100*scale);ctx.setLineDash([]);};
    const drawOrder=frame.state.foregroundPlayer===0?[1,0]:[0,1];
    drawOrder.forEach(i=>{
      const f=frame.state.players[i];
      if(f.tetherSource){const owner=frame.state.players[1-i],from=point(owner.x,owner.y+8500),to=point(f.x,f.y+7000);ctx.strokeStyle='#79d3df';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(from.x,from.y);ctx.lineTo(to.x,to.y);ctx.stroke();}

      const p=point(f.x,f.y),pose=!i&&record.geometryOnly&&moveFrame?poseAt(m,moveFrame,!!this.pack.art[f.character].ready):{phase:['active','windup','block','signature_windup','signature_active','ready','walk','run','stance','knockdown','knockdown_back','idle','crouch_idle','back_walk','attack_animation','backdash'][f.posePhase],index:f.poseIndex};
      const sheet=this.pack.art[f.character][pose.phase],tile=sheet?.frames[pose.index];
      ctx.fillStyle='#050d12';ctx.beginPath();ctx.ellipse(p.x,ground.y,22*scale,5*scale,0,0,Math.PI*2);ctx.fill();
      for(const q of frame.state.projectiles?.filter(q=>q.owner===i)??[]){
        const box=[q.x-q.width/2,q.y-q.height/2,q.x+q.width/2,q.y+q.height/2],from=point(box[0],box[3]),to=point(box[2],box[1]);
        const custom=this.pack.art[f.character].projectile_variants?.[q.move]??this.pack.art[f.character].projectile;
        const effect=this.image(custom?.file??'appearance-v3/projectiles.png'),region=custom?.frames?.[q.life<=6?3:Math.floor((q.age??0)/6)%3].region??custom?.region??(q.kind===2?[797,350,708,390]:[28,326,695,432]);
        if(this.options.art&&effect.complete&&effect.naturalWidth){ctx.save();ctx.translate((from.x+to.x)/2,from.y);ctx.scale(q.facing,1);ctx.drawImage(effect,...region,-Math.abs(to.x-from.x)/2,0,Math.abs(to.x-from.x),Math.abs(to.y-from.y));ctx.restore();}
        if(this.options.hit)rect(box,'#d7a7ff',.15);
      }
      // Ambient vapor is inside the owner's draw group, behind their body. It
      // follows the saved action clock, including freeze and backward seeking.
      const fighterArt=this.pack.art[f.character],movement=fighterArt.movement_smoke;
      const vapor=movement?.presentations[pose.phase]?movement:fighterArt.idle_smoke,placement=vapor?.presentations[pose.phase];
      if(this.options.art&&placement){
        const img=this.image(vapor.file),ticks=f.idleTime??0,interval=placement.frame_ticks??vapor.frame_ticks,blend=(ticks%interval)/interval;
        if(img.complete&&img.naturalWidth){
          const sx=150/vapor.body_height*scale*placement.scale[0],sy=150/vapor.body_height*scale*placement.scale[1];
          ctx.save();ctx.translate(p.x,p.y);ctx.scale(f.facing,1);ctx.translate(placement.offset[0]*scale,-placement.offset[1]*scale);ctx.scale(placement.flip_x?-1:1,1);
          for(let layer=0;layer<2;layer++){
            const key=vapor.frames[(Math.floor(ticks/interval)+layer)%vapor.frames.length];
            ctx.globalAlpha=vapor.opacity*(layer?blend:1-blend);
            ctx.drawImage(img,...key.region,-key.pivot[0]*sx,-key.pivot[1]*sy,key.region[2]*sx,key.region[3]*sy);
          }
          ctx.restore();
        }
      }
      const paintEffect=behind=>{
        const overlay=tile?.effect;if(!this.options.art||!overlay||!!overlay.behind!==behind)return;
        const info=this.pack.art[f.character][overlay.sheet],frame=info.frames[overlay.pose],img=this.image(frame.file??info.file);
        if(!img.complete||!img.naturalWidth)return;
        const [left,bottom,right,top]=overlay.box;ctx.save();ctx.translate(p.x,p.y);ctx.scale(f.facing,1);ctx.globalAlpha=overlay.opacity??1;
        ctx.drawImage(img,...frame.region,left*scale,-top*scale,(right-left)*scale,(top-bottom)*scale);ctx.restore();
      };
      paintEffect(true);
      if(this.options.art&&tile){const img=this.image(tile.file??sheet.file),s=150/(tile.body_height??sheet.body_height)*scale;if(img.complete&&img.naturalWidth){const [sx,sy,sw,sh]=tile.render_region??tile.region;ctx.save();ctx.translate(p.x,p.y);ctx.scale(f.facing,1);ctx.drawImage(img,sx,sy,sw,sh,(sx-tile.region[0]-tile.pivot[0])*s,(sy-tile.region[1]-tile.pivot[1])*s,sw*s,sh*s);ctx.restore();}}
      paintEffect(false);
      if(this.options.push)frame.boxes[i].push.forEach(box=>rect(box,'#a8ba76'));
      const hurt=!record.sequence&&!i&&moveFrame&&!f.variant&&(record.geometryOnly||m.hurtboxes[phase])?Object.values(enabledHurtboxes(effectiveHurtboxes(this.pack,record.character,m,moveFrame),m,phase)).map(localToWorld):frame.boxes[i].hurt;
      if(this.options.hurt)hurt.forEach(box=>rect(box,'#7bb8d4'));
      const authored=!record.sequence&&!i&&moveFrame&&!f.variant;
      const hits=authored?attackLocal.map(localToWorld):frame.boxes[i].hit;
      if(this.options.hit&&(!authored||phase==='active'||this.edit.hit))hits.forEach(box=>rect(box,'#f1aa66',.12,authored&&phase!=='active'));
      if(f.weaponVisible){const start=point(f.weaponBackX,f.weaponBackY),end=point(f.weaponTipX,f.weaponTipY);ctx.strokeStyle='#e3c79b';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(start.x,start.y);ctx.lineTo(end.x,end.y);ctx.stroke();ctx.lineWidth=1;}
      ctx.fillStyle=i?'#80d2dc':'#e0ba76';ctx.font='12px system-ui';ctx.textAlign=i?'right':'left';ctx.fillText(`${this.pack.art[f.character].name.toUpperCase()} · ${f.health} HP`,i?w-14:14,18);
      const barX=i?w-174:14;ctx.fillStyle='#36464e';ctx.fillRect(barX,24,160,4);ctx.fillStyle='#c4bdbe';ctx.fillRect(barX,24,160*f.health/1000,4);ctx.fillStyle=i?'#80d2dc':'#e0ba76';ctx.fillRect(barX,24,160*(f.health-f.greyLife)/1000,4);
      const status=f.bleedTime?`BLEED · ${f.greyLife} grey · ${(f.bleedTime/60).toFixed(1)}s`:f.tetherSource?f.tetherUsed?'TETHER · PULLED':'TETHER':f.variant&&f.move>=0?f.variant===1?'TETHER PULL':'CASH-OUT GRAB':'';ctx.font='11px system-ui';ctx.fillText(status,i?w-14:14,42);
    });
    this.handles=[];this.boxPixels=null;let selectedBox=null;
    const handles=(box,color,target,extra={},keys=[0,2,3,1])=>{
      selectedBox=box;rect(localToWorld(box),color,.23);const [l,bt,r,t]=box,lc=local(l,(bt+t)/2),rc=local(r,(bt+t)/2),tc=local((l+r)/2,t),bc=local((l+r)/2,bt);
      this.boxPixels={left:Math.min(lc.x,rc.x),right:Math.max(lc.x,rc.x),top:tc.y,bottom:bc.y};
      this.handles=[lc,rc,tc,bc].map((p,i)=>({...p,key:keys[i],cursor:i<2?'ew-resize':'ns-resize',target,...extra}));
      const size=this.coarse.matches?6:4;
      for(const h of this.handles){ctx.fillStyle=color;ctx.fillRect(h.x-size,h.y-size,size*2,size*2);ctx.strokeStyle='#111b20';ctx.strokeRect(h.x-size,h.y-size,size*2,size*2);}
    };
    if(moveFrame&&!a.variant&&this.edit.hit&&this.options.hit&&phase==='active'&&m.category!==4){
      const selected=this.edit.hitKey;
      if(selected){const box=m.hitboxTimeline.keys[selected.keyIndex]?.boxes?.[selected.boxIndex];if(box)handles(box,'#ffcf89','hit-key',selected);}
      else if(!m.hitAngle){const box=attackBoxes(m,moveFrame,this.pack.collisions[record.character].push)[0];if(box)handles(box,'#ffcf89','base',{},['hitboxBack','reach','height','bottom']);}
    }
    if(moveFrame&&!a.variant&&this.edit.hurt?.custom&&this.options.hurt){
      const box=m.hurtboxes[this.edit.hurt.phase]?.[this.edit.hurt.region];
      if(box&&regionEnabled(m,this.edit.hurt.phase,this.edit.hurt.region)){handles(box,'#b9e9ff','hurt');const p=local(box[0],box[3]);ctx.fillStyle='#b9e9ff';ctx.font='11px system-ui';ctx.textAlign='left';ctx.fillText(HURT_LABELS[this.edit.hurt.region],p.x,p.y-9);}
    }
    const impact=record.contacts.findLast(c=>c.tick<=index&&index-c.tick<18);
    if(impact){const p=point(impact.x,impact.y),age=index-impact.tick;ctx.strokeStyle=impact.event===2?'#8bd8ed':'#ffcf89';ctx.globalAlpha=1-age/18;ctx.lineWidth=2;ctx.beginPath();ctx.arc(p.x,p.y,8+age*1.5,0,Math.PI*2);ctx.stroke();ctx.fillStyle=ctx.strokeStyle;ctx.textAlign='center';ctx.font='bold 15px system-ui';ctx.fillText(impact.event===2?'BLOCK':`${impact.damage} DAMAGE`,p.x,p.y-24-age);ctx.globalAlpha=1;ctx.lineWidth=1;}
    this.measurements=measureDistances(frame.state.players,frame.boxes.map(boxes=>boxes.push[0]),this.options.hit&&moveFrame&&(phase==='active'||this.edit.hit)?attackLocal:[],selectedBox);
    const readout=document.getElementById('distance-readout');readout.hidden=!this.options.distances;readout.textContent=distanceSummary(this.measurements);
    this.measurementLabels=[];if(this.options.distances)this.drawMeasurements(ctx,{w,h,point,ground,a,b,phase,selectedBox,local,compact});
    ctx.textAlign='left';ctx.fillStyle='#b9c7ce';ctx.font='11px system-ui';ctx.fillText(record.geometryOnly?'GEOMETRY ONLY':frame.state.hitstop?'IMPACT FREEZE':frame.stage,14,h-10);
    this.syncTouchControls();
  }
  drawMeasurements(ctx,{w,h,point,ground,a,b,phase,selectedBox,local,compact}){
    const m=this.measurements;this.measurementLabels=[];ctx.save();
    const label=(text,x,y,color)=>{
      ctx.font='11px system-ui';const width=ctx.measureText(text).width+12,height=19;
      x=Math.max(width/2+8,Math.min(w-width/2-8,x));y=Math.max(32,Math.min(h-17,y));
      ctx.fillStyle='#0a151de8';ctx.fillRect(x-width/2,y-height/2,width,height);
      ctx.fillStyle=color;ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText(text,x,y);
      this.measurementLabels.push({text,x:x-width/2,y:y-height/2,width,height});
    };
    const span=(from,to,y,text,color,leaders=false)=>{
      const x1=point(from,0).x,x2=point(to,0).x;
      ctx.strokeStyle=color;ctx.lineWidth=1;
      if(leaders){ctx.globalAlpha=.4;ctx.setLineDash([2,4]);for(const x of [x1,x2]){ctx.beginPath();ctx.moveTo(x,ground.y+18);ctx.lineTo(x,y);ctx.stroke();}ctx.globalAlpha=1;ctx.setLineDash([]);}
      ctx.beginPath();ctx.moveTo(x1,y);ctx.lineTo(x2,y);for(const x of [x1,x2]){ctx.moveTo(x,y-4);ctx.lineTo(x,y+4);}ctx.stroke();
      label(text,(x1+x2)/2,y-12,color);
    };
    // The ruler follows the attacker's root: positive numbers always point forward.
    const step=([25,50,100,200,500,1000,2000,5000].find(n=>n*this.view.scale>=44)||10000)*100;
    const ends=[(b.left*100-a.x)*a.facing,(b.right*100-a.x)*a.facing];
    ctx.font='10px system-ui';ctx.textAlign='center';ctx.textBaseline='top';
    for(let value=Math.ceil(Math.min(...ends)/step)*step;value<=Math.max(...ends);value+=step){
      const p=point(a.x+a.facing*value,0);if(p.x<18||p.x>w-18)continue;
      ctx.strokeStyle=value===0?'#e9c174':'#8099a6';ctx.fillStyle=ctx.strokeStyle;
      ctx.beginPath();ctx.moveTo(p.x,ground.y-3);ctx.lineTo(p.x,ground.y+4);ctx.stroke();ctx.fillText(String(value/100),p.x,ground.y+6);
    }
    if(compact)span(m.roots.from,m.roots.to,h-28,`Roots ${pixels(m.roots.value)}${m.body?' · '+(m.body.overlap?'Overlap ':'Gap ')+pixels(m.body.value):''}`,'#a8c4d5',true);
    else{
      span(m.roots.from,m.roots.to,h-56,`Roots · ${pixels(m.roots.value)}`,'#a8c4d5',true);
      if(m.body)span(m.body.from,m.body.to,h-30,`${m.body.overlap?'Body overlap':'Body gap'} · ${pixels(m.body.value)}`,m.body.overlap?'#e9ad81':'#8ed0bd',true);
    }
    if(m.reach)span(m.reach.from,m.reach.to,50,`Box front · ${pixels(m.reach.value)}${phase==='active'?'':' · inactive'}`,'#f2c07d');
    if(selectedBox&&m.selected){
      const top=local((selectedBox[0]+selectedBox[2])/2,selectedBox[3]),bottom=local(0,selectedBox[1]);
      const y=bottom.y+13<ground.y-18?bottom.y+13:Math.max(72,top.y-14);
      label(`${pixels(m.selected.width)} × ${pixels(m.selected.height)}`,top.x,y,this.edit.hurt?'#b9e9ff':'#f2c07d');
    }
    ctx.restore();
  }
  local(event){const r=this.canvas.getBoundingClientRect();return {x:event.clientX-r.left,y:event.clientY-r.top};}
  syncTouchControls(){
    const button=document.getElementById('touch-edit');button.hidden=!this.coarse.matches||!this.handles.length;
    if(button.hidden)this.touchEditing=false;
    button.setAttribute('aria-pressed',String(this.touchEditing));button.textContent=this.touchEditing?'Done dragging':'Drag boxes';
    this.canvas.classList.toggle('box-editing',this.coarse.matches&&this.touchEditing);
  }
  pick(p){const radius=this.coarse.matches?24:14,handle=this.handles.map(h=>({h,d:Math.hypot(h.x-p.x,h.y-p.y)})).filter(v=>v.d<radius).sort((a,b)=>a.d-b.d)[0]?.h;if(handle)return handle;const b=this.boxPixels;if(this.handles.length&&b&&p.x>b.left&&p.x<b.right&&p.y>b.top&&p.y<b.bottom)return {...this.handles[0],key:'move',cursor:'move'};return null;}
  down(event){if(event.button!==0||event.isPrimary===false||this.drag||(event.pointerType==='touch'&&!this.touchEditing))return;const p=this.local(event),hit=this.pick(p);if(!hit)return;
    event.preventDefault();this.drag={...hit,pointerId:event.pointerId,start:p,attack:structuredClone(this.attack),view:structuredClone(this.view),hurt:structuredClone(this.hurtEdit)};
    if((hit.target==='hurt'?this.onHurtDrag:this.onDrag)('start')===false){this.drag=null;return;}this.canvas.setPointerCapture(event.pointerId);
  }
  move(event){const p=this.local(event);this.canvas.style.cursor=this.drag?.cursor||this.pick(p)?.cursor||'default';if(!this.drag||this.drag.pointerId!==event.pointerId)return;
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
  up(event){if(!this.drag||event&&this.drag.pointerId!==event.pointerId)return;const callback=this.drag.target==='hurt'?this.onHurtDrag:this.onDrag;this.drag=null;callback('end');this.draw();}
}
