// Render the exact game atlas metadata for visual QA; original artwork is untouched.
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {readFile,mkdir} from 'node:fs/promises';
import {createServer} from 'node:http';
const root='godot/assets/fighters/',catalog=JSON.parse(await readFile(root+'manifest.json','utf8'));
const art=catalog.fighters,images={};
for(const fighter of art)for(const sheet of Object.values(fighter))if(sheet?.frames)for(const frame of sheet.frames){
  const file=frame.file??sheet.file;images[file]='/'+file;
}
await mkdir('build/recovery-review',{recursive:true});
const html='<style>body{margin:0;background:#17232b;color:#edf0e6;font:18px sans-serif}canvas{display:block}</style><canvas id="review"></canvas>';
const server=createServer(async(req,res)=>{
  const file=decodeURIComponent(req.url.slice(1));
  if(!file){res.setHeader('Content-Type','text/html');res.end(html);return;}
  if(!images[file]){res.writeHead(404).end();return;}
  res.setHeader('Content-Type','image/png');res.end(await readFile(root+file));
});
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try {
  const page=await browser.newPage({viewport:{width:1440,height:1400}});
  await page.goto(`http://127.0.0.1:${server.address().port}/`);
  await page.evaluate(({art,images})=>{
    globalThis.reviewArt=art;
    globalThis.drawReview=async rows=>{
      const reviewImages={};
      for(const {c,phase,index} of rows.flat()){
        const sheet=reviewArt[c][phase],frame=sheet.frames[index],file=frame.file??sheet.file;
        if(!reviewImages[file])reviewImages[file]=await createImageBitmap(await (await fetch(images[file])).blob());
      }
      const canvas=document.getElementById('review'),w=240,h=225,scale=1.05;
      canvas.width=1440;canvas.height=rows.length*h;const ctx=canvas.getContext('2d');
      ctx.fillStyle='#17232b';ctx.fillRect(0,0,canvas.width,canvas.height);
      rows.forEach((row,y)=>row.forEach(({c,phase,index,label},x)=>{
        const sheet=reviewArt[c][phase],frame=sheet.frames[index],r=frame.render_region??frame.region;
        const s=150/(frame.body_height??sheet.body_height)*scale,px=x*w+w/2,py=(y+1)*h-15;
        ctx.strokeStyle='#45606e';ctx.beginPath();ctx.moveTo(x*w+8,py);ctx.lineTo((x+1)*w-8,py);ctx.stroke();
        ctx.fillStyle='#e9e6da';ctx.font='14px sans-serif';ctx.fillText(label??`${reviewArt[c].name} · ${frame.name}`,x*w+10,y*h+22);
        ctx.drawImage(reviewImages[frame.file??sheet.file],...r,px+(r[0]-frame.region[0]-frame.pivot[0])*s,py+(r[1]-frame.region[1]-frame.pivot[1])*s,r[2]*s,r[3]*s);
      }));
      for(const image of Object.values(reviewImages))image.close();
    };
  },{art,images});
  for(const phase of ['knockdown','knockdown_back']){
    await page.evaluate(phase=>drawReview(reviewArt.map((_,c)=>Array.from({length:6},(_,index)=>({c,phase,index})))),phase);
    await page.locator('#review').screenshot({path:`build/recovery-review/${phase}.png`});
  }
  const samples=[{c:4,phase:'ready',index:0,label:'Shark · ready'},{c:5,phase:'ready',index:0,label:'Fillet · stalker'},
    {c:3,phase:'ready',index:0,label:'Tapper · ready'},...[[0,'5P'],[1,'5K'],[4,'5Hs'],[10,'6P'],[12,'6Hs'],[24,'st.P'],[27,'st.Hs']].map(([index,label])=>({c:3,phase:'signature_active',index,label:'Tapper · '+label})),
    {c:3,phase:'walk',index:0,label:'Tapper · walk'},{c:3,phase:'run',index:3,label:'Tapper · step'}];
  await page.evaluate(samples=>drawReview([samples.slice(0,6),samples.slice(6)]),samples);
  await page.locator('#review').screenshot({path:'build/recovery-review/tapper-scale.png'});
  console.log('Rendered front/back recovery sequences and Tapper scale comparison to build/recovery-review.');
} finally {await browser.close();await new Promise(resolve=>server.close(resolve));}
