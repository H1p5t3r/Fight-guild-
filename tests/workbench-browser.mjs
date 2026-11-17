import {seedBaseline,ready,seekMoveFrame,dragHandle} from './workbench-ui-helpers.mjs';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {readFile,mkdir} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {serveWorkshop} from '../scripts/serve-workbench.mjs';

const server=await serveWorkshop(0),url=`http://127.0.0.1:${server.address().port}/`;
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
const errors=[],requests=[],STORAGE='fight-guild.move-workshop.v1';
const data=page=>page.evaluate(()=>moveWorkshop.data());
const waitSaved=page=>page.waitForFunction(()=>document.getElementById('save-status').textContent==='Saved in this browser');
const upload=async(page,value)=>page.locator('#import-file').setInputFiles({name:'moves.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(value))});
const screenshotDir='build/workshop-review';await mkdir(screenshotDir,{recursive:true});
try {
  const context=await browser.newContext({viewport:{width:1440,height:1000}}),page=await context.newPage();
  page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>requests.push(r.url()));
  await seedBaseline(page);await page.goto(url);await page.locator('#field-startup').waitFor();
  await page.evaluate(()=>document.fonts.ready);
  const initial=await data(page);assert.equal(initial.characters.length,6);
  assert.equal(await page.locator('#fighter').inputValue(),'5');
  await page.screenshot({path:`${screenshotDir}/desktop.png`,fullPage:true});
  // Incomplete/invalid numeric edits cannot silently disappear on navigation.
  await page.locator('#field-startup').fill('4');
  assert.equal(await page.locator('#export').isDisabled(),true);
  await page.locator('[data-move="1"]').click();assert.equal(await page.locator('#move-title').innerText(),'5P');
  assert.equal(await page.locator('#field-startup').getAttribute('aria-invalid'),'true');
  await page.locator('#field-startup').fill('7');await page.locator('#field-damage').fill('44');
  await page.locator('#tab-hit').click();await page.locator('#field-reach').fill('96.13');
  assert.equal((await data(page)).characters[5].moves[0].reach,9613);
  await seekMoveFrame(page,7);
  await dragHandle(page,'base','reach',20);
  assert.ok((await data(page)).characters[5].moves[0].reach>9613,'Dragging a hitbox edge updates game units');
  await page.locator('#undo').click();assert.equal((await data(page)).characters[5].moves[0].reach,9613);
  await page.locator('#tab-hurt').click();assert.equal(await page.locator('#field-hurt-width').isDisabled(),true);
  await page.locator('#hurt-custom').check();await page.locator('#hurt-region').selectOption('torsoArms');
  for(const [key,value]of [['left','-20'],['bottom','60'],['width','60'],['height','50']])await page.locator('#field-hurt-'+key).fill(value);
  await page.locator('#field-hurt-height').fill('0');assert.equal(await page.locator('#export').isDisabled(),true);
  await page.locator('#hurt-phase').selectOption('windup');assert.equal(await page.locator('#hurt-phase').inputValue(),'active');
  await page.locator('#field-hurt-height').fill('50');await page.locator('#hurt-extension').uncheck();
  assert.equal(Object.keys((await data(page)).characters[5].moves[0].hurtboxes.active).length,3);
  await page.locator('#hurt-extension').check();assert.equal(Object.keys((await data(page)).characters[5].moves[0].hurtboxes.active).length,4);
  await page.locator('#hurt-extension').uncheck();await page.locator('#hurt-region').selectOption('torsoArms');
  await dragHandle(page,'hurt',2,15);
  assert.ok((await data(page)).characters[5].moves[0].hurtboxes.active.torsoArms[2]>4000);
  await page.locator('#undo').click();assert.deepEqual((await data(page)).characters[5].moves[0].hurtboxes.active.torsoArms,[-2000,6000,4000,11000]);
  await page.locator('#hurt-phase').selectOption('windup');assert.equal(await page.locator('#hurt-custom').isChecked(),false);await page.locator('#hurt-custom').check();
  await page.locator('#hurt-region').selectOption('head');await page.locator('#field-hurt-width').fill('25');
  await page.locator('#hurt-phase').selectOption('recovery');await page.locator('#hurt-custom').check();await page.locator('#field-hurt-height').fill('20');
  const hurtProfiles=(await data(page)).characters[5].moves[0].hurtboxes;assert.deepEqual(hurtProfiles.active.torsoArms,[-2000,6000,4000,11000]);
  await page.locator('[data-move="4"]').click();assert.equal(await page.locator('#hurt-custom').isChecked(),false);
  await page.locator('[data-move="0"]').click();assert.equal(await page.locator('#hurt-custom').isChecked(),true);
  await page.screenshot({path:`${screenshotDir}/hurtboxes.png`,fullPage:true});
  await page.locator('#tab-art').click();
  const nickname='Knife study <img src=x onerror=alert(1)>';
  await page.locator('#note-label').fill(nickname);
  await page.locator('#note-windup').fill('Shift onto the rear foot; lead with the knife.');
  assert.equal(await page.locator('#move-label').innerText(),nickname);assert.equal(await page.locator('#move-label img').count(),0);
  // Reference photos are decoded/resized locally and embedded in the move JSON.
  await page.locator('#reference-file').setInputFiles('art/characters/fillet.png');
  await page.locator('.reference-card').waitFor();
  await page.locator('[data-reference-phase]').selectOption('windup');
  await page.locator('[data-reference-caption]').fill('Borrow the planted rear foot and torso twist.');
  const photo=(await data(page))._moveWorkshop.notes['Fillet/5P'].references[0];assert.match(photo.src,/^data:image\/webp;base64,/);assert.equal(photo.phase,'windup');
  await page.locator('.reference-thumbnail').click();assert.equal(await page.locator('#reference-dialog').isVisible(),true);
  assert.equal(await page.locator('#reference-photo').evaluate(img=>img.naturalWidth<=1200&&img.naturalHeight<=1200&&img.naturalWidth>0),true);
  await page.keyboard.press('Escape');await waitSaved(page);
  await page.locator('.pose-references').screenshot({path:`${screenshotDir}/pose-reference.png`});
  await page.locator('#reference-file').setInputFiles(['art/characters/fillet.png','art/characters/shark.png']);
  await page.waitForFunction(()=>document.querySelectorAll('.reference-card').length===3);
  assert.equal(await page.locator('#add-reference').isDisabled(),true);
  await page.locator('#reference-file').setInputFiles('art/characters/fillet.png');
  await page.waitForFunction(()=>document.getElementById('reference-status').textContent.includes('up to three'));
  assert.equal(await page.locator('.reference-card').count(),3);
  await page.locator('.reference-remove').last().click();await page.locator('.reference-remove').last().click();
  assert.equal(await page.locator('.reference-card').count(),1);
  await page.locator('.reference-remove').click();assert.equal(await page.locator('.reference-card').count(),0);
  await page.locator('#undo').click();assert.equal((await data(page))._moveWorkshop.notes['Fillet/5P'].references[0].src,photo.src);
  const beforeBadPhoto=await data(page);
  await page.locator('#reference-file').setInputFiles({name:'bad.png',mimeType:'image/png',buffer:Buffer.from('not an image')});
  await page.waitForFunction(()=>document.getElementById('reference-status').textContent.includes('could not be read'));
  assert.deepEqual(await data(page),beforeBadPhoto);
  await page.reload();await page.locator('.reference-card').waitFor();assert.equal((await data(page))._moveWorkshop.notes['Fillet/5P'].references[0].src,photo.src);
  await page.locator('#fighter').selectOption('4');await page.locator('[data-move="28"]').click();
  await page.locator('#tab-hit').click();await page.locator('#field-airLaunch').fill('13');
  await page.locator('#tab-routes').click();await page.locator('#field-normalRoutes-unified').uncheck();await page.locator('#field-normalRoutes-0').check();
  await waitSaved(page);const edited=await data(page);
  assert.equal(edited.characters[4].moves[28].normalRoutes,1);assert.deepEqual(edited.characters.slice(0,4),initial.characters.slice(0,4));
  for(const key of Object.keys(initial).filter(k=>k.endsWith('Rules')))assert.deepEqual(edited[key],initial[key]);
  const downloadPromise=page.waitForEvent('download');await page.locator('#export').click();const download=await downloadPromise;
  await download.saveAs('build/workshop-browser-roundtrip.json');
  assert.deepEqual(JSON.parse(await readFile('build/workshop-browser-roundtrip.json','utf8')),edited);
  await page.reload();await page.locator('#move-title').waitFor();assert.deepEqual(await data(page),edited);
  assert.equal(await page.locator('#move-title').innerText(),'214S');
  // A late invalid field must not overwrite any part of the current document.
  const invalid=structuredClone(initial);invalid.characters[5].moves[31].startup=0;
  await upload(page,invalid);await page.waitForFunction(()=>document.getElementById('toast').textContent.startsWith('Import stopped'));
  assert.deepEqual(await data(page),edited);
  await upload(page,initial);await page.waitForFunction(()=>document.getElementById('toast').textContent.startsWith('Move data imported'));
  assert.deepEqual(await data(page),initial);await page.locator('#undo').click();assert.deepEqual(await data(page),edited);
  // Reset is reversible, and art notes are kept.
  await page.locator('#fighter').selectOption('5');await page.locator('#reset').click();
  assert.equal((await data(page)).characters[5].moves[0].startup,5);assert.equal((await data(page))._moveWorkshop.notes['Fillet/5P'].label,nickname);
  assert.equal((await data(page))._moveWorkshop.notes['Fillet/5P'].references[0].src,photo.src);
  assert.deepEqual((await data(page)).characters[5].moves[0].hurtboxes,{});
  await page.locator('#undo').click();assert.equal((await data(page)).characters[5].moves[0].startup,7);
  assert.deepEqual((await data(page)).characters[5].moves[0].hurtboxes,hurtProfiles);
  // Search/filter controls and keyboard tab navigation remain usable.
  await page.locator('#search').fill('236S');assert.equal(await page.locator('.move-row').count(),3);await page.locator('#search').fill('');
  await page.locator('#tab-hit').click();await page.keyboard.press('ArrowRight');assert.equal(await page.locator('#tab-routes').getAttribute('aria-selected'),'true');
  for(const c of ['0','1','2','3','4','5']){
    await page.locator('#fighter').selectOption(c);await page.locator('#tab-hit').click();
    assert.equal(await page.locator('#preview-empty').isVisible(),false);
  }
  await page.locator('[data-move="25"]').click();await page.screenshot({path:`${screenshotDir}/fillet-spiral.png`,fullPage:true});
  await page.locator('#fighter').selectOption('4');await page.locator('[data-move="28"]').click();await page.screenshot({path:`${screenshotDir}/shark-hook.png`,fullPage:true});
  for(const [width,height,label] of [[1280,800,'laptop'],[390,844,'mobile']]){
    await page.setViewportSize({width,height});
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,`${label} horizontal overflow`);
    await page.screenshot({path:`${screenshotDir}/${label}.png`,fullPage:true});
  }
  await page.locator('#fighter').selectOption('5');await page.locator('#tab-art').click();
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,'Photo-reference mobile overflow');
  await page.screenshot({path:`${screenshotDir}/pose-reference-mobile.png`,fullPage:true});
  await page.locator('#tab-hurt').click();assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,'Hurtbox editor mobile overflow');
  await page.screenshot({path:`${screenshotDir}/hurtboxes-mobile.png`,fullPage:true});
  await page.locator('#help').click();assert.equal(await page.locator('#help-dialog').isVisible(),true);await page.keyboard.press('Escape');
  // Storage restrictions still allow downloads, with a clear unsaved warning.
  const denied=await browser.newContext();await denied.addInitScript(()=>{Storage.prototype.setItem=function(){throw new DOMException('Full','QuotaExceededError');};});
  const noStorage=await denied.newPage();noStorage.on('pageerror',e=>errors.push(e.message));await noStorage.goto(url);
  await noStorage.locator('#field-damage').fill('65');await noStorage.locator('#storage-warning').waitFor({state:'visible'});
  assert.equal(await noStorage.locator('#export').isEnabled(),true);
  const backupEvent=noStorage.waitForEvent('download');await noStorage.locator('#export').click();const backup=await backupEvent;
  await backup.saveAs('build/workshop-storage-backup.json');assert.equal(JSON.parse(await readFile('build/workshop-storage-backup.json','utf8')).characters[5].moves[0].damage,65);
  await denied.close();
  // Corrupt existing drafts must remain recoverable rather than being autosaved over.
  const recovery=await browser.newContext();await recovery.addInitScript(key=>localStorage.setItem(key,'broken-but-recoverable'),STORAGE);
  const recoveryPage=await recovery.newPage();await recoveryPage.goto(url);await recoveryPage.locator('#storage-warning').waitFor({state:'visible'});
  assert.equal(await recoveryPage.locator('#export').isDisabled(),true);
  await recoveryPage.locator('[data-move="1"]').click();assert.equal(await recoveryPage.evaluate(key=>localStorage.getItem(key),STORAGE),'broken-but-recoverable');
  await recoveryPage.getByRole('button',{name:'Start a new draft',exact:true}).click();assert.equal(await recoveryPage.locator('#export').isEnabled(),true);
  await recovery.close();await context.close();
  assert.deepEqual(errors,[]);assert.deepEqual(requests.filter(u=>!u.startsWith('data:')&&!u.startsWith('blob:')&&u!==url),[],'No external runtime resources');
  console.log('PASS browser edits, hitbox dragging, embedded pose photos, JSON round trip, autosave, atomic imports, undo/reset, storage recovery and responsive layouts; no external runtime resources.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
