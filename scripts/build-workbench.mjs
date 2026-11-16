import {build} from 'esbuild';
import {chromium} from 'playwright';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {existsSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {Engine,FIELDS,MOVEMENT_FIELDS} from '../web/engine.mjs';
import {SPECS} from '../web/workbench/specs.mjs';
const root=new URL('../',import.meta.url), path=p=>fileURLToPath(new URL(p,root));
const wasm=await readFile(path('web/generated/fight.wasm'));
const {instance}=await WebAssembly.instantiate(wasm),engine=new Engine(instance),defaults=engine.data();
if(defaults.schema!==13||defaults.coreVersion!==13) throw new Error('Rebuild the current combat core before packaging the workshop.');
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
const phases=['active','windup','signature_active','signature_windup'];
const art=manifest.fighters.map(f=>Object.fromEntries(['name',...phases].filter(p=>f[p]).map(p=>[p,f[p]])));
const files=[...new Set(art.flatMap(f=>phases.filter(p=>f[p]).map(p=>f[p].file)))];
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
const regions=['legs','torsoArms','head','extension'],posePhases={active:0,windup:1,signature_windup:3,signature_active:4};
const hurtPoses=art.map((fighter,c)=>Object.fromEntries(Object.entries(posePhases).filter(([phase])=>fighter[phase]).map(([phase,p])=>[phase,fighter[phase].frames.map((_,pose)=>Object.fromEntries(Array.from({length:engine.api.fg_pose_box_count(c,p,pose)},(_,n)=>[regions[n],Array.from({length:4},(_,edge)=>engine.api.fg_pose_box_get(c,p,pose,n,edge))])))])));
const pack={format:1,defaults,limits,art,collisions:collisions.fighters,hurtPoses,images};
const bundle=await build({entryPoints:[path('web/workbench/app.mjs')],bundle:true,format:'iife',write:false,minify:true,target:'es2022'});
let css=await readFile(path('web/workbench/style.css'),'utf8');
for(const [tag,file] of [['BARLOW_REGULAR','BarlowCondensed.woff2'],['BARLOW_SEMIBOLD','BarlowCondensedSemibold.woff2']])css=css.replace(tag,'data:font/woff2;base64,'+(await readFile(path('godot/Content/Fonts/'+file))).toString('base64'));
const template=await readFile(path('web/workbench/index.html'),'utf8');
const license=await readFile(path('godot/Content/Fonts/Barlow-LICENSE.txt'),'utf8');
const script='globalThis.FIGHT_WORKSHOP_DATA='+JSON.stringify(pack)+';'+bundle.outputFiles[0].text;
const html=template.replace('<!--WORKSHOP_STYLES-->',()=>'<style>'+css+'</style>')
  .replace('<!--WORKSHOP_SCRIPT-->',()=>'<script>'+script.replace(/<\/script/gi,'<\\/script')+'</script>')
  .replace('<!--FONT_LICENSE-->',()=>`<!-- Bundled Barlow font license:\n${license.replace(/--/g,'—')}\n-->`);
await mkdir(path('build/move-workshop'),{recursive:true});
await writeFile(path('build/FightGuild-Move-Workshop.html'),html);
await writeFile(path('build/move-workshop/index.html'),html);
await writeFile(path('build/workbench-pack.json'),JSON.stringify({...pack,images:{}}));
console.log(`Built standalone Move Workshop: ${(Buffer.byteLength(html)/1024/1024).toFixed(1)} MiB, ${files.length} embedded sprite sheets, no runtime requests or WebAssembly.`);
