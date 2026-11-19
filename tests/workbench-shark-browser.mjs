import {seedBaseline} from './workbench-ui-helpers.mjs';
import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir} from 'node:fs/promises';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {ready,seekMoveFrame} from './workbench-ui-helpers.mjs';
const server=await serveWorkshopSite(0);
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1080}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 await page.addInitScript(()=>{
  globalThis.WebAssembly=undefined;globalThis.sharkPaint=[];
  const draw=CanvasRenderingContext2D.prototype.drawImage;
  CanvasRenderingContext2D.prototype.drawImage=function(...args){
   if(this.canvas.id==='preview')sharkPaint.push({src:args[0].src,rect:args.slice(1),transform:Array.from(this.getTransform().toFloat64Array())});
   return draw.apply(this,args);
  };
 });
 await seedBaseline(page);await page.goto(`http://127.0.0.1:${server.address().port}/`);await ready(page);
 await page.locator('#fighter').selectOption('4');await page.locator('#tab-hit').click();
 await page.locator('#test-gap').fill('70');await page.locator('#test-gap').blur();
 await mkdir('build/shark-review',{recursive:true});
 const urls=await page.evaluate(async()=>{
  const files=Object.keys(FIGHT_WORKSHOP_DATA.images).filter(f=>f.startsWith('shark-normals-v1/'));
  const urls=files.map(f=>new URL(FIGHT_WORKSHOP_DATA.images[f],location.href).href);
  await Promise.all(urls.map(async src=>{const img=new Image();img.src=src;await img.decode();}));
  return urls;
 });assert.equal(urls.length,16);
 for(const facing of ['1','-1']){
  await page.locator('#test-facing').selectOption(facing);
  for(const slot of [0,1,32,2,3,4,5,6,7,17,18,19,20,8,9,11]){
   await page.locator(`[data-move="${slot}"]`).click();await ready(page);
   const start=await page.evaluate(slot=>FIGHT_WORKSHOP_DATA.draft.data.characters[4].moves[slot].startup,slot);
   await page.evaluate(()=>{sharkPaint=[];});await seekMoveFrame(page,start);
   await page.waitForFunction(urls=>sharkPaint.some(p=>urls.includes(p.src)),urls);
   const paint=await page.evaluate(urls=>sharkPaint.filter(p=>urls.includes(p.src)).at(-1),urls);
   assert.equal(Math.sign(paint.transform[0]),Number(facing));
   if(['1'].includes(facing)||slot===7)await page.locator('#preview').screenshot({path:`build/shark-review/slot-${slot}-${facing}.png`});
  }
 }
 await page.locator('[data-move="7"]').click();await ready(page);
 const paints=[];
 for(const tick of [1,6,11,12,14,16,25,37,11]){
  await page.evaluate(()=>{sharkPaint=[];});await seekMoveFrame(page,tick);
  paints.push(await page.evaluate(urls=>sharkPaint.filter(p=>urls.includes(p.src)),urls));
  await page.locator('#preview').screenshot({path:`build/shark-review/scoop-${tick}.png`});
 }
 assert.deepEqual(paints.at(-1),paints[2],'Seeking restores identical animation composition');
 // Keep the target's idle art distinct when checking the selected fighter's
 // actual canvas draws (the default target is also Shark).
 await page.locator('#test-target').selectOption('5');
 await page.locator('#tab-movement').click();await ready(page);
 const movementUrls=await page.evaluate(async()=>{
  const urls=Object.entries(FIGHT_WORKSHOP_DATA.images).filter(([file])=>file.startsWith('shark-movement-v1/')).map(([,url])=>new URL(url,location.href).href);
  await Promise.all(urls.map(async src=>{const image=new Image();image.src=src;await image.decode();}));
  return urls;
 });assert.equal(movementUrls.length,8);
 for(const facing of ['1','-1']){
  await page.locator('#test-facing').selectOption(facing);
  for(const [action,phase,count] of [['idle',11,4],['walk',6,8],['backWalk',13,8],['back',15,6],['forward',7,8]]){
   await page.locator('#movement-action').selectOption(action);await ready(page);
   const frames=await page.evaluate(({phase,count})=>Array.from({length:count},(_,key)=>moveWorkshop.preview().frames.findIndex(f=>f.state.players[0].posePhase===phase&&f.state.players[0].poseIndex===key)),{phase,count});
   assert.ok(frames.every(tick=>tick>=0),`${action}/${facing} misses a pose`);
   const drawn=[];
   for(let key=0;key<count;++key){
    await page.evaluate(()=>{sharkPaint=[];});
    await page.locator('#frame').evaluate((node,tick)=>{node.value=String(tick);node.dispatchEvent(new Event('input',{bubbles:true}));},frames[key]);
    await page.waitForFunction(urls=>sharkPaint.some(p=>urls.includes(p.src)),movementUrls);
    const draw=await page.evaluate(urls=>sharkPaint.filter(p=>urls.includes(p.src)).at(-1),movementUrls);
    assert.equal(Math.sign(draw.transform[0]),Number(facing));drawn.push(`${draw.src}:${draw.rect.slice(0,4).join(',')}`);
    if(facing==='1'&&(key===0||action==='forward'&&key===4||action==='back'&&key===2))await page.locator('#preview').screenshot({path:`build/shark-review/${action}-${key}.png`});
   }
   assert.equal(new Set(drawn).size,count,`${action}: repeated sprite instead of authored key`);
  }
 }
 assert.deepEqual(errors,[]);
 console.log('PASS Shark hosted editor: 16 normal pairs, Low Scoop, all 34 selected movement keys, both facings, saved-frame seeking, plain-JS preview.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
