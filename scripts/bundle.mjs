import {build} from 'esbuild';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
const root=new URL('../',import.meta.url);
const result=await build({entryPoints:[new URL('web/app.mjs',root).pathname],bundle:true,format:'iife',write:false,minify:true,target:'es2022'});
const [template,css,wasm]=await Promise.all(['web/index.html','web/style.css','web/generated/fight.wasm'].map(p=>readFile(new URL(p,root))));
const script=`globalThis.FIGHT_STANDALONE=true;globalThis.FIGHT_WASM="${wasm.toString('base64')}";${result.outputFiles[0].text}`;
const html=template.toString().replace('<link rel="stylesheet" href="style.css">',()=>`<style>${css}</style>`)
  .replace('<script type="module" src="app.mjs"></script>',()=>`<script>${script.replace(/<\/script/gi,'<\\/script')}</script>`);
await mkdir(new URL('build/',root),{recursive:true});
await writeFile(new URL('build/FightGuild.html',root),html);
console.log(`Packaged build/FightGuild.html (${Math.round(Buffer.byteLength(html)/1024)} KB). Open in Chrome or Edge; no server needed for local play.`);
