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
  globalThis.WebAssembly=undefined;globalThis.attackPaint=[];
  const original=CanvasRenderingContext2D.prototype.drawImage;
  CanvasRenderingContext2D.prototype.drawImage=function(...args){
   if(this.canvas.id==='preview')attackPaint.push({src:args[0].src,rect:args.slice(1),transform:Array.from(this.getTransform().toFloat64Array())});
   return original.apply(this,args);
  };
 });
 await page.goto(`http://127.0.0.1:${server.address().port}/`);await ready(page);
 await page.locator('#fighter').selectOption('2');await page.locator('#tab-hit').click();
 await page.locator('#test-gap').fill('120');await page.locator('#test-gap').blur();
 await mkdir('build/smoke-attacks-review',{recursive:true});
 const urls=await page.evaluate(async()=>{
  const pack=FIGHT_WORKSHOP_DATA,files=['backdraft_body_a','backdraft_body_b','backdraft_fx','special_entries','pillar_bodies','sword_bodies','sword_effects','pillar_effect'].map(n=>'smoke-attacks-v2/'+n+'.png');
  const urls=Object.fromEntries(files.map(f=>[f,new URL(pack.images[f],location.href).href]));
  await Promise.all(Object.values(urls).map(async src=>{const i=new Image();i.src=src;await i.decode();}));return urls;
 });
 for(const facing of ['1','-1']){
  await page.locator('#test-facing').selectOption(facing);
  for(const [slot,start,name] of [[7,18,'backdraft'],[14,13,'close-pillar'],[25,25,'far-pillar'],[15,15,'poison'],[16,29,'fire']]){
   await page.locator(`[data-move="${slot}"]`).click();await ready(page);
   await page.evaluate(()=>{attackPaint=[];});await seekMoveFrame(page,start);
   const file=slot===7?'backdraft_fx':slot===14||slot===25?'pillar_effect':'sword_effects';
   const url=urls['smoke-attacks-v2/'+file+'.png'];
   await page.waitForFunction(url=>attackPaint.some(p=>p.src===url),url);
   const paints=await page.evaluate(url=>attackPaint.filter(p=>p.src===url),url);
   assert.ok(paints.length>0);
   if(slot===15||slot===16)assert.equal(Math.sign(paints.at(-1).transform[0]),Number(facing));
   await page.locator('#preview').screenshot({path:`build/smoke-attacks-review/${name}-${facing}.png`});
  }
 }
 await page.locator('[data-move="7"]').click();await ready(page);
 const samples=[];
 for(const tick of [18,21,24,27,34,46,18]){
  await page.evaluate(()=>{attackPaint=[];});await seekMoveFrame(page,tick);
  const paint=await page.evaluate(urls=>attackPaint.filter(p=>Object.values(urls).includes(p.src)),urls);
  samples.push(paint);
 }
 assert.deepEqual(samples.at(-1),samples[0],'Seeking must restore identical body/effect composition');
 assert.deepEqual(errors,[]);
 console.log('PASS Smoke attack art: eight-key 2Hs, backhand effects, shared animated pillar, both facings, saved-frame seeking, hosted plain-JS preview.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
