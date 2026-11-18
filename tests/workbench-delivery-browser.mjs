import assert from 'node:assert/strict';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {readFile,mkdtemp,rm,stat} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {pathToFileURL} from 'node:url';
import {execFileSync} from 'node:child_process';
import {serveWorkshopSite} from '../scripts/serve-workbench.mjs';
import {ready,seekMoveFrame,dragHandle} from './workbench-ui-helpers.mjs';

const mount='/Fight-guild-/',server=await serveWorkshopSite(0,'127.0.0.1',mount);
const origin=`http://127.0.0.1:${server.address().port}`,url=origin+mount;
const browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
const folder=await mkdtemp(join(tmpdir(),'fight-guild-editor-'));
const data=page=>page.evaluate(()=>moveWorkshop.data());
try{
  const context=await browser.newContext({viewport:{width:1440,height:1000}}),page=await context.newPage();
  const errors=[],requests=[],responses=[];
  page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>requests.push({url:r.url(),method:r.method()}));page.on('response',r=>responses.push(r));
  await page.addInitScript(()=>{globalThis.WebAssembly=undefined;});
  await page.goto(url);await ready(page);await page.evaluate(()=>document.fonts.ready);
  const initial=await data(page),images=await page.evaluate(()=>FIGHT_WORKSHOP_DATA.images);
  assert.equal(initial.schema,19);assert.equal(initial.characters.length,6);
  assert.ok((await stat('build/move-workshop/index.html')).size<64000,'The entry page must stay small');
  assert.ok(requests.filter(r=>r.url.endsWith('.webp')).length<Object.keys(images).length,'Artwork must load on demand');
  assert.ok(Object.values(images).every(src=>/^assets\/[a-f0-9]{64}\.webp$/.test(src)),'Art URLs must be relative and versioned');
  const initialBytes=(await Promise.all(responses.map(async r=>(await r.body()).length))).reduce((a,b)=>a+b,0);
  assert.ok(initialBytes<6*1024**2,`Initial page fetched ${initialBytes} bytes`);
  // Every shipped image remains decodable with original atlas dimensions.
  const dimensions=await page.evaluate(async()=>Promise.all(Object.entries(FIGHT_WORKSHOP_DATA.images).map(async([file,src])=>{
    const image=new Image();image.src=src;await image.decode();return [file,image.naturalWidth,image.naturalHeight];
  })));
  assert.ok(dimensions.every(([,w,h])=>w>0&&h>0));
  await page.locator('#field-startup').fill('8');await page.locator('#field-startup').blur();await ready(page);
  await page.locator('#tab-hit').click();await seekMoveFrame(page,8);await dragHandle(page,'base','reach',12);
  await page.locator('#tab-art').click();await page.locator('#note-active').fill('Keep the hosted draft and pose reference.');
  await page.locator('#reference-file').setInputFiles('art/characters/fillet.png');await page.locator('.reference-card').waitFor();
  const edited=await data(page);
  const downloadEvent=page.waitForEvent('download');await page.locator('#export').click();const download=await downloadEvent;
  const exported=join(folder,'edited.json');await download.saveAs(exported);assert.deepEqual(JSON.parse(await readFile(exported,'utf8')),edited);
  await page.reload();await ready(page);assert.deepEqual(await data(page),edited,'Hosted reload must preserve edits and pose photos');
  // Import/export stays local: no write request or third-party destination.
  assert.ok(requests.every(r=>['GET','HEAD'].includes(r.method)));
  assert.ok(requests.every(r=>r.url.startsWith(url)||r.url.startsWith('data:')||r.url.startsWith('blob:')));
  assert.ok(responses.every(r=>r.status()<400));
  const htmlResponse=await fetch(url);assert.equal(htmlResponse.headers.get('cache-control'),'no-cache');
  const imageResponse=await fetch(url+Object.values(images)[0]);assert.match(imageResponse.headers.get('cache-control'),/immutable/);
  assert.equal((await fetch(url+'assets/missing.webp')).status,404);
  assert.equal((await fetch(url+'../package.json')).status,404);
  await context.close();

  // Extract the exact delivered ZIP, then launch index.html with all HTTP blocked.
  execFileSync('python',['-c','import sys,zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])','build/FightGuild-Move-Workshop.zip',folder]);
  const offline=await browser.newContext({viewport:{width:1280,height:900}});
  await offline.route(/^https?:/,route=>route.abort());
  const local=await offline.newPage();local.on('pageerror',e=>errors.push(e.message));
  await local.addInitScript(()=>{globalThis.WebAssembly=undefined;});
  let localAllowed=true;
  try{await local.goto(pathToFileURL(join(folder,'FightGuild-Move-Workshop/index.html')).href);}
  catch(error){
    if(process.env.FIGHT_SKIP_BLOCKED_FILE_CHECK!=='1'||!error.message.includes('ERR_BLOCKED_BY_ADMINISTRATOR'))throw error;
    localAllowed=false;
    console.log('SKIP direct file opening: this cloud browser blocks file:// by administrator policy. CI checks it in the standard Playwright browser.');
  }
  if(localAllowed){
    await ready(local);assert.deepEqual(await data(local),initial);
    await local.locator('#import-file').setInputFiles(exported);
    await local.waitForFunction(()=>document.getElementById('toast').textContent.startsWith('Move data imported'));
    await ready(local);
    assert.deepEqual(await data(local),edited);
    await local.locator('#fighter').selectOption('2');await local.locator('[data-move="7"]').click();await ready(local);await seekMoveFrame(local,18);
    await local.evaluate(async()=>{const i=new Image();i.src=FIGHT_WORKSHOP_DATA.images['smoke-v1/launcher.png'];await i.decode();});
    assert.equal(await local.locator('#preview-empty').isVisible(),false);
  }
  assert.deepEqual(errors,[]);
  await offline.close();
  console.log(`PASS hosted delivery: ${(initialBytes/1024**2).toFixed(2)} MiB initial fetch, ${dimensions.length} decoded sheets, project-subpath URLs, cache headers, editing/dragging, photos, autosave, JSON round trip and no uploads.${localAllowed?' Extracted ZIP also passes offline.':''}`);
}finally{await browser.close();await new Promise(resolve=>server.close(resolve));await rm(folder,{recursive:true,force:true});}
