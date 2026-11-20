// Capture the new grab art on the actual simulation clock; no interpolated art.
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,writeFile} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {once} from 'node:events';
import {resolve} from 'node:path';
import {serveWorkshopSite} from './serve-workbench.mjs';

const out=resolve('build/fillet-command-grabs-v2');await mkdir(out,{recursive:true});
const server=await serveWorkshopSite(0);
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage();
 await page.goto(`http://127.0.0.1:${server.address().port}/fillet-motion-review.html?move=236D`);
 await page.evaluate(()=>filletReview.ready);await page.evaluate(()=>filletReview.seek(1));
 const clips=await page.evaluate(()=>filletReview.pack.moves.flatMap((m,index)=>['236D','214D'].includes(m.id)?[{id:m.id,index,whiff:m.timeline.length,hit:m.contactTimeline.length}]:[]));
 const encode=async(file,slow)=>{
  const process=spawn('ffmpeg',['-y','-loglevel','error','-f','image2pipe','-framerate','60','-vcodec','mjpeg','-i','pipe:0','-c:v','libx264','-preset','fast','-crf','18','-pix_fmt','yuv420p','-movflags','+faststart',resolve(out,file)],{stdio:['pipe','ignore','pipe']});
  let errors='';process.stderr.on('data',data=>{errors+=data;});const completed=once(process,'close');
  for(const clip of clips)for(const scenario of ['whiff','hit'])for(let repeat=0;repeat<2;repeat++)for(let tick=1;tick<=clip[scenario];tick++){
   const encoded=await page.evaluate(({index,tick,scenario,slow})=>{
    const {pack,paint}=filletReview,m=pack.moves[index],canvas=document.createElement('canvas');
    canvas.width=1280;canvas.height=560;const ctx=canvas.getContext('2d');
    ctx.fillStyle='#0c161c';ctx.fillRect(0,0,1280,560);ctx.fillStyle='#e1b76d';ctx.font='italic 700 28px system-ui';
    ctx.fillText(`FILLET / ${m.id} — ${m.label}`,20,34);ctx.fillStyle='#b9cbd0';ctx.font='17px system-ui';
    ctx.fillText(`${slow?'½ speed inspection':'1× game speed · 60 Hz'} · ${scenario==='hit'?'Successful grab / cashout':'Whiff / committed recovery'} · 22 startup / 2 active / 30 recovery`,20,65);
    for(let column=0;column<2;column++){
     const frame=document.createElement('canvas');frame.width=640;frame.height=450;
     paint(frame,m,tick,column===0,{scenario,mirror:false,boxes:false});ctx.drawImage(frame,column*640,110);
     ctx.fillStyle=column?'#e1b76d':'#b9cbd0';ctx.font='700 19px system-ui';
     ctx.fillText(column?'NEW · distinct catch / held knife cut':'PREVIOUS · shared capture animation',column*640+20,96);
    }
    return canvas.toDataURL('image/jpeg',.94).split(',')[1];
   },{index:clip.index,tick,scenario,slow});
   const bytes=Buffer.from(encoded,'base64');
   for(let held=0;held<(slow?2:1);held++)if(!process.stdin.write(bytes))await once(process.stdin,'drain');
  }
  process.stdin.end();const [code]=await completed;if(code!==0)throw Error(errors);
  console.log('Captured '+file);
 };
 await encode('Fillet-Command-Grabs-60fps.mp4',false);
 await encode('Fillet-Command-Grabs-Half-Speed.mp4',true);
 await writeFile(resolve(out,'capture.json'),JSON.stringify({fps:60,repeats:2,clips,note:'Saved simulation clocks; before is commit 6f46a36. No invented hits, pose interpolation or altered timing.'},null,2)+'\n');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
