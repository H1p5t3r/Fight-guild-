// Capture the same registered PNGs/timeline shown by the review, without
// synthesizing poses or changing source artwork. Requires a built Workshop.
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,writeFile} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {resolve} from 'node:path';
import {serveWorkshopSite} from './serve-workbench.mjs';

const out=resolve('build/fillet-twos-review'),frames=resolve(out,'capture');
await mkdir(frames,{recursive:true});
const server=await serveWorkshopSite(0);
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage();
 await page.goto(`http://127.0.0.1:${server.address().port}/fillet-motion-review.html`);
 await page.evaluate(()=>filletReview.ready);await page.evaluate(()=>filletReview.seek(1));
 const png=async(args,file)=>{
  const url=await page.evaluate(({tick,slow,sweep})=>{
   const {pack,paint}=filletReview,c=document.createElement('canvas');c.width=sweep?1280:1920;c.height=sweep?520:1060;
   const ctx=c.getContext('2d');ctx.fillStyle='#0c161c';ctx.fillRect(0,0,c.width,c.height);
   ctx.fillStyle='#e1b76d';ctx.font='italic 700 30px system-ui';
   ctx.fillText(sweep?'FILLET / 2S — KNIFE REACH':'FILLET / ANIMATION ON TWOS',24,40);
   ctx.fillStyle='#b9cbd0';ctx.font='18px system-ui';
   ctx.fillText(sweep?'¼ speed · generated weapon arc / actual hitbox':`${slow?'¼ speed':'1× game speed'} · phase-entry drawings, then every second action frame · original timing`,24,68);
   const moves=sweep?[pack.moves[2]]:pack.moves;
   moves.forEach((m,i)=>{
    const t=Math.min(tick,m.total),scratch=document.createElement('canvas');scratch.width=640;scratch.height=450;
    for(let row=0;row<2;row++){
     document.getElementById('boxes').checked=sweep&&row===1;
     paint(scratch,m,t,sweep?false:row===0);
     const x=sweep?row*640:i*640,y=sweep?70:140+row*450;
     ctx.drawImage(scratch,x,y);
     if(!sweep){ctx.fillStyle=row?'#e1b76d':'#b9cbd0';ctx.font='700 19px system-ui';ctx.fillText(`${m.id} · ${row?'UPDATED':'ORIGINAL'} · ${row?m.after.length:m.before.length} drawings`,x+20,y-12);}
     if(tick>m.total){ctx.fillStyle='#0c161ce8';ctx.fillRect(x+10,y+4,610,64);ctx.fillStyle='#b9cbd0';ctx.font='18px system-ui';ctx.fillText(`${m.id} complete · pause between replays`,x+20,y+35);}
    }
   });
   return c.toDataURL('image/png').split(',')[1];
  },args);
  await writeFile(file,Buffer.from(url,'base64'));
 };
 let concat='';
 for(const slow of [false,true]){
  for(let tick=1;tick<=50;tick++)await png({tick,slow,sweep:false},resolve(frames,`${slow?'slow':'normal'}-${tick}.png`));
  for(let repeat=0;repeat<3;repeat++)for(let tick=1;tick<=50;tick++)concat+=`file '${slow?'slow':'normal'}-${tick}.png'\nduration ${slow?4/60:1/60}\n`;
 }
 concat+="file 'slow-50.png'\n";await writeFile(resolve(frames,'compare.txt'),concat);
 execFileSync('ffmpeg',['-y','-loglevel','error','-f','concat','-safe','0','-i',resolve(frames,'compare.txt'),'-vf','fps=60','-c:v','libx264','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',resolve(out,'Fillet-Animation-Comparison.mp4')]);
 for(let tick=1;tick<=38;tick++)await png({tick,slow:true,sweep:true},resolve(frames,`sweep-${String(tick).padStart(3,'0')}.png`));
 execFileSync('ffmpeg',['-y','-loglevel','error','-framerate','15','-i',resolve(frames,'sweep-%03d.png'),'-filter_complex','[0:v]scale=960:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer','-loop','0',resolve(out,'Fillet-Sweep-Reach.gif')]);
 console.log('Captured exact timeline: Fillet-Animation-Comparison.mp4 (1× then ¼×), Fillet-Sweep-Reach.gif (¼× clean and hitbox).');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
