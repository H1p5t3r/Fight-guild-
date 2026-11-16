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
  await page.goto(url);await page.locator('#field-startup').waitFor();
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
  await page.locator('#frame').evaluate(el=>{el.value='7';el.dispatchEvent(new Event('input',{bubbles:true}));});
  await page.locator('#preview').scrollIntoViewIfNeeded();
  const bounds=await page.locator('#preview').boundingBox();
  const m=(await data(page)).characters[5].moves[0],scale=Math.min((bounds.width-38)/260,(bounds.height-42)/200);
  const originX=(bounds.width-260*scale)/2+90*scale,originY=(bounds.height-200*scale)/2+185*scale;
  const x=bounds.x+originX+m.reach/100*scale,y=bounds.y+originY-(m.bottom+m.height/2)/100*scale;
  await page.mouse.move(x,y);await page.mouse.down();await page.mouse.move(x+20,y,{steps:5});await page.mouse.up();
  assert.ok((await data(page)).characters[5].moves[0].reach>9613,'Dragging a hitbox edge updates game units');
  await page.locator('#undo').click();assert.equal((await data(page)).characters[5].moves[0].reach,9613);
  await page.locator('#tab-art').click();
  const nickname='Knife study <img src=x onerror=alert(1)>';
  await page.locator('#note-label').fill(nickname);
  await page.locator('#note-windup').fill('Shift onto the rear foot; lead with the knife.');
  assert.equal(await page.locator('#move-label').innerText(),nickname);assert.equal(await page.locator('#move-label img').count(),0);
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
  await page.locator('#undo').click();assert.equal((await data(page)).characters[5].moves[0].startup,7);
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
  assert.deepEqual(errors,[]);assert.deepEqual(requests.filter(u=>!u.startsWith('data:')&&u!==url),[],'No external or secondary runtime resources');
  console.log('PASS browser edits, hitbox dragging, JSON round trip, autosave, atomic imports, undo/reset, storage recovery and responsive layouts; no runtime network resources.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
