// Capture actual registered sprites and simulation clocks; no pose synthesis.
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,writeFile} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {resolve} from 'node:path';
import {serveWorkshopSite} from './serve-workbench.mjs';
const out=resolve('build/fillet-sweep-timing-review'),frames=resolve(out,'capture');
await mkdir(frames,{recursive:true});
const server=await serveWorkshopSite(0);
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage();await page.goto(`http://127.0.0.1:${server.address().port}/fillet-motion-review.html`);
 await page.evaluate(()=>filletReview.ready);await page.evaluate(()=>filletReview.seek(1));
 const lengths=await page.evaluate(()=>{const m=filletReview.pack.moves[2];return {whiff:m.timeline.length,hit:m.contactTimeline.length};});
 for(const slow of [false,true])for(const scenario of ['whiff','hit'])for(let tick=1;tick<=lengths[scenario]+18;tick++){
  const url=await page.evaluate(({tick,slow,scenario})=>{
   const {pack,paint}=filletReview,m=pack.moves[2],length=(scenario==='hit'?m.contactTimeline:m.timeline).length;
   const c=document.createElement('canvas');c.width=1280;c.height=560;const ctx=c.getContext('2d');
   ctx.fillStyle='#0c161c';ctx.fillRect(0,0,c.width,c.height);ctx.fillStyle='#e1b76d';ctx.font='italic 700 28px system-ui';
   ctx.fillText('FILLET / 2S — HOLD, CUT, RECOVER',20,34);ctx.fillStyle='#b9cbd0';ctx.font='17px system-ui';
   ctx.fillText(`${slow?'½ speed':'1× game speed'} · ${scenario==='hit'?'On hit · actual 9-frame hitstop':'Whiff'} · Startup 12 / Active 4 / Recovery 23`,20,65);
   for(let col=0;col<2;col++){
    const scratch=document.createElement('canvas');scratch.width=640;scratch.height=450;
    paint(scratch,m,Math.min(tick,length),col===0,{scenario,mirror:false,boxes:false});
    ctx.drawImage(scratch,col*640,110);ctx.fillStyle=col?'#e1b76d':'#b9cbd0';ctx.font='700 19px system-ui';
    ctx.fillText(col?'CURRENT · 7 consistent body poses':'PREVIOUS · 22 evenly spaced drawings',col*640+20,96);
    if(tick>length){ctx.fillStyle='#0c161ce8';ctx.fillRect(col*640+10,115,610,62);ctx.fillStyle='#b9cbd0';ctx.font='18px system-ui';ctx.fillText('Move complete · pause between replays',col*640+20,147);}
   }
   return c.toDataURL('image/png').split(',')[1];
  },{tick,slow,scenario});
  await writeFile(resolve(frames,`${slow?'slow':'normal'}-${scenario}-${tick}.png`),Buffer.from(url,'base64'));
 }
 let sequence='';
 for(const slow of [false,true])for(const scenario of ['whiff','hit'])for(let repeat=0;repeat<(slow?1:3);repeat++){
  for(let tick=1;tick<=lengths[scenario]+18;tick++)sequence+=`file '${slow?'slow':'normal'}-${scenario}-${tick}.png'\nduration ${slow?2/60:1/60}\n`;
 }
 sequence+=`file 'slow-hit-${lengths.hit+18}.png'\n`;await writeFile(resolve(frames,'comparison.txt'),sequence);
 execFileSync('ffmpeg',['-y','-loglevel','error','-f','concat','-safe','0','-i',resolve(frames,'comparison.txt'),'-vf','fps=60','-c:v','libx264','-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',resolve(out,'Fillet-Sweep-Timing.mp4')]);
 for(const scenario of ['whiff','hit'])execFileSync('ffmpeg',['-y','-loglevel','error','-framerate','30','-start_number','1','-i',resolve(frames,`slow-${scenario}-%d.png`),'-filter_complex','[0:v]scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer','-loop','0',resolve(out,`Fillet-Sweep-${scenario}.gif`)]);
 console.log('Captured attack-timed sweep: before/after whiff and actual contact at 1×, then ½×. Half-speed GIFs included; MP4 is the authoritative game-speed preview.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
