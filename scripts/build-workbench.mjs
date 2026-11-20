import {buildSharkMotionReview} from './build-shark-motion-review.mjs';
import {buildSmokeMotionReview} from './build-smoke-motion-review.mjs';
import {build} from 'esbuild';
import {isDeepStrictEqual} from 'node:util';
import {chromium} from 'playwright';
import {readFile,writeFile,mkdir,rm} from 'node:fs/promises';
import {existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';
import {Engine,FIELDS,MOVEMENT_FIELDS} from '../web/engine.mjs';
import {validate} from '../web/workbench/model.mjs';
import {SPECS} from '../web/workbench/specs.mjs';
import {buildFilletMotionReview} from './build-fillet-motion-review.mjs';
const root=new URL('../',import.meta.url), path=p=>fileURLToPath(new URL(p,root));
const wasm=await readFile(path('web/generated/fight.wasm'));
const {instance}=await WebAssembly.instantiate(wasm),engine=new Engine(instance),defaults=engine.data();
if(defaults.schema!==26||defaults.coreVersion!==26) throw new Error('Rebuild the current combat core before packaging the workshop.');
// Ship the actual integer combat simulation as plain JS. Workplace browsers
// need neither a native executable nor WebAssembly permission to play a preview.
execFileSync(path('node_modules/.bin/wasm2js'),[path('web/generated/fight.wasm'),'-O','--enable-bulk-memory','-o',path('build/fight-core-js.mjs')]);
const translated=await readFile(path('build/fight-core-js.mjs'),'utf8');
const factoryAt=translated.indexOf('var retasmFunc = asmFunc(');
if(factoryAt<0)throw new Error('Unexpected wasm2js output; no simulation factory.');
// wasm2js also emits memory helpers outside asmFunc; enclose those as well so
// separate preview instances never share their memory-copy view.
await writeFile(path('web/generated/fight-core.mjs'),'export function createCombatCore(){\n'+translated.slice(0,factoryAt)+'return asmFunc({});\n}\n');
if(FIELDS.some(key=>!SPECS[key])||Object.keys(SPECS).length!==FIELDS.length)throw new Error('Every combat field needs an editor specification.');
// Discover accepted integer intervals from the real combat core, so browser
// validation cannot drift from native move/rule limits. Motion is a discrete enum.
function interval(set,value){
  let lo=-2147483648,hi=value;
  while(lo<hi){const mid=Math.floor((lo+hi)/2);if(set(mid))hi=mid;else lo=mid+1;}
  const min=lo;lo=value;hi=2147483647;
  while(lo<hi){const mid=Math.ceil((lo+hi)/2);if(set(mid))lo=mid;else hi=mid-1;}
  const max=lo;if(!set(value))throw new Error('Failed to restore a probed default.');return {min,max};
}
const limits={moves:[],movement:[],rules:{}};
for(let c=0;c<defaults.characters.length;c++){
  limits.moves.push(Object.fromEntries(FIELDS.map((key,i)=>[key,key==='motion'?{min:0,max:623}:interval(v=>engine.api.fg_move_set(c,0,i,v),defaults.characters[c].moves[0][key])])));
  limits.movement.push(Object.fromEntries(MOVEMENT_FIELDS.map((key,i)=>[key,interval(v=>engine.api.fg_mobility_set(c,i,v),defaults.characters[c].movement[key])])));
}
let rule=0;
for(const [group,values] of Object.entries(defaults).filter(([key])=>key.endsWith('Rules'))){
  limits.rules[group]={};
  for(const [key,value] of Object.entries(values)) {const i=rule++;limits.rules[group][key]=interval(v=>engine.api.fg_rule_set(i,v),value);}
}
if(JSON.stringify(defaults)!==JSON.stringify(engine.data()))throw new Error('Limit probing changed defaults.');
const manifest=JSON.parse(await readFile(path('godot/assets/fighters/manifest.json'),'utf8'));
const collisions=JSON.parse(await readFile(path('godot/data/fighter_collision.json'),'utf8'));
const phases=['active','windup','block','signature_active','signature_windup','ready','walk','run','stance','knockdown','knockdown_back','idle','crouch_idle','back_walk','attack_animation','backdash','idle_smoke','movement_smoke','backdraft_fx','sword_fx','sweep_fx','knife_fx','line_fx'];
const art=manifest.fighters.map(f=>Object.fromEntries(['name','hook_weapon','projectile','projectile_variants','attack_animations','attack_connected','paired_animations',...phases].filter(p=>f[p]).map(p=>[p,f[p]])));
const files=[...new Set(art.flatMap(f=>phases.filter(p=>f[p]).flatMap(p=>[f[p].file,...f[p].frames.flatMap(frame=>frame.file?[frame.file]:[])])))];
for(const f of manifest.fighters)if(f.hook_weapon&&!files.includes(f.hook_weapon.file))files.push(f.hook_weapon.file);
// The comparison retains superseded drawings that are no longer in live clips.
const reviewBaseline=JSON.parse(await readFile(path('art/characters/fillet-v1/production/kit-timing/baseline.json'),'utf8'));
for(const action of Object.values(reviewBaseline.actions))for(const frame of action.frames)if(!files.includes(frame.file))files.push(frame.file);
const grabBaseline=JSON.parse(await readFile(path('art/characters/fillet-v1/production/command-grabs-v2/before.json'),'utf8'));
for(const action of Object.values(grabBaseline.actions))for(const entry of [...action.timeline,...action.contactTimeline])for(const frame of [entry.actor,entry.target].filter(Boolean))if(!files.includes(frame.file))files.push(frame.file);
const filletAudit=JSON.parse(await readFile(path('art/characters/fillet-v1/production/guide-audit-v1/before.json'),'utf8'));
for(const move of filletAudit.moves)for(const key of ['timeline','contactTimeline','blockTimeline'])for(const entry of move[key])for(const frame of [entry.actor,entry.target].filter(Boolean))if(!files.includes(frame.file))files.push(frame.file);
for(const sheet of Object.values(filletAudit.effects))for(const file of [sheet.file,...sheet.frames.map(f=>f.file).filter(Boolean)])if(!files.includes(file))files.push(file);
files.push("appearance-v3/projectiles.png");
for(const fighter of art)if(fighter.projectile)files.push(fighter.projectile.file);
for(const fighter of art)for(const projectile of Object.values(fighter.projectile_variants??{}))if(!files.includes(projectile.file))files.push(projectile.file);
const images={};await mkdir(path('build/workbench-assets'),{recursive:true});
let browser,page;
try {
  for(const file of files){
    const source=await readFile(path('godot/assets/fighters/'+file));
    const hash=createHash('sha256').update(source).update('webp-quality-0.92-original-dimensions').digest('hex');
    const cached=path('build/workbench-assets/'+hash+'.webp');
    if(!existsSync(cached)){
      browser??=await chromium.launch({headless:true,executablePath:process.env.CHROMIUM_PATH??(existsSync('/usr/bin/chromium')?'/usr/bin/chromium':undefined),args:['--no-sandbox']});
      page??=await browser.newPage();
      // Texture encoding only; original generated PNGs, pixels' geometry, pivots
      // and alpha dimensions remain untouched. No new artwork is synthesized.
      const encoded=await page.evaluate(async source=>{
        const img=new Image();img.src=source;await img.decode();
        const canvas=document.createElement('canvas');canvas.width=img.width;canvas.height=img.height;
        canvas.getContext('2d').drawImage(img,0,0);return canvas.toDataURL('image/webp',0.92).split(',')[1];
      },'data:image/png;base64,'+source.toString('base64'));
      await writeFile(cached,Buffer.from(encoded,'base64'));
    }
    images[file]='data:image/webp;base64,'+(await readFile(cached)).toString('base64');
  }
} finally {await browser?.close();}
const regions=['legs','torsoArms','head','extension'],posePhases={active:0,windup:1,block:2,signature_windup:3,signature_active:4,ready:5,walk:6,run:7,stance:8,knockdown:9,knockdown_back:10,idle:11,crouch_idle:12,back_walk:13,attack_animation:14,backdash:15};
const hurtPoses=art.map((fighter,c)=>Object.fromEntries(Object.entries(posePhases).filter(([phase])=>fighter[phase]).map(([phase,p])=>[phase,fighter[phase].frames.map((_,pose)=>Object.fromEntries(Array.from({length:engine.api.fg_pose_box_count(c,p,pose)},(_,n)=>[regions[n],Array.from({length:4},(_,edge)=>engine.api.fg_pose_box_get(c,p,pose,n,edge))])))])));
const pack={format:1,defaults,limits,art,collisions:collisions.fighters,hurtPoses,images};
const manifestPath=path('godot/data/workshop/current.json');
if(existsSync(manifestPath)){
  const batch=JSON.parse(await readFile(manifestPath,'utf8')),raw=await readFile(path('godot/data/workshop/'+batch.file));
  if(createHash('sha256').update(raw).digest('hex')!==batch.sha256)throw new Error('Workshop source checksum mismatch.');
  pack.draft={label:batch.label,data:validate(JSON.parse(raw),pack)};
  engine.loadData(pack.draft.data);
  const { _moveWorkshop, ...gameplay }=pack.draft.data;
  if(!isDeepStrictEqual(gameplay,engine.data()))throw new Error('Workshop draft changed during core import.');
}
const bundle=await build({entryPoints:[path('web/workbench/app.mjs')],bundle:true,format:'iife',write:false,minify:true,target:'es2022'});
const sourceCss=await readFile(path('web/workbench/style.css'),'utf8');
let css=sourceCss;
const fonts=[];
for(const [tag,file] of [['BARLOW_REGULAR','BarlowCondensed.woff2'],['BARLOW_SEMIBOLD','BarlowCondensedSemibold.woff2']]){
  const bytes=await readFile(path('godot/Content/Fonts/'+file));fonts.push({tag,bytes});
  css=css.replace(tag,'data:font/woff2;base64,'+bytes.toString('base64'));
}
const template=await readFile(path('web/workbench/index.html'),'utf8');
const license=await readFile(path('godot/Content/Fonts/Barlow-LICENSE.txt'),'utf8');
const script='globalThis.FIGHT_WORKSHOP_DATA='+JSON.stringify(pack)+';'+bundle.outputFiles[0].text;
const html=template.replace('<!--WORKSHOP_STYLES-->',()=>'<style>'+css+'</style>')
  .replace('<!--WORKSHOP_SCRIPT-->',()=>'<script>'+script.replace(/<\/script/gi,'<\\/script')+'</script>')
  .replace('<!--FONT_LICENSE-->',()=>`<!-- Bundled Barlow font license:\n${license.replace(/--/g,'—')}\n-->`);
await writeFile(path('build/FightGuild-Move-Workshop.html'),html);
await writeFile(path('build/workbench-pack.json'),JSON.stringify({...pack,images:{}}));
console.log(`Built standalone Move Workshop: ${(Buffer.byteLength(html)/1024/1024).toFixed(1)} MiB, ${files.length} embedded sprite sheets, plain-JS combat preview, no runtime requests or WebAssembly.`);

// The hosted/portable folder loads only the artwork actually shown. Content
// hashes keep cached assets safe across updates, while index.html stays small.
// Classic scripts (not modules or fetch) also work when opening index.html locally.
await rm(path('build/move-workshop'),{recursive:true,force:true});
await mkdir(path('build/move-workshop/assets'),{recursive:true});
async function asset(content,extension){
  const name=createHash('sha256').update(content).digest('hex')+'.'+extension;
  await writeFile(path('build/move-workshop/assets/'+name),content);return 'assets/'+name;
}
const linkedImages={};
for(const [file,encoded] of Object.entries(images))linkedImages[file]=await asset(Buffer.from(encoded.split(',')[1],'base64'),'webp');
const linkedPack={...pack,images:linkedImages};
const dataScript=await asset('globalThis.FIGHT_WORKSHOP_DATA='+JSON.stringify(linkedPack)+';','js');
const appScript=await asset(bundle.outputFiles[0].text,'js');
let linkedCss=sourceCss;
for(const {tag,bytes} of fonts)linkedCss=linkedCss.replace(tag,(await asset(bytes,'woff2')).slice('assets/'.length));
const stylesheet=await asset(linkedCss,'css');
const linkedHtml=template.replace('<!--WORKSHOP_REVIEWS-->', '<p>Animation reviews: <a href="smoke-motion-review.html">Smoke · specials &amp; attack audit</a> · <a href="shark-motion-review.html">Shark · full kit &amp; Drive</a> · <a href="fillet-motion-review.html">Fillet · animation audit</a></p><p><a href="FightGuild-moves.json" download>Download the shipped move data</a>. Export your current draft before importing this file.</p>').replace('<!--WORKSHOP_STYLES-->',()=>`<link rel="stylesheet" href="${stylesheet}">`)
  .replace('<!--WORKSHOP_SCRIPT-->',()=>`<script defer src="${dataScript}"></script><script defer src="${appScript}"></script>`)
  .replace('<!--FONT_LICENSE-->',()=>`<!-- Bundled Barlow font license:\n${license.replace(/--/g,'—')}\n-->`)
  .replace('The page works offline without installing anything. It makes no network requests.',
    'The website loads the editor and artwork from this site. Your edits and pose photos stay in this browser; they are not uploaded. The extracted ZIP also works offline without installing anything.');
await writeFile(path('build/move-workshop/index.html'),linkedHtml);
await writeFile(path('build/move-workshop/fillet-motion-review.html'),await buildFilletMotionReview({art:manifest.fighters[5],roster:manifest.fighters,images:linkedImages,engine}));
await writeFile(path('build/move-workshop/fillet-animation-audit-60fps.mp4'),await readFile(path('art/characters/fillet-v1/production/guide-audit-v1/previews/Fillet-Animation-Audit-60fps.mp4')));
await writeFile(path('build/Fillet-Attack-Timing.html'),await buildFilletMotionReview({art:manifest.fighters[5],roster:manifest.fighters,images,engine}));
await writeFile(path('build/move-workshop/shark-motion-review.html'),await buildSharkMotionReview({art:manifest.fighters[4],roster:manifest.fighters,images:linkedImages,engine}));
await writeFile(path('build/move-workshop/smoke-motion-review.html'),await buildSmokeMotionReview({pack,images:linkedImages,engine}));
await writeFile(path('build/move-workshop/smoke-specials-60fps.mp4'),await readFile(path('art/characters/smoke-specials-v3/previews/Smoke-Specials-Before-After-60fps.mp4')));
await writeFile(path('build/move-workshop/.nojekyll'),'');
await writeFile(path('build/move-workshop/FightGuild-moves.json'),JSON.stringify(pack.draft?.data??pack.defaults,null,2)+'\n');
await writeFile(path('build/move-workshop/START_HERE.txt'),`Fight Guild - Move Workshop\n\nExtract this whole folder, then open index.html in Chrome or Edge.\nKeep the assets folder beside index.html. No installation or server is needed.\n\nDownload JSON before closing to keep a portable backup of edits, notes and photos.\nDrafts stay in this browser; they do not sync between PCs or with the old HTML.\nUse Import JSON to carry a saved draft into this version.\nFightGuild-moves.json contains the shipped project draft; importing it replaces\nthe open draft, so download your edits before doing so.\n`);
const sourceCommit=execFileSync('git',['rev-parse','HEAD'],{cwd:path('.'),encoding:'utf8'}).trim();
await writeFile(path('build/move-workshop/version.json'),JSON.stringify({sourceCommit,schema:defaults.schema,artSheets:files.length,draft:pack.draft?.label??null},null,2)+'\n');
execFileSync('python',[path('scripts/package-workshop.py')],{stdio:'inherit'});
console.log(`Built hosted Move Workshop: ${(Buffer.byteLength(linkedHtml)/1024).toFixed(1)} KiB HTML, artwork loaded on demand, cached assets, local JSON import/export.`);
