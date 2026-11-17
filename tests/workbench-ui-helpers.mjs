import {readFile} from 'node:fs/promises';
export async function seedBaseline(page){const pack=JSON.parse(await readFile('build/workbench-pack.json','utf8'));await page.addInitScript(defaults=>{const key='fight-guild.move-workshop.v1';if(!localStorage.getItem(key))localStorage.setItem(key,JSON.stringify({format:1,data:defaults,selection:{character:5,slot:0,tab:'timing'}}));},pack.defaults);}
export async function ready(page){await page.waitForFunction(()=>window.moveWorkshop?.preview()&&!moveWorkshop.cursor().pending);}
export async function seekMoveFrame(page,frame){
  await ready(page);
  const tick=await page.evaluate(frame=>moveWorkshop.preview().frames.findIndex(f=>f.selectedFrame===frame),frame);
  if(tick<0)throw new Error(`Move frame ${frame} is missing from the exchange`);
  await page.locator('#frame').evaluate((n,tick)=>{n.value=String(tick);n.dispatchEvent(new Event('input',{bubbles:true}));},tick);
}
export async function dragHandle(page,target,key,dx,dy=0){
  await ready(page);await page.locator('#preview').scrollIntoViewIfNeeded();
  const box=await page.locator('#preview').boundingBox();
  const h=await page.evaluate(({target,key})=>moveWorkshop.geometry().handles.find(h=>h.target===target&&h.key===key),{target,key});
  if(!h)throw new Error(`No editable ${target}/${key} handle`);
  await page.mouse.move(box.x+h.x,box.y+h.y);await page.mouse.down();await page.mouse.move(box.x+h.x+dx,box.y+h.y+dy,{steps:5});await page.mouse.up();await ready(page);
}
