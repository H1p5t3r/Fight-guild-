import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir} from 'node:fs/promises';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {ready} from './workbench-ui-helpers.mjs';
const server=await serveWorkshopSite(0);
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1080}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 await page.addInitScript(()=>{
  globalThis.WebAssembly=undefined;globalThis.idlePaint=[];
  const original=CanvasRenderingContext2D.prototype.drawImage;
  CanvasRenderingContext2D.prototype.drawImage=function(...args){
   if(this.canvas.id==='preview')idlePaint.push({src:args[0].src,rect:args.slice(1),alpha:this.globalAlpha});
   return original.apply(this,args);
  };
 });
 await page.goto(`http://127.0.0.1:${server.address().port}/`);await ready(page);
 await page.locator('#fighter').selectOption('2');await page.locator('#tab-movement').click();await ready(page);
 await mkdir('build/smoke-idle-review',{recursive:true});
 for(const facing of ['1','-1'])for(const [action,phase] of [['idle',11],['crouch',12]]){
  await page.locator('#test-facing').selectOption(facing);
  await page.locator('#movement-action').selectOption(action);
  await page.waitForFunction(({action,phase})=>!moveWorkshop.cursor().pending&&moveWorkshop.preview().movement===action&&moveWorkshop.preview().frames[1].state.players[0].posePhase===phase,{action,phase});
  const record=await page.evaluate(()=>moveWorkshop.preview());
  assert.deepEqual([...new Set(record.frames.slice(1).map(f=>f.state.players[0].poseIndex))].sort(),[0,1,2,3]);
  assert.ok(record.frames.slice(1).every(f=>f.state.players[0].y===0&&f.boxes[0].hurt.length===4&&f.boxes[0].hit.length===0));
  const urls=await page.evaluate(async phase=>{
   const pack=FIGHT_WORKSHOP_DATA,art=pack.art[2],files=[art.idle_smoke.file,art[phase===11?'idle':'crouch_idle'].file];
   const urls=files.map(file=>new URL(pack.images[file],location.href).href);
   await Promise.all(urls.map(async src=>{const img=new Image();img.src=src;await img.decode();}));return urls;
  },phase);
  let first;
  // The same saved frame must paint identically after seeking backward, and
  // the two smoke keys must be painted before the owning body.
  for(const tick of [15,45,15,95]){
   await page.evaluate(()=>{idlePaint=[];});
   await page.locator('#frame').evaluate((node,tick)=>{node.value=String(tick);node.dispatchEvent(new Event('input',{bubbles:true}));},tick);
   await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
   const paint=await page.evaluate(urls=>idlePaint.filter(p=>urls.includes(p.src)).slice(-3),urls);
   assert.deepEqual(paint.map(p=>p.src),[urls[0],urls[0],urls[1]]);
   assert.ok(Math.abs(paint[0].alpha+paint[1].alpha-0.65)<0.000001);
   if(!first)first=paint;
   if(tick===15||tick===95)assert.deepEqual(paint,first,'Loop or backward seek changed the saved presentation');
  }
  await page.locator('#preview').screenshot({path:`build/smoke-idle-review/${action}-${facing}.png`});
 }
 // A selected attack must hide the ambient idle vapor entirely.
 await page.locator('#tab-hit').click();await page.locator('[data-move="0"]').click();await ready(page);
 const active=await page.evaluate(()=>moveWorkshop.preview().frames.findIndex(f=>f.state.players[0].move===0&&f.state.players[0].posePhase===4));
 assert.ok(active>=0);await page.evaluate(()=>{idlePaint=[];});
 await page.locator('#frame').evaluate((node,tick)=>{node.value=String(tick);node.dispatchEvent(new Event('input',{bubbles:true}));},active);
 await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
 assert.equal(await page.evaluate(()=>idlePaint.some(p=>p.src===new URL(FIGHT_WORKSHOP_DATA.images[FIGHT_WORKSHOP_DATA.art[2].idle_smoke.file],location.href).href)),false);
 assert.deepEqual(errors,[]);
 console.log('PASS Smoke A/H idles: hosted PNG decoding, body keys, crouch action, both facings, rear-vapor order, seamless clock wrap and backward seeking without WebAssembly.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
