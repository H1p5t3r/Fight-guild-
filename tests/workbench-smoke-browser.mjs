import {seedBaseline} from './workbench-ui-helpers.mjs';
import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir} from 'node:fs/promises';
import {serveWorkshop} from '../scripts/serve-workbench.mjs';
import {ready,seekMoveFrame} from './workbench-ui-helpers.mjs';
const server=await serveWorkshop(0);
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1080}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>{globalThis.WebAssembly=undefined;});
 await seedBaseline(page);await page.goto(`http://127.0.0.1:${server.address().port}/`);await ready(page);
 await mkdir('build/smoke-review',{recursive:true});
 await page.locator('#fighter').selectOption('2');await page.locator('#tab-hit').click();
 await page.locator('#test-gap').fill('100');await page.locator('#test-gap').blur();
 for(const [slot,start,name] of [[0,6,'vapor-check'],[7,18,'backdraft'],[2,12,'fivefold'],[21,16,'ember']]){
  await page.locator(`[data-move="${slot}"]`).click();await ready(page);await seekMoveFrame(page,start);
  await page.screenshot({path:`build/smoke-review/${name}-editor.png`});
 }
 assert.equal(await page.evaluate(()=>!!FIGHT_WORKSHOP_DATA.images['smoke-v1/projectile.png']),true);
 assert.equal(await page.evaluate(async()=>{const img=new Image();img.src=FIGHT_WORKSHOP_DATA.images['smoke-v1/projectile.png'];await img.decode();return img.naturalWidth>0;}),true);
 await page.locator('[data-move="11"]').click();await page.locator('#tab-stance').click();await ready(page);
 assert.equal(await page.locator('#field-actionType').inputValue(),'5');assert.equal(await page.locator('#field-holdFollow').inputValue(),'43');
 await page.locator('#field-holdFrame').fill('40');await page.locator('#field-holdFrame').blur();await ready(page);
 await page.locator('[data-move="43"]').click();assert.match(await page.locator('#actual-input').innerText(),/6\[HS\]/i);
 await page.locator('#fighter').selectOption('3');await page.locator('[data-move="0"]').click();await page.locator('#tab-hit').click();await ready(page);await seekMoveFrame(page,5);
 await page.screenshot({path:'build/smoke-review/tapper-hitboxes-editor.png'});
 assert.deepEqual(errors,[]);
 console.log('PASS Smoke/Tapper editor: decoded generated art, traced boxes, charge controls, source notation and offline plain-JS preview.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
