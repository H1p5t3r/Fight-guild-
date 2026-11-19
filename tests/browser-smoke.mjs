import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import {existsSync} from 'node:fs';
import {readFile,mkdir} from 'node:fs/promises';
import {createServer} from '../scripts/server.mjs';
const {server,wss}=createServer();
await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
const url=`http://127.0.0.1:${server.address().port}`;
const executablePath=process.env.CHROMIUM_PATH??(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined);
const browser=await chromium.launch({headless:true,executablePath,args:['--no-sandbox','--disable-background-timer-throttling','--disable-renderer-backgrounding']});
const errors=[];
const context=await browser.newContext({viewport:{width:1440,height:1080}});
const page=await context.newPage();
page.on('pageerror',e=>errors.push(e.message));
const state=()=>page.evaluate(()=>window.fightLab.state());
async function frames(n){for(let i=0;i<n;++i)await page.locator('#step').click();}
async function pause(){await page.locator('#pause').click();}
try {
  await page.goto(url);await page.getByRole('button',{name:'Enter training floor'}).click();await pause();
  const jab=await page.evaluate(()=>window.fightLab.data().characters[0].moves[0]);
  await page.keyboard.down('KeyD');await frames(30);await page.keyboard.up('KeyD');
  const before=(await state()).players[1].health;
  await page.keyboard.down('KeyJ');await frames(jab.startup-1);assert.equal((await state()).players[1].health,before);
  await frames(1);await page.keyboard.up('KeyJ');assert.equal((await state()).players[1].health,before-jab.damage);
  await page.locator('#field-damage').fill('177');await page.getByRole('button',{name:'Apply & reset',exact:true}).click();
  assert.equal(await page.evaluate(()=>window.fightLab.data().characters[0].moves[0].damage),177);
  await pause();await page.keyboard.down('KeyD');await frames(30);await page.keyboard.up('KeyD');
  await page.keyboard.down('KeyJ');await frames(jab.startup);await page.keyboard.up('KeyJ');assert.equal((await state()).players[1].health,823);
  await page.locator('#save').click();
  const downloadPromise=page.waitForEvent('download');await page.locator('#export').click();const download=await downloadPromise;
  assert.equal(JSON.parse(await readFile(await download.path(),'utf8')).characters[0].moves[0].damage,177);
  await page.reload();await page.getByRole('button',{name:'Enter training floor'}).click();assert.equal(await page.locator('#field-damage').inputValue(),'177');
  const bad=await page.evaluate(()=>window.fightLab.data());bad.characters[1].moves[21].startup=0;
  await page.locator('#import-file').setInputFiles({name:'invalid.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(bad))});
  await page.waitForFunction(()=>document.getElementById('editor-status').textContent.startsWith('Import failed'));
  assert.equal(await page.evaluate(()=>window.fightLab.data().characters[0].moves[0].damage),177);
  await page.locator('#reset').click();await pause();
  await page.keyboard.down('KeyS');await frames(1);await page.keyboard.down('KeyD');await frames(1);await page.keyboard.up('KeyS');await page.keyboard.down('KeyJ');await frames(1);await page.keyboard.up('KeyJ');await page.keyboard.up('KeyD');
  assert.equal((await state()).players[0].move,14);
  await page.locator('#select-open').click();await page.locator('#p1-simple').check();await page.getByRole('button',{name:'Enter training floor'}).click();await pause();
  await page.keyboard.down('ShiftLeft');await page.keyboard.down('KeyW');await page.keyboard.down('KeyI');await frames(1);
  for(const key of ['ShiftLeft','KeyW','KeyI'])await page.keyboard.up(key);
  const simple=await state();assert.equal(simple.players[0].move,16);assert.equal(simple.players[0].y,0);assert.equal(simple.players[0].simple,1);assert.equal(simple.players[1].simple,0);
  await page.locator('#rollback-check').click();await page.waitForFunction(()=>document.getElementById('rollback-result').textContent.startsWith('PASS'));
  await page.locator('#reset').click();await pause();
  await page.evaluate(()=>Object.defineProperty(navigator,'getGamepads',{configurable:true,value:()=>[{axes:[0,0],buttons:Array.from({length:16},(_,i)=>({pressed:i===0}))}]}));
  await frames(1);assert.equal((await state()).players[0].move,0);
  await page.evaluate(()=>Object.defineProperty(navigator,'getGamepads',{configurable:true,value:()=>[]}));
  await mkdir(new URL('../build/',import.meta.url),{recursive:true});
  await page.locator('#reset').click();await page.screenshot({path:new URL('../build/combat-lab.png',import.meta.url).pathname,fullPage:true});
  console.log('PASS: browser combat, edited damage, save/load/export, invalid import, motions, simple controls, gamepad mapping, rollback workbench');

  const peerContexts=await Promise.all([0,1].map(()=>browser.newContext({viewport:{width:1280,height:900}})));
  const peers=await Promise.all(peerContexts.map(c=>c.newPage()));
  for(const p of peers){p.on('pageerror',e=>errors.push(e.message));await p.goto(url);await p.getByRole('button',{name:'Enter training floor'}).click();}
  await peers[0].locator('#host').click();await peers[0].waitForFunction(()=>document.getElementById('room-code').value.length===6);
  const code=await peers[0].locator('#room-code').inputValue();await peers[1].locator('#room-code').fill(code);await peers[1].locator('#join').click();
  for(const p of peers)await p.waitForFunction(()=>window.fightLab.net()?.verifiedThrough>=60,null,{timeout:15000});
  assert.equal(await peers[0].evaluate(()=>window.fightLab.net().player),0);assert.equal(await peers[1].evaluate(()=>window.fightLab.net().player),1);
  await peers[0].locator('#arena').focus();await peers[0].keyboard.down('KeyD');await peers[0].waitForTimeout(300);await peers[0].keyboard.up('KeyD');await peers[0].keyboard.press('KeyJ');
  for(const p of peers)await p.waitForFunction(()=>window.fightLab.net()?.verifiedThrough>=120,null,{timeout:15000});
  assert.equal(await peers[0].locator('#field-damage').isDisabled(),true);
  await peers[0].locator('#disconnect').click();await peers[1].waitForFunction(()=>document.getElementById('network-status').textContent.includes('disconnected'));
  console.log('PASS: two browser clients connect, verify confirmed state hashes, lock editing, and disconnect cleanly');
  const standalone=await browser.newPage();standalone.on('pageerror',e=>errors.push(e.message));
  let directFile=true;
  try {await standalone.goto(new URL('../build/FightGuild.html',import.meta.url).href);}
  catch(error) {
    if(!error.message.includes('ERR_BLOCKED_BY_ADMINISTRATOR'))throw error;
    directFile=false;
    const html=await readFile(new URL('../build/FightGuild.html',import.meta.url),'utf8');
    await standalone.route(`${url}/standalone-test.html`,route=>route.fulfill({contentType:'text/html',body:html}));
    await standalone.goto(`${url}/standalone-test.html`);
  }
  await standalone.getByRole('button',{name:'Enter training floor'}).click();
  await standalone.waitForFunction(()=>window.fightLab.state().frame>0);assert.equal(await standalone.locator('#host').isDisabled(),true);
  await standalone.locator('#rollback-check').click();await standalone.waitForFunction(()=>document.getElementById('rollback-result').textContent.startsWith('PASS'));
  console.log('PASS: self-contained HTML runs combat plus rollback checks');
  console.log(directFile?'PASS: direct file launch':'SKIP: direct file launch blocked by managed Chromium; packaged content verified over local HTTP');
  await page.setViewportSize({width:390,height:844});await page.locator('#help-open').click();assert.equal(await page.locator('#help-dialog').isVisible(),true);await page.locator('#help-close').click();
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),true);
  assert.deepEqual(errors,[]);
  console.log('PASS: narrow layout, controls dialog, and no browser exceptions');
} finally {await browser.close();for(const client of wss.clients)client.terminate();await new Promise(resolve=>wss.close(resolve));await new Promise(resolve=>server.close(resolve));}
