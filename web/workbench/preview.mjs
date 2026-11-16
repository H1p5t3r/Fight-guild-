import {phaseAt,attackBoxes,poseAt,effectiveHurtboxes} from './model.mjs';
import {HURT_LABELS} from '../hurtboxes.mjs';
export class Preview {
  constructor(canvas,pack,onDrag,onHurtDrag){
    this.canvas=canvas;this.pack=pack;this.onDrag=onDrag;this.onHurtDrag=onHurtDrag;this.images=new Map();this.options={hit:true,hurt:true,push:false,art:true};this.handles=[];this.editable=false;
    this.observer=new ResizeObserver(()=>this.draw());this.observer.observe(canvas);
    canvas.addEventListener('pointerdown',event=>this.down(event));
    canvas.addEventListener('pointermove',event=>this.move(event));
    for(const type of ['pointerup','pointercancel','lostpointercapture'])canvas.addEventListener(type,event=>this.up(event));
  }
  pose(){return poseAt(this.attack,this.frame);}
  show(character,attack,frame,editable=false,hurtEdit=null,hitEdit=null){this.test=null;this.character=character;this.attack=attack;this.frame=frame;this.editable=editable;this.hurtEdit=hurtEdit;this.hitEdit=hitEdit;this.draw();}
  showTest(record,index){this.test={record,index};this.handles=[];this.boxPixels=null;this.draw();}
  image(file){
    if(!this.images.has(file)){
      const img=new Image();img.onload=()=>{document.getElementById('preview-empty').hidden=true;this.draw();};img.onerror=()=>{document.getElementById('preview-empty').hidden=false;};
      img.src=this.pack.images[file];this.images.set(file,img);
    }
    return this.images.get(file);
  }
  draw(){
    if(this.test){this.drawTest();return;}
    if(!this.attack)return;
    const canvas=this.canvas,w=canvas.clientWidth,h=canvas.clientHeight;if(!w||!h)return;
    const dpr=window.devicePixelRatio||1;canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);
    const ctx=canvas.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,w,h);
    const m=this.attack,pose=this.pose(),sheet=this.pack.art[this.character][pose.phase],tile=sheet?.frames[pose.index];
    const source=this.pack.collisions[this.character],push=source.push;
    const lift=m.air?60:0;
    const boxes=attackBoxes(m,this.frame,push).map(b=>b.map(x=>x/100));
    // Keep the camera fixed for the entire pose cycle, including the full hook path.
    const allBoxes=[...attackBoxes(m,m.startup,push),...attackBoxes(m,m.startup+m.active-1,push),...(m.hitboxTimeline?.keys||[]).flatMap(k=>k.boxes||[]),...Object.values(m.hurtboxes).flatMap(Object.values)].map(b=>b.map(x=>x/100));
    const x0=Math.min(-90,...allBoxes.map(b=>b[0]-25)),x1=Math.max(170,...allBoxes.map(b=>b[2]+25));
    const y0=Math.min(-15,...allBoxes.map(b=>b[1]+lift-15)),y1=Math.max(185+lift,...allBoxes.map(b=>b[3]+lift+25));
    const scale=this.drag?.view.scale??Math.min((w-38)/(x1-x0),(h-42)/(y1-y0));
    const origin=this.drag?.view.origin??{x:(w-(x1-x0)*scale)/2-x0*scale,y:(h-(y1-y0)*scale)/2+y1*scale};
    this.view={scale,origin,lift};const point=(x,y)=>({x:origin.x+x*scale,y:origin.y-y*scale});
    const rect=(b,color,alpha=0.12,dashed=false)=>{
      const p=point(b[0],b[3]+lift),rw=(b[2]-b[0])*scale,rh=(b[3]-b[1])*scale;
      ctx.fillStyle=color;ctx.globalAlpha=alpha;ctx.fillRect(p.x,p.y,rw,rh);ctx.globalAlpha=1;
      ctx.strokeStyle=color;ctx.lineWidth=1.3;ctx.setLineDash(dashed?[4,4]:[]);ctx.strokeRect(p.x,p.y,rw,rh);ctx.setLineDash([]);
    };
    ctx.fillStyle='#101b22';ctx.fillRect(0,0,w,h);
    ctx.strokeStyle='#23323b';ctx.lineWidth=1;ctx.font='10px system-ui';ctx.fillStyle='#70828b';
    for(let x=Math.ceil(x0/50)*50;x<=x1;x+=50){const p=point(x,0);ctx.beginPath();ctx.moveTo(p.x,16);ctx.lineTo(p.x,h-16);ctx.stroke();ctx.fillText(`${x}`,p.x+4,h-8);}
    for(let y=Math.ceil(y0/50)*50;y<=y1;y+=50){const p=point(0,y);ctx.beginPath();ctx.moveTo(16,p.y);ctx.lineTo(w-16,p.y);ctx.stroke();ctx.fillText(`${y}`,6,p.y-4);}
    const ground=point(0,0);ctx.strokeStyle='#718086';ctx.beginPath();ctx.moveTo(14,ground.y);ctx.lineTo(w-14,ground.y);ctx.stroke();
    if(this.options.art&&tile){
      const img=this.image(sheet.file),s=150/sheet.body_height*scale;
      if(img.complete&&img.naturalWidth){const [sx,sy,sw,sh]=tile.region;ctx.drawImage(img,sx,sy,sw,sh,origin.x-tile.pivot[0]*s,origin.y-lift*scale-tile.pivot[1]*s,sw*s,sh*s);}
    }
    if(this.options.push){const bottom=m.air?push.airBottom/100:0,height=(m.air?push.airHeight:push.standingHeight)/100;rect([-push.halfWidth/100,bottom,push.halfWidth/100,bottom+height],'#a8ba76',0.05,true);}
    const hurt=effectiveHurtboxes(this.pack,this.character,m,this.frame);
    if(this.options.hurt)for(const b of Object.values(hurt))rect(b.map(v=>v/100),'#7bb8d4',0.06);
    this.handles=[];
    if(this.options.hit){
      const active=phaseAt(m,this.frame)==='active';
      if(m.hitAngle){
        const from=point(m.hitboxBack/100,m.bottom/100+lift),to=point(m.reach/100,m.bottom/100+lift+m.hitAngle*(m.reach-m.hitboxBack)/100);
        ctx.strokeStyle='#efb56c';ctx.setLineDash([5,5]);ctx.beginPath();ctx.moveTo(from.x,from.y);ctx.lineTo(to.x,to.y);ctx.stroke();ctx.setLineDash([]);
      }
      for(const box of boxes)rect(box,'#f1aa66',active?0.20:0.035,!active);
      if(this.editable&&active&&!this.hitEdit&&!m.hitAngle&&m.category!==4){
        const b=boxes[0],left=point(b[0],b[1]+lift),right=point(b[2],b[3]+lift),cx=(left.x+right.x)/2,cy=(left.y+right.y)/2;
        this.boxPixels={left:left.x,right:right.x,top:right.y,bottom:left.y};
        this.handles=[{key:'hitboxBack',x:left.x,y:cy,cursor:'ew-resize'},{key:'reach',x:right.x,y:cy,cursor:'ew-resize'},{key:'height',x:cx,y:right.y,cursor:'ns-resize'},{key:'bottom',x:cx,y:left.y,cursor:'ns-resize'}];
        for(const handle of this.handles){ctx.fillStyle='#f5c78e';ctx.fillRect(handle.x-4,handle.y-4,8,8);ctx.strokeStyle='#111b20';ctx.strokeRect(handle.x-4,handle.y-4,8,8);}
      }
    }
    if(this.options.hit&&this.hitEdit&&this.editable&&phaseAt(m,this.frame)==='active'){
      const {keyIndex,boxIndex}=this.hitEdit,b=m.hitboxTimeline.keys[keyIndex]?.boxes?.[boxIndex]?.map(v=>v/100);
      if(b){
        rect(b,'#ffcf89',.25);const left=point(b[0],b[1]+lift),right=point(b[2],b[3]+lift),cx=(left.x+right.x)/2,cy=(left.y+right.y)/2;
        this.boxPixels={left:left.x,right:right.x,top:right.y,bottom:left.y};
        this.handles=[{key:0,x:left.x,y:cy,cursor:'ew-resize'},{key:2,x:right.x,y:cy,cursor:'ew-resize'},{key:3,x:cx,y:right.y,cursor:'ns-resize'},{key:1,x:cx,y:left.y,cursor:'ns-resize'}].map(h=>({...h,target:'hit-key',keyIndex,boxIndex}));
        for(const h of this.handles){ctx.fillStyle='#ffcf89';ctx.fillRect(h.x-4,h.y-4,8,8);ctx.strokeStyle='#111b20';ctx.strokeRect(h.x-4,h.y-4,8,8);}
      }else{this.handles=[];this.boxPixels=null;}
    }
    if(this.options.hurt&&this.hurtEdit?.custom){
      const region=this.hurtEdit.region,b=hurt[region]?.map(v=>v/100);
      if(b){
        rect(b,'#a5ddf5',0.18);const left=point(b[0],b[1]+lift),right=point(b[2],b[3]+lift),cx=(left.x+right.x)/2,cy=(left.y+right.y)/2;
        this.boxPixels={left:left.x,right:right.x,top:right.y,bottom:left.y};
        this.handles=[{key:0,x:left.x,y:cy,cursor:'ew-resize'},{key:2,x:right.x,y:cy,cursor:'ew-resize'},{key:3,x:cx,y:right.y,cursor:'ns-resize'},{key:1,x:cx,y:left.y,cursor:'ns-resize'}].map(h=>({...h,target:'hurt'}));
        for(const h of this.handles){ctx.fillStyle='#b9e9ff';ctx.fillRect(h.x-4,h.y-4,8,8);ctx.strokeStyle='#111b20';ctx.strokeRect(h.x-4,h.y-4,8,8);}
        ctx.fillStyle='#b9e9ff';ctx.font='11px system-ui';ctx.fillText(HURT_LABELS[region],left.x,right.y-9);
      }
    }
    ctx.fillStyle='#b9c7ce';ctx.font='10px system-ui';ctx.fillText('px · facing right',w-103,15);
    const p=point(0,lift);ctx.strokeStyle='#eee5d1';ctx.beginPath();ctx.moveTo(p.x-4,p.y);ctx.lineTo(p.x+4,p.y);ctx.moveTo(p.x,p.y-4);ctx.lineTo(p.x,p.y+4);ctx.stroke();
  }
  drawTest(){
    const {record,index}=this.test,frame=record.frames[index];if(!frame)return;
    const canvas=this.canvas,w=canvas.clientWidth,h=canvas.clientHeight,dpr=window.devicePixelRatio||1;
    canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);const ctx=canvas.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);
    if(!record.bounds){
      const fighters=record.frames.flatMap(f=>f.state.players);
      record.bounds={left:Math.min(...fighters.map(p=>p.x/100))-100,right:Math.max(...fighters.map(p=>p.x/100))+125,top:Math.max(190,...fighters.map(p=>p.y/100+180))};
    }
    const b=record.bounds,scale=Math.min((w-40)/(b.right-b.left),(h-65)/b.top),ox=(w-(b.right-b.left)*scale)/2-b.left*scale,oy=h-31;
    const point=(x,y)=>({x:ox+x/100*scale,y:oy-y/100*scale});
    ctx.fillStyle='#101b22';ctx.fillRect(0,0,w,h);ctx.strokeStyle='#263941';ctx.lineWidth=1;
    for(let x=Math.floor(b.left/50)*50;x<b.right;x+=50){const p=point(x*100,0);ctx.beginPath();ctx.moveTo(p.x,30);ctx.lineTo(p.x,oy);ctx.stroke();}
    ctx.strokeStyle='#718086';ctx.beginPath();ctx.moveTo(12,oy);ctx.lineTo(w-12,oy);ctx.stroke();
    const rect=(box,color)=>{const p=point(box[0],box[3]);ctx.fillStyle=color;ctx.globalAlpha=.1;ctx.fillRect(p.x,p.y,(box[2]-box[0])/100*scale,(box[3]-box[1])/100*scale);ctx.globalAlpha=1;ctx.strokeStyle=color;ctx.strokeRect(p.x,p.y,(box[2]-box[0])/100*scale,(box[3]-box[1])/100*scale);};
    frame.state.players.forEach((f,i)=>{
      const p=point(f.x,f.y),phase=['active','windup','block','signature_windup','signature_active'][f.posePhase],sheet=this.pack.art[f.character][phase],tile=sheet?.frames[f.poseIndex];
      ctx.fillStyle='#050d12';ctx.beginPath();ctx.ellipse(p.x,oy,22*scale,5*scale,0,0,Math.PI*2);ctx.fill();
      if(this.options.art&&tile){const img=this.image(sheet.file),s=150/sheet.body_height*scale;if(img.complete&&img.naturalWidth){const [sx,sy,sw,sh]=tile.region;ctx.save();ctx.translate(p.x,p.y);ctx.scale(f.facing,1);ctx.drawImage(img,sx,sy,sw,sh,-tile.pivot[0]*s,-tile.pivot[1]*s,sw*s,sh*s);ctx.restore();}}
      if(this.options.push)frame.boxes[i].push.forEach(box=>rect(box,'#a8ba76'));
      if(this.options.hurt)frame.boxes[i].hurt.forEach(box=>rect(box,'#7bb8d4'));
      if(this.options.hit)frame.boxes[i].hit.forEach(box=>rect(box,'#f1aa66'));
      if(f.weaponVisible){const start=point(f.weaponBackX,f.weaponBackY),end=point(f.weaponTipX,f.weaponTipY);ctx.strokeStyle='#e3c79b';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(start.x,start.y);ctx.lineTo(end.x,end.y);ctx.stroke();ctx.lineWidth=1;}
      ctx.fillStyle=i?'#80d2dc':'#e0ba76';ctx.font='12px system-ui';ctx.textAlign=i?'right':'left';ctx.fillText(`${this.pack.art[f.character].name.toUpperCase()} · ${f.health} HP`,i?w-14:14,18);
    });
    const impact=record.contacts.findLast(c=>c.tick<=index&&index-c.tick<18);
    if(impact){const p=point(impact.x,impact.y),age=index-impact.tick;ctx.strokeStyle=impact.event===2?'#8bd8ed':'#ffcf89';ctx.globalAlpha=1-age/18;ctx.lineWidth=2;ctx.beginPath();ctx.arc(p.x,p.y,8+age*1.5,0,Math.PI*2);ctx.stroke();ctx.fillStyle=ctx.strokeStyle;ctx.textAlign='center';ctx.font='bold 15px system-ui';ctx.fillText(impact.event===2?'BLOCK':`${impact.damage} DAMAGE`,p.x,p.y-24-age);ctx.globalAlpha=1;ctx.lineWidth=1;}
    ctx.textAlign='left';ctx.fillStyle='#b9c7ce';ctx.font='11px system-ui';ctx.fillText(frame.state.hitstop?'IMPACT FREEZE':frame.stage,14,h-10);
  }
  local(event){const r=this.canvas.getBoundingClientRect();return {x:event.clientX-r.left,y:event.clientY-r.top};}
  pick(p){const handle=this.handles.find(h=>Math.hypot(h.x-p.x,h.y-p.y)<14);if(handle)return handle;
    const b=this.boxPixels;if(this.handles.length&&p.x>b.left&&p.x<b.right&&p.y>b.top&&p.y<b.bottom)return {...this.handles[0],key:'move',cursor:'move'};return null;}
  down(event){if(event.button!==0)return;const p=this.local(event),hit=this.pick(p);if(!hit)return;
    event.preventDefault();this.drag={...hit,start:p,attack:structuredClone(this.attack),view:structuredClone(this.view),hurt:structuredClone(this.hurtEdit)};this.canvas.setPointerCapture(event.pointerId);(hit.target==='hurt'?this.onHurtDrag:this.onDrag)('start');}
  move(event){const p=this.local(event);this.canvas.style.cursor=this.drag?.cursor||this.pick(p)?.cursor||'default';if(!this.drag)return;
    const d=this.drag,m=d.attack,dx=Math.round((p.x-d.start.x)/d.view.scale*100),dy=Math.round(-(p.y-d.start.y)/d.view.scale*100);let patch={};
    if(d.target==='hurt'){
      const {phase,region}=d.hurt,b=[...m.hurtboxes[phase][region]];
      if(d.key==='move'){b[0]+=dx;b[2]+=dx;b[1]+=dy;b[3]+=dy;}else b[d.key]+=(d.key===0||d.key===2)?dx:dy;
      this.onHurtDrag('change',{phase,region,rect:b});return;
    }
    if(d.target==='hit-key'){
      const b=[...m.hitboxTimeline.keys[d.keyIndex].boxes[d.boxIndex]];
      if(d.key==='move'){b[0]+=dx;b[2]+=dx;b[1]+=dy;b[3]+=dy;}else b[d.key]+=(d.key===0||d.key===2)?dx:dy;
      this.onDrag('change',{keyIndex:d.keyIndex,boxIndex:d.boxIndex,rect:b});return;
    }
    if(d.key==='move')patch={hitboxBack:m.hitboxBack+dx,reach:m.reach+dx,bottom:m.bottom+dy};
    else if(d.key==='height')patch={height:m.height+dy};
    else if(d.key==='bottom')patch={bottom:m.bottom+dy,height:m.height-dy};
    else patch={[d.key]:m[d.key]+dx};
    this.onDrag('change',patch);
  }
  up(){if(!this.drag)return;const callback=this.drag.target==='hurt'?this.onHurtDrag:this.onDrag;this.drag=null;callback('end');this.draw();}
}
