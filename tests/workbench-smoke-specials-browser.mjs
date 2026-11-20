import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {ready,seekMoveFrame} from './workbench-ui-helpers.mjs';
const server=await serveWorkshopSite(0),browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage(),errors=[],missing=[];
 page.on('pageerror',e=>errors.push(e.message));page.on('response',r=>{if(r.status()>=400)missing.push(r.url());});
 await page.addInitScript(()=>{globalThis.WebAssembly=undefined;});
 const url=`http://127.0.0.1:${server.address().port}/`;
 await page.goto(url+'smoke-motion-review.html');await page.evaluate(()=>smokeReview.ready);
 for(const width of [1280,390]){
  await page.setViewportSize({width,height:900});
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'Review must fit a phone');
  await page.locator('#move').selectOption('1');await page.locator('#scenario').selectOption('whiff');
  const frame=await page.evaluate(()=>{const m=smokeReview.pack.moves[1];return m.scenarios.whiff.findIndex(f=>f.frame===m.startup+m.active+2);});
  await page.locator('#seek').fill(String(frame));
  assert.equal(await page.locator('#play').innerText(),'Play');
  assert.match(await page.locator('#stage').innerText(),/Follow-through/);
  const normal=await page.locator('#after').evaluate(c=>c.toDataURL());
  await page.locator('#mirror').check();const mirrored=await page.locator('#after').evaluate(c=>c.toDataURL());assert.notEqual(mirrored,normal);
  await page.locator('#mirror').uncheck();assert.equal(await page.locator('#after').evaluate(c=>c.toDataURL()),normal,'Seeking/mirroring must restore the same drawing');
  await page.locator('#back').click();assert.equal(Number(await page.locator('#seek').inputValue()),frame-1);
 }
 await page.goto(url);await ready(page);await page.locator('#fighter').selectOption('2');await page.locator('#choose-move').click();await page.locator('[data-move="15"]').click();await ready(page);
 await seekMoveFrame(page,26);
 const pose=await page.evaluate(()=>{const record=moveWorkshop.preview(),frame=record.frames.find(f=>f.selectedFrame===26),p=frame.state.players[0];return FIGHT_WORKSHOP_DATA.art[2].attack_animation.frames[p.poseIndex];});
 assert.match(pose.file,/smoke-specials-v3\/backhand-recovery/);assert.match(pose.motion_cue,/Withdraw/);
 assert.deepEqual(errors,[]);assert.deepEqual(missing,[]);
 console.log('PASS Smoke review: mobile/desktop, plain JS, frame controls, mirroring and new recovery inside the editor.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
