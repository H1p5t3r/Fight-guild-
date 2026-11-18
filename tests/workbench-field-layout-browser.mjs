import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,readFile} from 'node:fs/promises';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {seedBaseline,ready,selectSection,seekMoveFrame} from './workbench-ui-helpers.mjs';
const server=await serveWorkshopSite(0),browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
const dir='build/field-layout-review/verified';await mkdir(dir,{recursive:true});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));await seedBaseline(page);
 await page.goto(`http://127.0.0.1:${server.address().port}/`);await ready(page);
 const data=await page.evaluate(()=>moveWorkshop.data());
 data._moveWorkshop={version:1,notes:{'Fillet/5P':{active:'Keep this pose and photo.',references:[{id:'layout-reference',name:'pose.png',phase:'active',caption:'Keep the shoulder angle.',width:1,height:1,src:'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII='}]}},sequences:{Fillet:[{move:0,delay:0},{move:1,delay:6}]}};
 await page.locator('#import-file').setInputFiles({name:'layout-draft.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(data))});await ready(page);
 const initial=await page.evaluate(()=>moveWorkshop.data());
 const find=async(key,query=key)=>{await page.locator('#setting-search').fill(query);await page.locator(`[data-setting-result="${key}"]`).click();};
 const open=async id=>{const p=page.locator(`[data-panel="${id}"]`);if(!await p.evaluate(n=>n.open))await p.locator('summary').click();};
 const visible=async key=>assert.equal(await page.locator('#field-'+key).isVisible(),true,key+' visible');
 const hidden=async key=>assert.equal(await page.locator('#field-'+key).isVisible(),false,key+' hidden');
 // A manual disclosure and field help survive form refresh, navigation and reload.
 await page.locator('[data-panel="counter"]>summary').click();
 await page.locator('[data-setting="startup"] .field-help').click();
 await seekMoveFrame(page,2);assert.equal(await page.locator('[data-panel="counter"]').evaluate(n=>n.open),false);
 await selectSection(page,'hit');await selectSection(page,'timing');
 assert.equal(await page.locator('[data-panel="counter"]').evaluate(n=>n.open),false);
 assert.equal(await page.locator('#hint-startup').isVisible(),true);
 await page.waitForFunction(()=>document.getElementById('save-status').textContent==='Saved in this browser');await page.reload();await ready(page);
 assert.equal(await page.locator('[data-panel="counter"]').evaluate(n=>n.open),false);
 assert.equal(await page.locator('#hint-startup').isVisible(),true);
 // Search locates optional settings even while their group is closed/inactive.
 for(const key of ['armorHits','hurtWindowMask','proximityRange','artPose','stanceRequired']){
  await find(key);const selector=key==='hurtWindowMask'?'#field-hurtWindowMask-0':'#field-'+key;
  assert.equal(await page.locator(selector).isVisible(),true,key);
 }
 await find('movement-airDashPauseFrames','air forward pause');await visible('movement-airDashPauseFrames');
 await page.locator('#field-view').selectOption('all');await page.locator('#field-view').selectOption('relevant');
 assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),initial,'Search, help, disclosure and visibility never edit tuning, notes, photos or queues');
 // Fighter-specific Drive controls; each input exists only once even in All fields.
 await page.locator('#fighter').selectOption('4');await page.locator('[data-move="13"]').click();await selectSection(page,'mechanics');await ready(page);
 await visible('tetherSpeed');await hidden('bleedInitial');await hidden('variantDamage');await visible('variantStartup');
 assert.match(await page.locator('.drive-overview').innerText(),/Tether → pull/);
 await page.locator('[data-drive-test="followup"]').click();await ready(page);
 assert.equal(await page.locator('#test-mechanic').inputValue(),'followup');assert.ok((await page.evaluate(()=>moveWorkshop.preview())).frames.some(f=>f.state.players[1].tetherUsed));
 await page.screenshot({path:dir+'/shark-drive.png',fullPage:true});
 await page.locator('#field-view').selectOption('all');await visible('bleedInitial');
 assert.match(await page.locator('[data-setting="bleedInitial"] .inactive-reason').innerText(),/Bleed/);
 const ids=await page.locator('#form [id]').evaluateAll(nodes=>nodes.map(n=>n.id));assert.equal(new Set(ids).size,ids.length,'No duplicated controls');
 await page.locator('#field-view').selectOption('relevant');
 await open('drive-type');await page.locator('#field-mechanic').selectOption('2');await visible('bleedInitial');await hidden('tetherSpeed');
 await page.locator('#field-mechanic').selectOption('1');await visible('tetherSpeed');await hidden('bleedInitial');
 await page.locator('#field-tetherSpeed').fill('99999');await page.locator('#field-mechanic').selectOption('2');
 assert.equal(await page.locator('#field-mechanic').inputValue(),'1');assert.equal(await page.locator('#field-tetherSpeed').inputValue(),'99999');
 await page.locator('#field-tetherSpeed').fill(String(initial.characters[4].moves[13].tetherSpeed/100));
 assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),initial,'Changing the mechanic and restoring it retains every inactive value');
 await page.locator('#fighter').selectOption('5');await page.locator('[data-drive-move="13"]').click();await ready(page);await visible('bleedInitial');await visible('variantDamage');await hidden('tetherSpeed');
 await page.locator('#fighter').selectOption('3');await ready(page);
 assert.match(await page.locator('.drive-overview').innerText(),/Enter \/ apply[\s\S]*While in stance[\s\S]*Exit stance/);
 await page.locator('[data-drive-move="40"]').click();await ready(page);await visible('stanceRequired');await visible('grabFrames');
 assert.equal(await page.locator('#field-stanceRequired').inputValue(),'2');assert.equal(await page.evaluate(()=>moveWorkshop.selection().slot),40);
 await page.screenshot({path:dir+'/tapper-drive.png',fullPage:true});
 await page.locator('#attack-enabled').uncheck();assert.equal(await page.locator('[data-drive-move="40"]').count(),0);
 await page.locator('#attack-enabled').check();assert.equal(await page.locator('[data-drive-move="40"]').count(),1);
 // Conditional controls update immediately; invalid values stay visible.
 await page.locator('[data-move="0"]').click();await selectSection(page,'projectiles');await page.locator('#field-projectileKind').selectOption('1');await visible('projectileSpeedX');
 await page.locator('#field-projectileSpeedX').fill('99999');
 await page.locator('#field-projectileKind').selectOption('2');await visible('projectileSpeedX');
 await page.locator('#field-view').selectOption('all');assert.equal(await page.locator('#field-view').inputValue(),'relevant');
 assert.equal(await page.locator('#export').isDisabled(),true);
 await page.locator('#field-projectileSpeedX').fill('8');await page.locator('#field-projectileKind').focus();await page.locator('#field-projectileKind').selectOption('1');await page.locator('#field-projectileKind').selectOption('2');await hidden('projectileSpeedX');
 await selectSection(page,'movement');await page.locator('#field-movement-forwardStyle').selectOption('0');await visible('movement-runSpeed');await hidden('movement-stepSpeed');
 await page.locator('#field-movement-forwardStyle').selectOption('1');await visible('movement-stepSpeed');await hidden('movement-runSpeed');
 await page.locator('#field-movement-airDashEnabled').check();await page.locator('#field-movement-airDashStyle').selectOption('3');
 await visible('movement-teleportDistance');await hidden('movement-airDashSpeed');await visible('movement-airDashPauseFrames');
 const edited=await page.evaluate(()=>moveWorkshop.data());assert.deepEqual(edited._moveWorkshop,initial._moveWorkshop);
 // Mobile form space and optional pinning retain a single shared workspace.
 await page.setViewportSize({width:390,height:844});await selectSection(page,'mechanics');
 assert.equal(await page.locator('#preview-core').evaluate(n=>getComputedStyle(n).position),'static');
 await page.locator('#preview-pin').click();assert.equal(await page.locator('#preview-core').evaluate(n=>getComputedStyle(n).position),'sticky');
 await page.locator('#preview-pin').click();await page.locator('[data-panel="stance-access"]').scrollIntoViewIfNeeded();
 assert.ok((await page.locator('#preview-core').boundingBox()).y<0,'Unpinned stage scrolls away to leave room for editing');
 await page.screenshot({path:dir+'/phone-editing.png'});
 for(const [width,height]of [[320,640],[390,844],[430,932],[768,1024],[844,390],[1440,1000]]){
  await page.setViewportSize({width,height});await page.evaluate(()=>new Promise(requestAnimationFrame));
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,`${width}×${height}: overflow`);
  assert.equal(await page.locator('#preview').count(),1);assert.equal(await page.locator('#form').count(),1);
  assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),edited);
 }
 await page.waitForFunction(()=>document.getElementById('save-status').textContent==='Saved in this browser');
 const downloadEvent=page.waitForEvent('download');await page.locator('#export').click();const download=await downloadEvent;await download.saveAs(dir+'/roundtrip.json');
 assert.deepEqual(JSON.parse(await readFile(dir+'/roundtrip.json','utf8')),edited);
 await page.reload();await ready(page);assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),edited);
 assert.deepEqual(errors,[]);console.log('PASS field organization: contextual Drive and movement, search, retained values, error visibility, saved disclosures, help, mobile pinning, 320–1440px and JSON roundtrip.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
