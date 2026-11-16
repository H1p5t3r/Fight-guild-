import {phaseAt,attackBoxes} from './model.mjs';
export class Preview {
  constructor(canvas,pack,onDrag){
    this.canvas=canvas;this.pack=pack;this.onDrag=onDrag;this.images=new Map();this.options={hit:true,hurt:true,push:false,art:true};this.handles=[];this.editable=false;
    this.observer=new ResizeObserver(()=>this.draw());this.observer.observe(canvas);
    canvas.addEventListener('pointerdown',event=>this.down(event));
    canvas.addEventListener('pointermove',event=>this.move(event));
    for(const type of ['pointerup','pointercancel','lostpointercapture'])canvas.addEventListener(type,event=>this.up(event));
  }
  pose(){
    const m=this.attack,phase=phaseAt(m,this.frame);
    if(m.artPose&&phase!=='recovery')return {phase:'signature_'+phase,index:m.artPose-1};
    return phase==='recovery'?{phase:'active',index:m.air?8:[1,2,3].includes(m.direction)?11:0}:{phase,index:1+m.button};
  }
  show(character,attack,frame,editable=false){this.character=character;this.attack=attack;this.frame=frame;this.editable=editable;this.draw();}
  image(file){
    if(!this.images.has(file)){
      const img=new Image();img.onload=()=>{document.getElementById('preview-empty').hidden=true;this.draw();};img.onerror=()=>{document.getElementById('preview-empty').hidden=false;};
      img.src=this.pack.images[file];this.images.set(file,img);
    }
    return this.images.get(file);
  }
  draw(){
    if(!this.attack)return;
    const canvas=this.canvas,w=canvas.clientWidth,h=canvas.clientHeight;if(!w||!h)return;
    const dpr=window.devicePixelRatio||1;canvas.width=Math.round(w*dpr);canvas.height=Math.round(h*dpr);
    const ctx=canvas.getContext('2d');ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,w,h);
    const m=this.attack,pose=this.pose(),sheet=this.pack.art[this.character][pose.phase],tile=sheet?.frames[pose.index];
    const source=this.pack.collisions[this.character],push=source.push;
    const lift=m.air?60:0;
    const boxes=attackBoxes(m,this.frame,push).map(b=>b.map(x=>x/100));
    // Keep the camera fixed for the entire pose cycle, including the full hook path.
    const allBoxes=[...attackBoxes(m,m.startup,push),...attackBoxes(m,m.startup+m.active-1,push)].map(b=>b.map(x=>x/100));
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
    if(this.options.hurt&&tile){
      const hurt=source.poses[pose.phase]?.[pose.index]?.hurt||{};
      for(const [region,b] of Object.entries(hurt)){
        const s=150/sheet.body_height;rect([(b[0]-tile.pivot[0])*s,(tile.pivot[1]-b[3])*s,(b[2]-tile.pivot[0])*s,(tile.pivot[1]-b[1])*s],'#7bb8d4',0.06);
      }
    }
    this.handles=[];
    if(this.options.hit){
      const active=phaseAt(m,this.frame)==='active';
      if(m.hitAngle){
        const from=point(m.hitboxBack/100,m.bottom/100+lift),to=point(m.reach/100,m.bottom/100+lift+m.hitAngle*(m.reach-m.hitboxBack)/100);
        ctx.strokeStyle='#efb56c';ctx.setLineDash([5,5]);ctx.beginPath();ctx.moveTo(from.x,from.y);ctx.lineTo(to.x,to.y);ctx.stroke();ctx.setLineDash([]);
      }
      for(const box of boxes)rect(box,'#f1aa66',active?0.20:0.035,!active);
      if(this.editable&&active&&!m.hitAngle&&m.category!==4){
        const b=boxes[0],left=point(b[0],b[1]+lift),right=point(b[2],b[3]+lift),cx=(left.x+right.x)/2,cy=(left.y+right.y)/2;
        this.boxPixels={left:left.x,right:right.x,top:right.y,bottom:left.y};
        this.handles=[{key:'hitboxBack',x:left.x,y:cy,cursor:'ew-resize'},{key:'reach',x:right.x,y:cy,cursor:'ew-resize'},{key:'height',x:cx,y:right.y,cursor:'ns-resize'},{key:'bottom',x:cx,y:left.y,cursor:'ns-resize'}];
        for(const handle of this.handles){ctx.fillStyle='#f5c78e';ctx.fillRect(handle.x-4,handle.y-4,8,8);ctx.strokeStyle='#111b20';ctx.strokeRect(handle.x-4,handle.y-4,8,8);}
      }
    }
    ctx.fillStyle='#b9c7ce';ctx.font='10px system-ui';ctx.fillText('px · facing right',w-103,15);
    const p=point(0,lift);ctx.strokeStyle='#eee5d1';ctx.beginPath();ctx.moveTo(p.x-4,p.y);ctx.lineTo(p.x+4,p.y);ctx.moveTo(p.x,p.y-4);ctx.lineTo(p.x,p.y+4);ctx.stroke();
  }
  local(event){const r=this.canvas.getBoundingClientRect();return {x:event.clientX-r.left,y:event.clientY-r.top};}
  pick(p){const handle=this.handles.find(h=>Math.hypot(h.x-p.x,h.y-p.y)<14);if(handle)return handle;
    const b=this.boxPixels;if(this.handles.length&&p.x>b.left&&p.x<b.right&&p.y>b.top&&p.y<b.bottom)return {key:'move',cursor:'move'};return null;}
  down(event){if(event.button!==0)return;const p=this.local(event),hit=this.pick(p);if(!hit)return;
    event.preventDefault();this.drag={...hit,start:p,attack:structuredClone(this.attack),view:structuredClone(this.view)};this.canvas.setPointerCapture(event.pointerId);this.onDrag('start');}
  move(event){const p=this.local(event);this.canvas.style.cursor=this.drag?.cursor||this.pick(p)?.cursor||'default';if(!this.drag)return;
    const d=this.drag,m=d.attack,dx=Math.round((p.x-d.start.x)/d.view.scale*100),dy=Math.round(-(p.y-d.start.y)/d.view.scale*100);let patch={};
    if(d.key==='move')patch={hitboxBack:m.hitboxBack+dx,reach:m.reach+dx,bottom:m.bottom+dy};
    else if(d.key==='height')patch={height:m.height+dy};
    else if(d.key==='bottom')patch={bottom:m.bottom+dy,height:m.height-dy};
    else patch={[d.key]:m[d.key]+dx};
    this.onDrag('change',patch);
  }
  up(){if(!this.drag)return;this.drag=null;this.onDrag('end');this.draw();}
}
