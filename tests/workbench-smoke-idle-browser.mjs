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
   if(this.canvas.id==='preview')idlePaint.push({src:args[0].src,rect:args.slice(1),alpha:this.globalAlpha,transform:Array.from(this.getTransform().toFloat64Array())});
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
 // Approved G3 forward/backward body lean keeps the opponent-facing direction;
 // only the rear vapor mirrors when retreating. Seeking reproduces both layers.
 for(const facing of ['1','-1'])for(const [action,phase,name] of [['walk',6,'walk'],['backWalk',13,'back_walk'],['forward',7,'run']]){
  await page.locator('#test-facing').selectOption(facing);
  await page.locator('#movement-action').selectOption(action);
  await page.waitForFunction(({action,phase})=>!moveWorkshop.cursor().pending&&moveWorkshop.preview().movement===action&&moveWorkshop.preview().frames.some(f=>f.state.players[0].posePhase===phase),{action,phase});
  const record=await page.evaluate(()=>moveWorkshop.preview()),moving=record.frames.filter(f=>f.state.players[0].posePhase===phase);
  assert.ok(moving.length>10);
  assert.ok(new Set(moving.map(f=>f.state.players[0].poseIndex)).size>=4);
  assert.ok(moving.every(f=>f.state.players[0].y===0&&f.state.players[0].facing===Number(facing)&&f.boxes[0].hurt.length===4&&f.boxes[0].hit.length===0));
  const urls=await page.evaluate(async name=>{
   const pack=FIGHT_WORKSHOP_DATA,art=pack.art[2],files=[art.movement_smoke.file,art[name].file];
   const urls=files.map(file=>new URL(pack.images[file],location.href).href);
   await Promise.all(urls.map(async src=>{const img=new Image();img.src=src;await img.decode();}));return urls;
  },name);
  const tick=record.frames.findIndex((f,i)=>i>=15&&f.state.players[0].posePhase===phase);
  let first;
  for(const seek of [tick,tick+5,tick]){
   await page.evaluate(()=>{idlePaint=[];});
   await page.locator('#frame').evaluate((node,tick)=>{node.value=String(tick);node.dispatchEvent(new Event('input',{bubbles:true}));},seek);
   await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
   const paint=await page.evaluate(urls=>idlePaint.filter(p=>urls.includes(p.src)).slice(-3),urls);
   assert.deepEqual(paint.map(p=>p.src),[urls[0],urls[0],urls[1]]);
   assert.ok(Math.abs(paint[0].alpha+paint[1].alpha-.55)<.000001);
   assert.equal(Math.sign(paint[2].transform[0]),Number(facing),'Body must keep facing its opponent');
   assert.equal(Math.sign(paint[0].transform[0]),Number(facing)*(phase===13?-1:1),'Vapor must trail movement');
   if(!first)first=paint;else if(seek===tick)assert.deepEqual(paint,first);
  }
  await page.locator('#preview').screenshot({path:`build/smoke-idle-review/${name}-${facing}.png`});
 }
 // A selected attack must hide both ambient vapor clips entirely.
 await page.locator('#tab-hit').click();await page.locator('[data-move="0"]').click();await ready(page);
 const active=await page.evaluate(()=>moveWorkshop.preview().frames.findIndex(f=>f.state.players[0].move===0&&f.state.players[0].posePhase===4));
 assert.ok(active>=0);await page.evaluate(()=>{idlePaint=[];});
 await page.locator('#frame').evaluate((node,tick)=>{node.value=String(tick);node.dispatchEvent(new Event('input',{bubbles:true}));},active);
 await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
 assert.equal(await page.evaluate(()=>idlePaint.some(p=>['idle_smoke','movement_smoke'].some(phase=>p.src===new URL(FIGHT_WORKSHOP_DATA.images[FIGHT_WORKSHOP_DATA.art[2][phase].file],location.href).href))),false);
 assert.deepEqual(errors,[]);
 console.log('PASS Smoke A/H/G3/R4: hosted PNGs, idle/drift/run, both facings, body/vapor orientation, rear-vapor order, frozen frame seeking without WebAssembly.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
