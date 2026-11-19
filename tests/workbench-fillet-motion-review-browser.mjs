import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir} from 'node:fs/promises';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
const server=await serveWorkshopSite(0,'127.0.0.1','/Fight-guild-/');
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1080}}),errors=[],bad=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400)bad.push(r.url());});
 await page.goto(`http://127.0.0.1:${server.address().port}/Fight-guild-/fillet-motion-review.html`);
 await page.evaluate(()=>filletReview.ready);
 const ids=await page.evaluate(()=>filletReview.pack.moves.map(m=>m.id));
 assert.equal(ids.length,26);assert.equal(new Set(ids).size,26);
 assert.equal(await page.locator('#speed').inputValue(),'1');
 assert.equal(await page.evaluate(()=>filletReview.pack.moves[filletReview.state().selected].id),'2S');
 assert.ok(await page.evaluate(()=>filletReview.pack.moves.every(m=>[...m.before,...m.after].every(k=>typeof filletReview.pack.images[k.file]==='string'))));
 assert.match(await page.locator('#stats').textContent(),/Startup 12f · Active 4f · Recovery 23f · Hitstop 9f/);
 await page.evaluate(()=>filletReview.seek(14));
 assert.match(await page.locator('#readout').textContent(),/Active · Frame 14/);
 assert.equal(await page.evaluate(()=>filletReview.state().playing),false);
 await page.locator('#boxes').check();
 assert.deepEqual(await page.evaluate(()=>filletReview.pack.moves.find(m=>m.id==='2S').timeline[13].hits),[[19,0,116,27]]);
 await mkdir('build/fillet-kit-timing-review',{recursive:true});
 await page.screenshot({path:'build/fillet-kit-timing-review/review-desktop.png',fullPage:true});
 for(const id of ids){
  const index=ids.indexOf(id);await page.locator('#move-select').selectOption(String(index));
  await page.locator('#scenario').selectOption('hit');
  await page.evaluate(()=>{const r=filletReview,m=r.pack.moves[r.state().selected];r.seek(m.contactTimeline.findIndex(t=>t.frame===m.startup)+1);});
  assert.ok((await page.locator('#readout').textContent()).startsWith(id));
 }
 const report=await page.evaluate(()=>filletReview.pack.moves.map(m=>({id:m.id,freeze:m.contactTimeline.filter(k=>k.stopped).length,
  pair:m.contactTimeline.some(k=>k.pairKind&&k.actor.paired),landed:m.timeline.some(k=>k.stage==='Landing / reset'),damage:m.contactTimeline.at(-1).damage})));
 for(const id of ['4P+K','6P+K','5D','236D','214D'])assert.ok(report.find(r=>r.id===id).pair,id+' plays its successful capture');
 assert.equal(report.find(r=>r.id==='2S').freeze,9);
 assert.ok(report.find(r=>r.id==='j.Hs').landed,'Long airborne recovery is interrupted by actual landing');
 assert.ok(report.every(r=>r.damage>0||r.id==='5D'),'On-hit examples must connect');
 await page.locator('#scenario').selectOption('whiff');
 await page.setViewportSize({width:390,height:844});
 await page.locator('#move-select').selectOption(String(ids.indexOf('236S>2S')));await page.locator('#compare').uncheck();await page.locator('#mirror').check();
 await page.evaluate(()=>filletReview.seek(16));
 assert.match(await page.locator('#readout').textContent(),/Frame 16/);
 assert.equal(await page.locator('.old').isVisible(),false);
 assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'No mobile horizontal overflow');
 await page.screenshot({path:'build/fillet-kit-timing-review/review-mobile.png',fullPage:true});
 assert.deepEqual(errors,[]);assert.deepEqual(bad,[]);
 console.log('PASS 26-attack hosted review: actual contacts, five capture tracks, landing, freeze, frame stepping and mobile layout');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
