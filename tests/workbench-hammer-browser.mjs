import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,writeFile} from 'node:fs/promises';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {ready} from './workbench-ui-helpers.mjs';
const server=await serveWorkshopSite(0,'127.0.0.1','/Fight-guild-/');
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1000},reducedMotion:'reduce'}),errors=[],bad=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400)bad.push(r.url());});
 await page.addInitScript(()=>{globalThis.WebAssembly=undefined;});
 const base=`http://127.0.0.1:${server.address().port}/Fight-guild-/`;
 await page.goto(base+'hammer-motion-review.html');await page.evaluate(()=>hammerReview.ready);
 const report=await page.evaluate(()=>hammerReview.pack.moves.map(m=>({slot:m.slot,id:m.id,name:m.name,damage:Math.max(...m.scenarios.hit.map(f=>f.damage)),bonus:m.scenarios.hit.some(f=>f.driveBonus===4),warnings:m.warnings??[],steps:m.steps??[]})));
 await mkdir('build/hammer-kit-review',{recursive:true});await writeFile('build/hammer-kit-review/report.json',JSON.stringify(report,null,2)+'\n');
 assert.equal(report.filter(m=>m.slot>=0).length,23);
 for(const m of report.filter(m=>m.slot>=0&&m.slot!==13))assert.ok(m.damage>0,m.id+' contact example must connect');
 assert.ok(report.find(m=>m.slot===13).bonus);
 for(const route of report.filter(m=>m.slot<0)){assert.deepEqual(route.warnings,[]);assert.ok(route.bonus);assert.ok(route.steps.every(s=>s.start!==undefined));}
 for(const [i,m]of report.entries()){
  await page.locator('#move-select').selectOption(String(i));
  for(const scenario of m.slot<0?[]:['hit','block','whiff']){
   await page.locator('#scenario').selectOption(scenario);
   await page.evaluate(()=>{const r=hammerReview,m=r.pack.moves[r.state().selected];r.seek(Math.min(20,m.scenarios[document.getElementById('scenario').value].length-1));});
  }
 }
 await page.locator('#move-select').selectOption(String(report.findIndex(m=>m.slot===2)));await page.locator('#scenario').selectOption('hit');
 await page.evaluate(()=>{const r=hammerReview,m=r.pack.moves[r.state().selected];r.seek(m.scenarios.hit.findIndex(f=>f.hitstop>0));});
 await page.screenshot({path:'build/hammer-kit-review/review-desktop.png',fullPage:true});
 await page.locator('#boxes').check();await page.screenshot({path:'build/hammer-kit-review/hitbox-inspection.png',fullPage:true});
 await page.setViewportSize({width:390,height:844});await page.locator('#mirror').check();
 assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));
 await page.screenshot({path:'build/hammer-kit-review/review-mobile.png',fullPage:true});
 await page.goto(base);await ready(page);await page.locator('#fighter').selectOption('1');await page.locator('#choose-move').click();await page.locator('[data-move="13"]').click();await page.locator('#section-picker').selectOption('mechanics');await ready(page);
 assert.match(await page.locator('.drive-overview').innerText(),/Break Step/);
 assert.equal(await page.locator('#stat-block').innerText(),'—');
 for(const field of ['driveDistance','drivePlus','driveNeutralFrames'])assert.ok(await page.locator('#field-'+field).isVisible(),field+' editable on mobile');
 await page.locator('[data-drive-test="followup"]').click();await ready(page);
 assert.ok(await page.evaluate(()=>moveWorkshop.preview().frames.some(f=>f.state.players[0].driveBonus===4)));
 assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));
 await page.screenshot({path:'build/hammer-kit-review/editor-mobile.png',fullPage:true});
 await page.locator('#help').click();assert.equal(await page.locator('a[href="hammer-motion-review.html"]').count(),1);
 assert.deepEqual(errors,[]);assert.deepEqual(bad,[]);
 console.log('PASS Hammer: all 23 contact clips, Drive follow-up, mirrored/mobile playback, editable controls, hosted subpath, and zero browser/resource errors.');
}finally{await browser.close();await new Promise(r=>server.close(r));}
