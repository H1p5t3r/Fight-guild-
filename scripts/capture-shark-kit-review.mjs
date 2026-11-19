// Encode actual saved simulation frames. No synthesized or blended drawings.
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,writeFile} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {resolve} from 'node:path';
import {serveWorkshopSite} from './serve-workbench.mjs';
const out=resolve('build/shark-kit-review');await mkdir(out,{recursive:true});
const server=await serveWorkshopSite(0);
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage();await page.goto(`http://127.0.0.1:${server.address().port}/shark-motion-review.html`);
 await page.evaluate(()=>sharkReview.ready);await page.evaluate(()=>sharkReview.seek(1));
 const moves=await page.evaluate(()=>sharkReview.pack.moves.map(m=>({id:m.id,whiff:m.timeline.length,hit:m.contactTimeline.length})));
 const encode=async(file,indices,slow=false)=>{
  const ffmpeg=spawn('ffmpeg',['-y','-loglevel','error','-f','image2pipe','-framerate','60','-vcodec','mjpeg','-i','pipe:0','-c:v','libx264','-preset','fast','-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',resolve(out,file)],{stdio:['pipe','ignore','pipe']});
  let error='';ffmpeg.stderr.on('data',b=>{error+=b;});const completed=once(ffmpeg,'close');
  for(const index of indices)for(const scenario of ['whiff','hit'])for(let tick=1;tick<=moves[index][scenario];tick++){
   const base64=await page.evaluate(({index,tick,scenario,slow})=>{
    const {pack,paint}=sharkReview,m=pack.moves[index];
    const c=document.createElement('canvas');c.width=1280;c.height=560;const ctx=c.getContext('2d');
    ctx.fillStyle='#0c161c';ctx.fillRect(0,0,c.width,c.height);ctx.fillStyle='#e1b76d';ctx.font='italic 700 28px system-ui';
    ctx.fillText(`SHARK / ${m.id} — ${m.label}`,20,34);ctx.fillStyle='#b9cbd0';ctx.font='17px system-ui';
    ctx.fillText(`${slow?'½ speed inspection':'1× game speed · 60 Hz'} · ${scenario==='hit'?'Contact / capture':'Whiff'} · ${m.startup} startup / ${m.active} active / ${m.recovery} recovery`,20,65);
    for(let col=0;col<2;col++){
     const scratch=document.createElement('canvas');scratch.width=640;scratch.height=450;paint(scratch,m,tick,col===0,{scenario,mirror:false,boxes:false});
     ctx.drawImage(scratch,col*640,110);ctx.fillStyle=col?'#e1b76d':'#b9cbd0';ctx.font='700 19px system-ui';ctx.fillText(col?'CURRENT · attack-timed poses':'PREVIOUS · drawings on current clock',col*640+20,96);
    }
    return c.toDataURL('image/jpeg',.93).split(',')[1];
   },{index,tick,scenario,slow});
   const bytes=Buffer.from(base64,'base64');
   for(let repeat=0;repeat<(slow?2:1);repeat++)if(!ffmpeg.stdin.write(bytes))await once(ffmpeg.stdin,'drain');
  }
  ffmpeg.stdin.end();const [code]=await completed;if(code!==0)throw Error(error);console.log('Captured '+file);
 };
 await encode('Shark-Full-Kit-60fps.mp4',moves.map((_,i)=>i));
 await encode('Shark-Drive-and-Hooks-Half-Speed.mp4',['5D','j.D','2D','214S','j.214P','2Hs','6P+K'].map(id=>moves.findIndex(m=>m.id===id)),true);
 await writeFile(resolve(out,'capture.json'),JSON.stringify({fps:60,moves,note:'Actual simulation poses, roots, hitstop, landing and capture clocks; half-speed file explicitly duplicates each simulation tick.'},null,2)+'\n');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
