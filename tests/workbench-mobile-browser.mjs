import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,readFile} from 'node:fs/promises';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {seedBaseline,ready,selectSection,seekMoveFrame} from './workbench-ui-helpers.mjs';
const server=await serveWorkshopSite(0),browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
await mkdir('build/mobile-review/verified',{recursive:true});
try{
 const context=await browser.newContext({viewport:{width:390,height:844},isMobile:true,hasTouch:true,deviceScaleFactor:2}),page=await context.newPage(),errors=[];
 page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>{globalThis.WebAssembly=undefined;});
 await seedBaseline(page);await page.goto(`http://127.0.0.1:${server.address().port}/`);await ready(page);
 const initial=await page.evaluate(()=>moveWorkshop.data());
 assert.equal(await page.locator('#preview').count(),1);assert.equal(await page.locator('#form').count(),1);
 assert.ok((await page.locator('#preview').boundingBox()).y<450,'The preview should appear in the first phone screen');
 assert.equal(await page.locator('#export').innerText(),'Export');
 assert.ok((await page.locator('#export').boundingBox()).height>=44);
 await page.screenshot({path:'build/mobile-review/verified/phone.png'});
 await page.locator('#choose-move').tap();assert.equal(await page.locator('#move-dialog').isVisible(),true);
 await page.locator('#search').fill('6P');await page.screenshot({path:'build/mobile-review/verified/move-picker.png'});
 await page.locator('[data-move="8"]').tap();assert.equal(await page.locator('#move-dialog').isVisible(),false);
 assert.equal(await page.locator('#chosen-move').innerText(),'6P');assert.equal(await page.evaluate(()=>document.activeElement.id),'choose-move');
 assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),initial,'Navigation must not edit the draft');
 // Invalid edits survive navigation attempts; valid numeric changes are saved.
 await page.locator('#field-startup').fill('2');await selectSection(page,'hit');
 assert.equal(await page.locator('#section-picker').inputValue(),'timing');assert.equal(await page.locator('#export').isDisabled(),true);
 await page.locator('#field-startup').fill('7');await page.locator('#field-startup').blur();await ready(page);
 await selectSection(page,'hit');await ready(page);await seekMoveFrame(page,7);
 const cdp=await context.newCDPSession(page);
 const gesture=async(x,y,dx,dy)=>{
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{x,y,id:1}]});
  for(let i=1;i<=6;++i){await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{x:x+dx*i/6,y:y+dy*i/6,id:1}]});await page.evaluate(()=>new Promise(requestAnimationFrame));}
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
 };
 await page.evaluate(()=>scrollTo(0,0));
 const beforeSwipe=await page.evaluate(()=>JSON.stringify(moveWorkshop.data())),bounds=await page.locator('#preview').boundingBox();
 await gesture(bounds.x+25,bounds.y+170,0,-110);
 await page.waitForFunction(()=>scrollY>30);
 assert.equal(await page.evaluate(()=>JSON.stringify(moveWorkshop.data())),beforeSwipe,'Swiping the stage should scroll, not change a box');
 // True browser touch events, not synthetic model changes, resize a hitbox.
 await page.locator('#touch-edit').tap();assert.equal(await page.locator('#touch-edit').getAttribute('aria-pressed'),'true');
 const oldReach=await page.evaluate(()=>moveWorkshop.data().characters[5].moves[8].reach);
 const box=await page.locator('#preview').boundingBox(),handle=await page.evaluate(()=>moveWorkshop.geometry().handles.find(h=>h.target==='base'&&h.key==='reach'));
 assert.ok(handle);await gesture(box.x+handle.x,box.y+handle.y,20,0);await ready(page);
 assert.ok(await page.evaluate(()=>moveWorkshop.data().characters[5].moves[8].reach)>oldReach);
 await page.locator('#undo').tap();await ready(page);assert.equal(await page.evaluate(()=>moveWorkshop.data().characters[5].moves[8].reach),oldReach);
 await page.screenshot({path:'build/mobile-review/verified/touch-boxes.png'});
 await page.locator('#preview-collapse').tap();assert.equal(await page.locator('#preview-visual').isHidden(),true);
 await page.locator('#preview-collapse').tap();assert.equal(await page.locator('#preview-visual').isVisible(),true);
 // Build, reorder and delay a real sequence in the same canvas.
 await selectSection(page,'sequence');await ready(page);
 for(const move of ['0','1','8']){await page.locator('#sequence-add-move').selectOption(move);await page.locator('#sequence-add').tap();await ready(page);}
 assert.match(await page.locator('#sequence-result').innerText(),/3 \/ 3 moves started/);
 await page.locator('#field-sequence-delay-1').fill('-1');await selectSection(page,'timing');
 assert.equal(await page.locator('#section-picker').inputValue(),'sequence');assert.equal(await page.locator('#export').isDisabled(),true);
 await page.locator('#field-sequence-delay-1').fill('8');await page.locator('#field-sequence-delay-1').blur();await ready(page);
 assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()._moveWorkshop.sequences.Fillet),[{move:0,delay:0},{move:1,delay:8},{move:8,delay:0}]);
 await page.getByRole('button',{name:'Move step 3 up',exact:true}).tap();await ready(page);
 assert.equal(await page.locator('#sequence-move-1').inputValue(),'8');await page.locator('#undo').tap();await ready(page);
 await page.locator('[data-sequence-seek="1"]').tap();
 assert.equal(await page.evaluate(()=>moveWorkshop.cursor().index),await page.evaluate(()=>moveWorkshop.preview().steps[1].start));
 await page.locator('#play').tap();await page.waitForFunction(()=>document.getElementById('play').getAttribute('aria-label')==='Pause sequence');await page.locator('#play').tap();
 await page.locator('#preview-options-open').tap();await page.locator('#test-behavior').selectOption('block');await ready(page);
 await page.locator('#preview-display>summary').tap();await page.locator('#show-distances').uncheck();
 await page.locator('#close-preview-options').tap();assert.equal(await page.locator('#preview-options-dialog').isVisible(),false);
 assert.ok((await page.evaluate(()=>moveWorkshop.preview().contacts)).some(c=>c.event===2));
 await page.locator('[data-sequence-seek="1"]').tap();await page.screenshot({path:'build/mobile-review/verified/sequence.png'});
 // Both navigation modes use the original nodes and preserve the user's data.
 const edited=await page.evaluate(()=>moveWorkshop.data());
 for(const [width,height]of [[320,640],[430,932],[768,1024],[844,390],[1440,1000],[390,844]]){
  await page.setViewportSize({width,height});await page.evaluate(()=>new Promise(requestAnimationFrame));
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,`${width}×${height}: overflow`);
  assert.equal(await page.locator('#preview').count(),1);assert.equal(await page.locator('#move-browser').count(),1);
  assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),edited);
  if(width===1440){assert.ok(await page.locator('#move-list').isVisible());assert.ok(await page.locator('#tab-sequence').isVisible());}
  if(height===390)assert.equal(await page.locator('#preview-core').evaluate(n=>getComputedStyle(n).position),'static');
 }
 await page.waitForFunction(()=>document.getElementById('save-status').textContent==='Saved in this browser');
 const downloadEvent=page.waitForEvent('download');await page.locator('#export').tap();const download=await downloadEvent;await download.saveAs('build/mobile-sequence-roundtrip.json');
 assert.deepEqual(JSON.parse(await readFile('build/mobile-sequence-roundtrip.json','utf8')),edited);
 await page.reload();await ready(page);assert.equal(await page.locator('#section-picker').inputValue(),'sequence');assert.deepEqual(await page.evaluate(()=>moveWorkshop.data()),edited);
 assert.deepEqual(errors,[]);await context.close();
 console.log('PASS mobile: real touch scrolling/box edits, picker focus, numeric validation, shared preview, queued sequences, delays, undo, 320–1440px, rotation, autosave and JSON without WebAssembly.');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
