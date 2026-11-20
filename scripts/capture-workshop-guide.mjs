// Capture the current standalone editor with a fresh, temporary browser draft.
import {seedBaseline} from '../tests/workbench-ui-helpers.mjs';
import {chromium} from 'playwright';
import {existsSync} from 'node:fs';
import {mkdir} from 'node:fs/promises';
import {serveWorkshop} from './serve-workbench.mjs';
const server=await serveWorkshop(0);
let browser;
try {
  browser=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH||(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
  const page=await browser.newPage({viewport:{width:1440,height:1180},deviceScaleFactor:1});
  await mkdir('docs/workshop-guide',{recursive:true});
  await seedBaseline(page);await page.goto(`http://127.0.0.1:${server.address().port}/`);
  await page.locator('#field-startup').waitFor();
  await page.waitForFunction(()=>moveWorkshop.preview()?.contacts.length>0);
  const tick=await page.evaluate(()=>moveWorkshop.preview().contacts[0].tick);
  await page.locator('#frame').evaluate((n,tick)=>{n.value=String(tick);n.dispatchEvent(new Event('input',{bubbles:true}));},tick);
  await page.evaluate(()=>document.fonts.ready);
  await page.waitForFunction(()=>document.getElementById('preview-empty').hidden);
  await page.screenshot({path:'docs/workshop-guide/editor-overview.png'});
  await page.locator('#tab-hurt').click();
  await page.locator('#hurt-custom').check();
  await page.locator('#hurt-region').selectOption('torsoArms');
  await page.waitForFunction(()=>!moveWorkshop.cursor().pending);
  await page.locator('#preview').screenshot({path:'docs/workshop-guide/hurtbox-preview.png'});
  console.log('Captured the editor overview and active-phase hurtbox preview.');
} finally {
  await browser?.close();
  await new Promise(resolve=>server.close(resolve));
}
