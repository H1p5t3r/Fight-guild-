import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir} from 'node:fs/promises';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {ready,selectSection} from './workbench-ui-helpers.mjs';
const server=await serveWorkshopSite(0),browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
await mkdir('build/combo-decay',{recursive:true});
try{
 for(const mobile of [false,true]){
  const context=await browser.newContext({viewport:mobile?{width:390,height:844}:{width:1440,height:1000},isMobile:mobile,hasTouch:mobile}),page=await context.newPage(),errors=[];
  page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>{globalThis.WebAssembly=undefined;});
  await page.goto(`http://127.0.0.1:${server.address().port}/`);await ready(page);
  assert.equal(await page.evaluate(()=>moveWorkshop.data().comboRules.comboPhysics),1);
  await page.locator('#setting-search').fill('launch reduction');
  await page.locator('[data-setting-result="rule-decayLaunchStep"]').click();
  assert.ok(await page.locator('#combo-rules').evaluate(n=>n.open));
  await page.locator('#field-rule-decayLaunchStep').fill('3');await page.locator('#field-rule-decayLaunchStep').blur();await ready(page);
  assert.equal(await page.evaluate(()=>moveWorkshop.data().comboRules.decayLaunchStep),3);
  await page.locator('#field-rule-decayLaunchStep').fill('22');await page.locator('#field-rule-decayLaunchStep').blur();
  assert.ok(await page.locator('#export').isDisabled());assert.equal(await page.evaluate(()=>moveWorkshop.data().comboRules.decayLaunchStep),3);
  await page.locator('#field-rule-decayLaunchStep').fill('2');await page.locator('#field-rule-decayLaunchStep').blur();await ready(page);
  await page.locator('#field-rule-launchCarry').fill('33');await page.locator('#field-rule-launchCarry').blur();await ready(page);
  await page.screenshot({path:`build/combo-decay/editor-${mobile?'mobile':'desktop'}.png`});
  assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1));
  await selectSection(page,'hit');await ready(page);
  await page.locator('#field-groundHitSpeed').fill('2.75');await page.locator('#field-groundHitSpeed').blur();await ready(page);
  assert.equal(await page.evaluate(()=>moveWorkshop.data().characters[5].moves[0].groundHitSpeed),275);
  await page.waitForTimeout(350);await page.reload();await ready(page);
  assert.equal(await page.evaluate(()=>moveWorkshop.data().comboRules.launchCarry),33);
  assert.equal(await page.evaluate(()=>moveWorkshop.data().characters[5].moves[0].groundHitSpeed),275);
  assert.deepEqual(errors,[]);await context.close();
 }
 console.log('Combo editor: desktop/mobile edits, search, invalid-value guard, plain-JS preview and saved drafts passed');
}finally{await browser.close();server.close();}
