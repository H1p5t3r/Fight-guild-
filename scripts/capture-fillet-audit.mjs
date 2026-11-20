// Save actual 60 Hz poses; slow sections duplicate frames, never interpolate.
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,writeFile} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {resolve} from 'node:path';
import {serveWorkshopSite} from './serve-workbench.mjs';
const out=resolve('build/fillet-animation-audit');await mkdir(out,{recursive:true});
const server=await serveWorkshopSite(0);
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1400,height:1050}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(`http://127.0.0.1:${server.address().port}/fillet-motion-review.html?move=c.S`);
 await page.evaluate(()=>filletReview.ready);await page.evaluate(()=>filletReview.seek(7));
 await page.screenshot({path:resolve(out,'review-desktop.png'),fullPage:true});
 for(const before of [true,false]){
  const png=await page.evaluate(before=>{
   const {pack,paint}=filletReview,c=document.createElement('canvas');c.width=1920;c.height=900;const ctx=c.getContext('2d');
   for(const [row,id] of ['c.S','j.K','623Hs','2S'].entries()){
    const m=pack.moves.find(m=>m.id===id),ages=[m.startup-1,m.startup,m.startup+m.active-1,m.startup+m.active+Math.floor(m.recovery*.3),m.startup+m.active+Math.floor(m.recovery*.7),m.total];
    ages.forEach((age,col)=>{const p=document.createElement('canvas');p.width=640;p.height=450;
     const tick=Math.max(0,m.timeline.findIndex(f=>f.frame>=age));paint(p,m,tick+1,before,{scenario:'whiff',boxes:col===1,hurt:false,mirror:false,silhouette:false,effects:true});ctx.drawImage(p,col*320,row*225,320,225);});
   }return c.toDataURL('image/png').split(',')[1];
  },before);
  await writeFile(resolve(out,before?'key-poses-before.png':'key-poses-after.png'),Buffer.from(png,'base64'));
 }
 const contacts=await page.evaluate(()=>{
  const {pack,paint}=filletReview,c=document.createElement('canvas');c.width=1280;c.height=1575;const ctx=c.getContext('2d');
  pack.moves.forEach((m,i)=>{const p=document.createElement('canvas');p.width=640;p.height=450;
   const tick=m.contactTimeline.findIndex(f=>f.hitstop>0||f.pairKind);
   paint(p,m,Math.max(0,tick)+1,false,{scenario:'hit',boxes:true,hurt:false,mirror:false,silhouette:false,effects:true});ctx.drawImage(p,(i%4)*320,Math.floor(i/4)*225,320,225);});
  return c.toDataURL('image/png').split(',')[1];
 });await writeFile(resolve(out,'all-contacts.png'),Buffer.from(contacts,'base64'));
 if(!process.argv.includes('--stills')){
  const clips=await page.evaluate(()=>['c.S','j.K','623Hs','2S','236D'].map(id=>{const m=filletReview.pack.moves.find(m=>m.id===id);return {id,whiff:m.timeline.length,hit:m.contactTimeline.length,block:m.blockTimeline.length};}));
  const ffmpeg=spawn('ffmpeg',['-y','-loglevel','error','-f','image2pipe','-framerate','60','-vcodec','mjpeg','-i','pipe:0','-c:v','libx264','-preset','fast','-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',resolve(out,'Fillet-Animation-Audit-60fps.mp4')],{stdio:['pipe','ignore','pipe']});
  let error='';ffmpeg.stderr.on('data',b=>{error+=b;});const completed=once(ffmpeg,'close');
  for(const slow of [false,true])for(const clip of (slow?clips.slice(0,3):clips))for(const scenario of (slow?['whiff']:['whiff','hit','block']))for(let tick=1;tick<=clip[scenario];tick++){
   const jpeg=await page.evaluate(({id,tick,scenario,slow})=>{
    const {pack,paint}=filletReview,m=pack.moves.find(m=>m.id===id),c=document.createElement('canvas');c.width=1280;c.height=560;const ctx=c.getContext('2d');
    ctx.fillStyle='#0c161c';ctx.fillRect(0,0,1280,560);ctx.fillStyle='#e1b76d';ctx.font='italic 700 28px system-ui';ctx.fillText(`FILLET / ${m.id} — ${m.label}`,20,34);
    ctx.fillStyle='#b9cbd0';ctx.font='17px system-ui';ctx.fillText(`${slow?'½ SPEED INSPECTION':'1× GAME SPEED · 60 Hz'} · ${scenario==='block'?'GUARDING TARGET':scenario.toUpperCase()} · ${m.startup} / ${m.active} / ${m.recovery}`,20,65);
    for(let col=0;col<2;col++){const p=document.createElement('canvas');p.width=640;p.height=450;paint(p,m,tick,col===0,{scenario,mirror:false,boxes:false,hurt:false,silhouette:false,effects:true});ctx.drawImage(p,col*640,110);ctx.fillStyle=col?'#e1b76d':'#b9cbd0';ctx.font='700 19px system-ui';ctx.fillText(col?(m.changed?'CURRENT · REFINED':'CURRENT · RETAINED BENCHMARK'):'BEFORE · SAVED PRE-AUDIT RECORDING',col*640+20,96);}
    return c.toDataURL('image/jpeg',.93).split(',')[1];
   },{id:clip.id,tick,scenario,slow});
   const bytes=Buffer.from(jpeg,'base64');
   // Hold the end card briefly without altering any action frame or hitstop.
   for(let repeat=0;repeat<(tick===clip[scenario]?18:slow?2:1);repeat++)if(!ffmpeg.stdin.write(bytes))await once(ffmpeg.stdin,'drain');
  }
  ffmpeg.stdin.end();const [code]=await completed;if(code!==0)throw Error(error);
  await writeFile(resolve(out,'capture.json'),JSON.stringify({fps:60,clips,note:'Actual isolated-action simulation. Final inspection repeats each tick twice. End cards hold for18 video frames after the simulation ends.'},null,2)+'\n');
 }
 await page.setViewportSize({width:390,height:844});await page.locator('#compare').uncheck();await page.screenshot({path:resolve(out,'review-mobile.png'),fullPage:true});
 if(errors.length)throw Error(errors.join('\n'));
 console.log('Captured Fillet guide audit in '+out);
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
