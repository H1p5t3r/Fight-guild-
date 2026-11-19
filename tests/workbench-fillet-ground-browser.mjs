import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir,readFile} from 'node:fs/promises';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {ready,seekMoveFrame} from './workbench-ui-helpers.mjs';

const art=JSON.parse(await readFile('godot/assets/fighters/manifest.json','utf8')).fighters[5];
const spec=JSON.parse(await readFile('art/characters/fillet-v1/FILLET_SPEC.json','utf8'));
const actions=spec.actions.filter(a=>art.attack_animations[a.slot]);
const server=await serveWorkshopSite(0);
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 await page.addInitScript(()=>{
  window.filletDraws=[];
  const draw=CanvasRenderingContext2D.prototype.drawImage;
  CanvasRenderingContext2D.prototype.drawImage=function(image,...args){
   if(this.canvas.id==='preview'&&args.length===8){
    window.filletDraws.push({source:image.currentSrc||image.src,size:[image.naturalWidth,image.naturalHeight],region:args.slice(0,4)});
    if(window.filletDraws.length>30)window.filletDraws.shift();
   }
   return draw.call(this,image,...args);
  };
 });
 await page.goto(`http://127.0.0.1:${server.address().port}/`);await ready(page);
 let keys=0;
 for(const action of actions){
  await page.locator(`[data-move="${action.slot}"]`).click();await ready(page);
  for(const expected of art.attack_animation.frames.filter(f=>f.action_id===action.id)){
   await page.evaluate(()=>{window.filletDraws=[];});
   await seekMoveFrame(page,expected.action_frame);
   await page.waitForFunction(({file,region,size})=>window.filletDraws.some(d=>d.source===new URL(FIGHT_WORKSHOP_DATA.images[file],location.href).href&&JSON.stringify(d.region)===JSON.stringify(region)&&JSON.stringify(d.size)===JSON.stringify(size)),{file:expected.file,region:expected.region,size:expected.source_size});
   keys++;
  }
 }
 assert.equal(keys,105);
 await mkdir('build/fillet-ground-review',{recursive:true});
 await page.locator('[data-move="6"]').click();await ready(page);await seekMoveFrame(page,12);
 await page.waitForFunction(file=>window.filletDraws.some(d=>d.source===new URL(FIGHT_WORKSHOP_DATA.images[file],location.href).href),art.sweep_fx.file);
 await page.screenshot({path:'build/fillet-ground-review/sweep-desktop.png'});
 await page.setViewportSize({width:390,height:844});
 await page.locator('#choose-move').click();
 await page.locator('[data-move="8"]').click();await ready(page);await seekMoveFrame(page,9);
 assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
 await page.locator('#preview').scrollIntoViewIfNeeded();
 await page.screenshot({path:'build/fillet-ground-review/anti-air-mobile.png'});
 assert.deepEqual(errors,[]);
 console.log('PASS all 105 Fillet pose keys draw from their registered atlases in the hosted editor, plus desktop/mobile preview');
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));}
