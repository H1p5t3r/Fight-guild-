import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,readFile} from 'node:fs/promises';
import {serveWorkshop} from '../scripts/serve-workbench.mjs';
import {ready} from './workbench-ui-helpers.mjs';
const server=await serveWorkshop(0),browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1080}}),errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.addInitScript(()=>{globalThis.WebAssembly=undefined;});
 await page.goto(`http://127.0.0.1:${server.address().port}/`);await page.locator('#field-startup').waitFor();await ready(page);
 await page.locator('#fighter').selectOption('3');await page.locator('[data-move="40"]').click();await page.locator('#tab-mechanics').click();await ready(page);
 assert.equal(await page.locator('#field-stanceRequired').inputValue(),'2');assert.equal(await page.locator('#field-grabFrames').inputValue(),'24');
 const record=await page.evaluate(()=>moveWorkshop.preview());assert.equal(record.contacts.length,1);
 const i=record.frames.findIndex(f=>f.state.players[0].poseIndex===30&&f.state.players[0].posePhase===4);assert.ok(i>=0);
 await page.locator('#frame').evaluate((n,i)=>{n.value=String(i);n.dispatchEvent(new Event('input',{bubbles:true}));},i);
 await mkdir('build/tapper-review',{recursive:true});await page.screenshot({path:'build/tapper-review/tackle-editor.png'});
 await page.locator('#field-grabFrames').fill('30');await page.locator('#field-grabFrames').blur();await ready(page);
 const pending=page.waitForEvent('download');await page.locator('#export').click();await (await pending).saveAs('build/tapper-review/editor-roundtrip.json');
 assert.equal(JSON.parse(await readFile('build/tapper-review/editor-roundtrip.json','utf8')).characters[3].moves[40].grabFrames,30);
 await page.locator('#tab-movement').click();await page.locator('#movement-action').selectOption('rolling');await ready(page);
 assert.ok((await page.evaluate(()=>moveWorkshop.preview())).frames.every(f=>f.state.players[0].posePhase===8));
 await page.screenshot({path:'build/tapper-review/rolling-idle.png'});
 await page.locator('#movement-action').selectOption('forward');await ready(page);const step=await page.evaluate(()=>moveWorkshop.preview());
 const tick=step.frames.findIndex(f=>f.state.players[0].posePhase===7&&f.state.players[0].poseIndex===3);assert.ok(tick>=0);
 await page.locator('#frame').evaluate((n,i)=>{n.value=String(i);n.dispatchEvent(new Event('input',{bubbles:true}));},tick);
 await page.screenshot({path:'build/tapper-review/step-dash.png'});
 assert.deepEqual(errors,[]);console.log('PASS Tapper editor: no WebAssembly, real capture/finish, stance idle, step dash, editable fields and JSON roundtrip.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
