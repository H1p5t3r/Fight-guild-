import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {readFile,mkdir} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {ready} from './workbench-ui-helpers.mjs';
const server=await serveWorkshopSite(0),url=`http://127.0.0.1:${server.address().port}/`;
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
try {
  const page=await browser.newPage({viewport:{width:1440,height:1060}}),errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  const data=JSON.parse(await readFile('build/workbench-pack.json','utf8')).defaults;
  Object.assign(data.characters[5].moves[0],{knockdown:1,knockdownFrames:12,wakeupFrames:20,launch:600,pushback:0,damage:1});
  await page.addInitScript(data=>{
    globalThis.WebAssembly=undefined;
    localStorage.setItem('fight-guild.move-workshop.v1',JSON.stringify({format:1,data,selection:{character:5,slot:0,tab:'hit'}}));
  },data);
  await page.goto(url);await ready(page);
  await page.locator('#test-gap').fill('0');await page.locator('#test-gap').dispatchEvent('change');
  await page.locator('#test-target').selectOption('3');
  for(const key of ['hit','hurt','distances'])await page.locator('#show-'+key).uncheck();
  await mkdir('build/recovery-review',{recursive:true});
  for(const kind of [1,2])for(const facing of [1,-1]){
    await page.locator('#field-knockdown').selectOption(String(kind));
    await page.locator('#test-facing').selectOption(String(facing));
    const phase=kind===2?9:10;
    await page.waitForFunction(({phase,facing})=>!moveWorkshop.cursor().pending&&moveWorkshop.preview().target===3&&moveWorkshop.preview().frames.some(f=>f.state.players[1].posePhase===phase)&&moveWorkshop.preview().frames[0].state.players[0].facing===facing,{phase,facing});
    const ticks=await page.evaluate(()=>[2,3].map(reaction=>moveWorkshop.preview().frames.findIndex(f=>f.state.players[1].reaction===reaction)));
    assert.ok(ticks.every(t=>t>=0));
    for(let i=0;i<2;i++){
      await page.locator('#frame').evaluate((node,tick)=>{node.value=String(tick);node.dispatchEvent(new Event('input',{bubbles:true}));},ticks[i]);
      await page.evaluate(async phase=>{const pack=FIGHT_WORKSHOP_DATA,sheet=pack.art[3][phase===9?'knockdown':'knockdown_back'],image=new Image();image.src=pack.images[sheet.file];await image.decode();await new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve)));},phase);
      assert.equal(await page.locator('#preview-empty').isVisible(),false);
      if(facing===1)await page.locator('#preview').screenshot({path:`build/recovery-review/editor-${kind===2?'hard':'soft'}-${i?'getup':'down'}.png`});
    }
  }
  assert.deepEqual(errors,[]);
  console.log('PASS hosted recovery rendering: soft on back, hard face down, get-up animation, both facings, no WebAssembly.');
} finally {await browser.close();await new Promise(resolve=>server.close(resolve));}
