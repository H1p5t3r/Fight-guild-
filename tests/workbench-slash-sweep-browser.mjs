import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,readFile} from 'node:fs/promises';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {ready,selectSection} from './workbench-ui-helpers.mjs';

const server=await serveWorkshopSite(0);
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
const dir='build/slash-sweep-review';await mkdir(dir,{recursive:true});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 await page.addInitScript(()=>{globalThis.WebAssembly=undefined;});
 await page.goto(`http://127.0.0.1:${server.address().port}/`);await ready(page);
 const initial=await page.evaluate(()=>moveWorkshop.data());
 const testSpacing=async index=>{
  await page.locator(`[data-slash-test="${index}"]`).click();await ready(page);
  const record=await page.evaluate(()=>moveWorkshop.preview());
  assert.equal(record.executed,true,`S selected ${index}`);assert.deepEqual(record.warnings,[]);
  assert.ok(record.frames.some(f=>f.state.players[0].move===index));
  assert.equal(await page.evaluate(()=>moveWorkshop.selection().slot),index);
 };
 for(let fighter=0;fighter<6;fighter++){
  await page.locator('#fighter').selectOption(String(fighter));
  await page.locator('[data-move="2"]').click();await ready(page);
  assert.match(await page.locator('[data-move="2"]').innerText(),/f\.S/);
  assert.match(await page.locator('[data-move="32"]').innerText(),/c\.S/);
  assert.equal(await page.locator('#slash-warning').isHidden(),true);
  await testSpacing(32);await testSpacing(2);
 }
 assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),initial,'Spacing tests do not edit any tuning or art briefs');
 // Change the threshold through the real editor, then test its new boundary.
 await selectSection(page,'routes');
 await page.locator('#setting-search').fill('proximityRange');
 await page.locator('[data-setting-result="proximityRange"]').click();
 await page.locator('#field-proximityRange').fill('90.25');await page.locator('#field-proximityRange').blur();await ready(page);
 assert.match(await page.locator('#slash-description').innerText(),/90\.25 px/);
 await testSpacing(32);await testSpacing(2);
 assert.equal(await page.evaluate(()=>moveWorkshop.data().characters[5].moves[2].proximityRange),9025);
 await page.locator('[data-slash-edit="32"]').click();await page.locator('#attack-enabled').uncheck();await ready(page);
 assert.equal(await page.locator('#slash-warning').isVisible(),true);
 await page.locator('#attack-enabled').check();await ready(page);await testSpacing(32);
 // Mobile navigation, timing card and sequence share the same canvas.
 await page.setViewportSize({width:390,height:844});await selectSection(page,'timing');
 await page.locator('.slash-pair').scrollIntoViewIfNeeded();
 await page.screenshot({path:dir+'/phone-slash.png'});
 for(const size of [{width:320,height:640},{width:430,height:932},{width:1440,height:1000}]){
  await page.setViewportSize(size);await page.evaluate(()=>new Promise(requestAnimationFrame));
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
 }
 await page.locator('#test-gap').fill('0');await page.locator('#test-gap').dispatchEvent('change');await ready(page);
 await selectSection(page,'sequence');
 for(const move of ['32','2','3']){
  await page.locator('#sequence-add-move').selectOption(move);await page.locator('#sequence-add').click();await ready(page);
 }
 assert.equal(await page.locator('#sequence-move-1 option:checked').innerText(),'f.S');
 const sequence=await page.evaluate(()=>moveWorkshop.preview());
 assert.deepEqual(sequence.warnings,[]);assert.ok(sequence.steps.every(s=>s.start!==undefined));
 assert.equal(sequence.steps[1].route,'cancel / buffered link');
 await page.locator('[data-sequence-seek="1"]').click();
 await page.screenshot({path:dir+'/desktop-sequence.png'});
 // The new universal sweep still reports real hard knockdown in the preview.
 await page.locator('[data-move="6"]').click();await selectSection(page,'timing');await ready(page);
 const sweep=await page.evaluate(()=>moveWorkshop.preview());
 assert.ok(sweep.frames.some(f=>f.state.players[1].knockdown===2));
 const edited=await page.evaluate(()=>moveWorkshop.data());
 assert.equal(edited.characters[5].moves[2].id,'5S');
 assert.deepEqual(edited._moveWorkshop.notes,initial._moveWorkshop.notes);
 await page.waitForFunction(()=>document.getElementById('save-status').textContent==='Saved in this browser');
 const downloadEvent=page.waitForEvent('download');await page.locator('#export').click();
 const download=await downloadEvent;await download.saveAs(dir+'/roundtrip.json');
 assert.deepEqual(JSON.parse(await readFile(dir+'/roundtrip.json','utf8')),edited);
 await page.reload();await ready(page);assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),edited);
 assert.deepEqual(errors,[]);
 console.log('PASS close/far Slash labels, editable fractional threshold, actual spacing inputs, disabled warning, mobile layout, c.S → f.S sequence, sweep knockdown and JSON roundtrip.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
