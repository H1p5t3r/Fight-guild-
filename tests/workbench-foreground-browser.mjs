import {legacyData} from './legacy-data.mjs';
import {seedBaseline} from './workbench-ui-helpers.mjs';
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
  const data=legacyData(JSON.parse(await readFile('build/workbench-pack.json','utf8')).defaults);
  await page.addInitScript(data=>{
    globalThis.WebAssembly=undefined;
    localStorage.setItem('fight-guild.move-workshop.v1',JSON.stringify({format:1,data,selection:{character:5,slot:0,tab:'hit'}}));
    globalThis.fighterPaint=[];
    const original=CanvasRenderingContext2D.prototype.drawImage;
    CanvasRenderingContext2D.prototype.drawImage=function(...args){
      if(this.canvas.id==='preview')fighterPaint.push(args[0].src);
      return original.apply(this,args);
    };
  },data);
  await seedBaseline(page);await page.goto(url);await ready(page);
  await page.locator('#test-gap').fill('0');await page.locator('#test-gap').dispatchEvent('change');
  await page.locator('#test-target').selectOption('4');
  await page.waitForFunction(()=>!moveWorkshop.cursor().pending&&moveWorkshop.preview().contacts.length>0);
  const contact=await page.evaluate(()=>moveWorkshop.preview().frames.findIndex(f=>f.state.foregroundPlayer===0));
  assert.ok(contact>0);
  // Seek backward again too: draw order must come from that frame, not UI history.
  for(const tick of [0,contact,0,contact]){
    const expected=await page.evaluate(async tick=>{
      const frame=moveWorkshop.preview().frames[tick],pack=FIGHT_WORKSHOP_DATA;
      const phases=['active','windup','block','signature_windup','signature_active','ready','walk','run','stance','knockdown','knockdown_back','idle','crouch_idle','back_walk','attack_animation','backdash'];
      const files=frame.state.players.map(f=>{
        const sheet=pack.art[f.character][phases[f.posePhase]],tile=sheet.frames[f.poseIndex];
        return new URL(pack.images[tile.file??sheet.file],location.href).href;
      });
      await Promise.all(files.map(async src=>{const image=new Image();image.src=src;await image.decode();}));
      return {files,order:frame.state.foregroundPlayer===0?[files[1],files[0]]:files};
    },tick);
    await page.evaluate(()=>{fighterPaint=[];});
    await page.locator('#frame').evaluate((node,tick)=>{node.value=String(tick);node.dispatchEvent(new Event('input',{bubbles:true}));},tick);
    await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
    const painted=await page.evaluate(files=>fighterPaint.filter(src=>files.includes(src)).slice(-2),expected.files);
    assert.deepEqual(painted,expected.order,`Wrong foreground after seeking to frame ${tick}`);
  }
  await mkdir('build/recovery-review',{recursive:true});
  await page.locator('#preview').screenshot({path:'build/recovery-review/editor-attacker-foreground.png'});
  assert.deepEqual(errors,[]);
  console.log('PASS browser foreground: actual canvas sprite order on contact and backward/forward seeking without WebAssembly.');
} finally {await browser.close();await new Promise(resolve=>server.close(resolve));}
