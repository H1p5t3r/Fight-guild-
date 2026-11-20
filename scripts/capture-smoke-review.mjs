import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,writeFile} from 'node:fs/promises';
import {execFileSync} from 'node:child_process';
import {resolve} from 'node:path';
import {serveWorkshopSite} from './serve-workbench.mjs';

const beforeOnly=process.argv.includes('--before'),stillsOnly=process.argv.includes('--stills'),out=resolve('build/smoke-specials-audit'),frames=resolve(out,'frames');
await mkdir(frames,{recursive:true});
const server=await serveWorkshopSite(0),browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1360,height:1020}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(`http://127.0.0.1:${server.address().port}/smoke-motion-review.html`);await page.evaluate(()=>smokeReview.ready);
 await page.evaluate(()=>{smokeReview.select(0,'whiff');smokeReview.seek(smokeReview.pack.moves[0].scenarios.whiff.findIndex(f=>f.frame===26));});
 await page.screenshot({path:resolve(out,beforeOnly?'before-desktop.png':'review-desktop.png'),fullPage:true});
 const contactSheet=await page.evaluate(()=>{
  const c=document.createElement('canvas');c.width=1280;c.height=1680;const ctx=c.getContext('2d');
  for(let i=0;i<8;i++){const m=smokeReview.pack.moves[i],track=m.scenarios.hit,tick=track.findIndex(f=>f.contact)||m.startup;
   const panel=document.createElement('canvas');panel.width=640;panel.height=420;smokeReview.paint(panel,m,tick,false,{scenario:'hit',boxes:true,hurt:false,mirror:false});ctx.drawImage(panel,(i%2)*640,Math.floor(i/2)*420);
  }return c.toDataURL('image/png').split(',')[1];
 });
 await writeFile(resolve(out,beforeOnly?'audit-before.png':'audit-after.png'),Buffer.from(contactSheet,'base64'));
 const study=await page.evaluate(()=>{
  const canvas=document.createElement('canvas');canvas.width=1920;canvas.height=840;const ctx=canvas.getContext('2d');
  smokeReview.pack.moves.slice(0,4).forEach((m,row)=>{
   const ticks=m.slot===14||m.slot===25?[m.startup-1,m.startup,m.startup+4,m.startup+18,m.startup+26,m.startup+32]:[m.startup-1,m.startup,m.startup+m.active+2,m.startup+m.active+Math.floor(m.recovery/3),m.startup+m.active+Math.floor(2*m.recovery/3),m.startup+m.active+Math.floor(5*m.recovery/6)];
   ticks.forEach((age,col)=>{const panel=document.createElement('canvas');panel.width=640;panel.height=420;const tick=m.scenarios.whiff.findIndex(f=>f.frame===age);smokeReview.paint(panel,m,tick,false,{scenario:'whiff',effects:true,boxes:false,hurt:false,mirror:false});ctx.drawImage(panel,col*320,row*210,320,210);});
  });return canvas.toDataURL('image/png').split(',')[1];
 });
 await writeFile(resolve(out,beforeOnly?'keys-before.png':'keys-after.png'),Buffer.from(study,'base64'));
 if(!beforeOnly&&!stillsOnly){
  const lengths=await page.evaluate(()=>smokeReview.pack.moves.slice(0,4).map(m=>Object.fromEntries(['hit','whiff','block'].map(s=>[s,m.scenarios[s].length]))));
  let sequence='';
  for(let i=0;i<4;i++)for(const scenario of ['whiff','hit','block']){
   for(let tick=0;tick<lengths[i][scenario];tick++){
    const png=await page.evaluate(({i,scenario,tick})=>{
     const {pack,paint}=smokeReview,m=pack.moves[i],c=document.createElement('canvas');c.width=1280;c.height=520;const ctx=c.getContext('2d');
     ctx.fillStyle='#0c171d';ctx.fillRect(0,0,1280,520);ctx.fillStyle='#d5e29a';ctx.font='italic 700 26px system-ui';ctx.fillText(`SMOKE / ${m.id} — ${m.label.toUpperCase()}`,20,32);ctx.fillStyle='#afc1c7';ctx.font='16px system-ui';ctx.fillText(`1× game speed · ${scenario.toUpperCase()} · actual simulation and contact freeze`,20,58);
     for(let col=0;col<2;col++){const panel=document.createElement('canvas');panel.width=640;panel.height=420;paint(panel,m,tick,col===0,{scenario,boxes:false,hurt:false,mirror:false,effects:true,silhouette:false});ctx.drawImage(panel,col*640,100);ctx.fillStyle=col?'#d5e29a':'#afc1c7';ctx.font='700 16px system-ui';ctx.fillText(col?'CURRENT · FOLLOW-THROUGH & SETTLE':'PREVIOUS · CONTACT THEN RESET',col*640+20,86);}
     return c.toDataURL('image/png').split(',')[1];
    },{i,scenario,tick});
    const name=`${i}-${scenario}-${tick}.png`;await writeFile(resolve(frames,name),Buffer.from(png,'base64'));sequence+=`file '${name}'\nduration ${1/60}\n`;
   }
   sequence+=`file '${i}-${scenario}-${lengths[i][scenario]-1}.png'\nduration 0.3\n`;
  }
  sequence+=`file '3-block-${lengths[3].block-1}.png'\n`;
  await writeFile(resolve(frames,'sequence.txt'),sequence);
  execFileSync('ffmpeg',['-y','-loglevel','error','-f','concat','-safe','0','-i',resolve(frames,'sequence.txt'),'-vf','fps=60','-c:v','libx264','-crf','19','-pix_fmt','yuv420p','-movflags','+faststart',resolve(out,'Smoke-Specials-Before-After-60fps.mp4')]);
 }
 await page.setViewportSize({width:390,height:844});await page.evaluate(()=>{smokeReview.select(1,'hit');smokeReview.seek(32);});await page.screenshot({path:resolve(out,beforeOnly?'before-mobile.png':'review-mobile.png'),fullPage:true});
 if(errors.length)throw Error(errors.join('\n'));
 console.log(`Captured ${beforeOnly?'baseline audit':stillsOnly?'final review stills':'final review and 60fps MP4'} in ${out}`);
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
