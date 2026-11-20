import {legacyData} from './legacy-data.mjs';
import {seedBaseline} from './workbench-ui-helpers.mjs';
import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {readFile,mkdir} from 'node:fs/promises';
import {serveWorkshop} from '../scripts/serve-workbench.mjs';
import {ready,seekMoveFrame} from './workbench-ui-helpers.mjs';

const pack=JSON.parse(await readFile('build/workbench-pack.json','utf8'));
const server=await serveWorkshop(0),browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1180}}),errors=[];
 page.on('pageerror',error=>errors.push(error.message));
 await page.addInitScript(()=>{globalThis.WebAssembly=undefined;});
 await seedBaseline(page);await page.goto(`http://127.0.0.1:${server.address().port}/`);await page.locator('#field-startup').waitFor();await ready(page);
 assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),legacyData(pack.defaults),'The legacy fixture opens without inheriting the new kit');
 await page.locator('#fighter').selectOption('5');await page.locator('[data-move="8"]').click();await page.locator('#tab-hurt').click();await ready(page);
 const coordinates=await page.evaluate(()=>moveWorkshop.data().characters[5].moves[8].hurtboxes);
 const boxes=()=>page.evaluate(()=>moveWorkshop.preview().frames[moveWorkshop.cursor().index].boxes[0]);
 assert.equal(await page.locator('#hurt-phase').inputValue(),'active');assert.equal((await boxes()).hurt.length,1);
 assert.equal(await page.locator('#hurt-enabled-head').isChecked(),false);
 await page.locator('#hurt-enabled-legs').uncheck();await ready(page);assert.equal((await boxes()).hurt.length,0);assert.equal((await boxes()).push.length,1);
 await page.locator('#hurt-enabled-head').check();await ready(page);assert.equal((await boxes()).hurt.length,1);
 assert.deepEqual(await page.evaluate(()=>moveWorkshop.data().characters[5].moves[8].hurtboxes),coordinates,'Turning a region off and on retains its edited coordinates');
 await page.locator('#undo').click();await ready(page);assert.equal((await boxes()).hurt.length,0);
 await page.locator('#redo').click();await ready(page);assert.equal((await boxes()).hurt.length,1);
 await page.locator('#hurt-phase').selectOption('recovery');await ready(page);assert.ok((await boxes()).hurt.length>=3);
 await page.locator('#hurt-phase').selectOption('windup');await ready(page);assert.equal((await boxes()).hurt.length,1);
 await page.locator('#hurt-enabled-torsoArms').check();await ready(page);assert.equal((await boxes()).hurt.length,2);
 await page.locator('#hurt-enabled-head').check();await ready(page);assert.equal((await boxes()).hurt.length,3);
 assert.equal(await page.evaluate(()=>moveWorkshop.data().characters[5].moves[8].hurtMaskActive),4,'Phase edits are independent');
 await page.locator('#hurt-enabled-torsoArms').uncheck();await page.locator('#hurt-enabled-head').uncheck();await ready(page);
 await mkdir('build/workshop-hurt-toggle-review',{recursive:true});
 await page.screenshot({path:'build/workshop-hurt-toggle-review/fillet-6p.png',fullPage:false});
 const draft=await page.evaluate(()=>moveWorkshop.data()),pending=page.waitForEvent('download');await page.locator('#export').click();
 const download=await pending;await download.saveAs('build/workshop-hurt-toggle-roundtrip.json');
 assert.deepEqual(JSON.parse(await readFile('build/workshop-hurt-toggle-roundtrip.json','utf8')),draft);
 await page.waitForFunction(()=>document.getElementById('save-status').textContent==='Saved in this browser');
 await page.reload();await page.locator('#hurt-enabled-head').waitFor();await ready(page);assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),draft,'Existing local edits take priority over the bundled batch');
 // The switches also work on inherited sprite geometry, without creating a custom profile.
 await page.locator('#fighter').selectOption('0');await page.locator('[data-move="8"]').click();await ready(page);await seekMoveFrame(page,1);
 assert.equal(await page.locator('#hurt-custom').isChecked(),false);
 await page.locator('#hurt-enabled-head').check();await ready(page);assert.equal((await boxes()).hurt.length,2);
 assert.deepEqual(await page.evaluate(()=>moveWorkshop.data().characters[0].moves[8].hurtboxes),{});
 assert.deepEqual(errors,[]);console.log('PASS working-batch startup, per-region hurtbox toggles, phase isolation, coordinates, pushboxes, undo/redo, JSON and existing drafts');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
