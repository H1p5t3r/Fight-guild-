// Search ordinary input sequences in the shipped core. Never change move data,
// seed hitstun, teleport during a route, or count a reset as a combo.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {createCore,INPUT,manifest,data,wasm,sha256,directory,notation} from './combo-showcase-core.mjs';
const engine=await createCore();
const g=(p,k)=>engine.api.fg_get(p,k),snapshot=()=>engine.snapshot();
const dir=(n,f=1)=>{const x=(n-1)%3-1,y=Math.floor((n-1)/3)-1;return (x?(x*f>0?INPUT.right:INPUT.left):0)|(y>0?INPUT.up:y<0?INPUT.down:0);};
const out=directory;mkdirSync(out,{recursive:true});
const width=Number(process.env.COMBO_BEAM??24),depthLimit=Number(process.env.COMBO_DEPTH??8);
let trials=0;

function tick(node,input){
 input??=g(0,13)===0?dir(4,g(0,2)):0;
 const defend=node.hits?INPUT.down|dir(4,g(1,2)):0;
 engine.step(input,defend);node.inputs.push([input,defend]);
 const count=g(0,73),delta=count-node.contacts;
 if(delta<0)node.invalid=true; // A stage reset resets the counter; never splice combos across it.
 if(delta){
  if(g(0,10)===2||g(0,9)!==node.hits+delta)node.invalid=true;
  node.hits+=delta;node.contacts=count;
 }
 node.damage=(node.healthBase??1000)-g(1,3);
 if(g(-1,4))node.ended=true; // Stop at the break hit, including its freeze.
 if(node.hits&&!g(-1,2)&&!g(-1,28)&&!g(-1,22)){
  const reaction=g(1,31);
  if(g(-1,4)||g(-1,3)>=0||reaction===2||reaction===3||(!g(1,6)&&reaction===0))node.ended=true;
 }
 if(node.inputs.length>650)node.ended=true;
 return !node.invalid&&!node.ended;
}
const copy=n=>({...n,inputs:[...n.inputs],route:[...n.route]});
function command(base,slot,moves){
 engine.restore(base.state);const n=copy(base),m=moves[slot];
 const startSerial=engine.attackSerial();let started=false;
 if(!m.air&&g(0,1)>0)return null;
 if(m.air&&g(0,1)===0){
  if(!tick(n,INPUT.up|dir(6,g(0,2))))return null;
  for(let j=0;j<8&&g(0,1)===0;j++)if(!tick(n,dir(6,g(0,2))))return null;
  if(g(0,1)===0)return null;
 }
 // A released button is a fresh press, including repeated punches.
 if(g(0,12)&(INPUT.P|INPUT.K|INPUT.S|INPUT.Hs|INPUT.D))if(!tick(n))return null;
 const charged=slot===43||slot===44;
 const source=charged?moves[slot===43?11:13]:slot===32?moves[2]:m;
 const commands=source.motion?String(source.motion).split('').map(Number):[g(0,13)===0&&source.direction===5?4:source.direction];
 const facing=g(0,2),button=INPUT.P<<source.button;
 const began=n.inputs.length;
 for(let j=0;j<commands.length;j++){
  if(!tick(n,dir(commands[j],facing)|(j===commands.length-1?button:0))&&!n.hits)return null;
  if(n.invalid||n.ended)return null;
 }
 for(let j=0;j<(charged?80:data.inputRules.buttonBuffer+2);j++){
  if(engine.attackSerial()!==startSerial){
   if(g(0,4)===slot){started=true;break;}
   if(!charged||g(0,4)!==(slot===43?11:13))return null;
  }
  if(!tick(n,charged?dir(source.direction,facing)|button:undefined))return null;
 }
 if(!started)return null;
 n.route.push({slot,inputFrame:began+1,startFrame:n.inputs.length});
 // Non-damaging movement/pull can connect two damaging actions. Never count
 // them as extra hits; the defender's real actionable state still ends a route.
 if(m.mechanic===5||m.mechanic===4){
  for(let j=0;j<70&&!n.invalid&&!n.ended;j++){
   if(m.mechanic===5&&g(0,5)>=m.startup||m.mechanic===4&&g(1,102)>0)break;
   tick(n);
  }
  if(n.invalid||n.ended)return null;
  n.state=snapshot();return n;
 }
 const before=base.contacts;
 for(let j=0;j<240&&n.contacts===before&&!n.invalid&&!n.ended;j++)tick(n);
 if(n.invalid||n.contacts===before)return null;
 n.state=snapshot();return n;
}
function attempt(parent,slot,delay,moves){
 trials++;engine.restore(parent.state);const waiting=copy(parent);
 for(let j=0;j<delay;){if(!g(-1,2))j++;if(!tick(waiting))return null;}
 for(let j=0;j<55;j++){
  waiting.state=snapshot();
  if(!g(-1,2)){
   const n=command(waiting,slot,moves);if(n)return n;
   engine.restore(waiting.state);
  }
  if(!tick(waiting))return null;
 }
 return null;
}
function finish(parent){
 engine.restore(parent.state);const n=copy(parent);
 for(let j=0;j<180&&!n.invalid&&!n.ended;j++)tick(n);
 n.state=snapshot();return n;
}
const compare=(a,b)=>b.damage-a.damage||b.hits-a.hits||a.inputs.length-b.inputs.length;
const selected=process.argv.slice(2);
const results=[];
for(const c of [5,2,4,3,1,0])for(const corner of [false,true]){
 const stance=c===3&&process.env.COMBO_STANCE==='1';
 const id=data.characters[c].name.toLowerCase()+'-'+(stance?'stance':corner?'corner':'midscreen');
 if(selected.length&&!selected.includes(id))continue;
 const target=c===4||c===2?5:4;
 engine.reset([c,target]);
 const root=corner?85000:42000,gap=6500,momentum=c===0?5000:0;
 engine.api.fg_preview_place(0,root,0,momentum);engine.api.fg_preview_place(1,root+gap,0,momentum);
 const initial={characters:[c,target],positions:[root,root+gap],momentum};
 if(stance){
  initial.setupInputs=[];
  const setup=a=>{engine.step(a,0);initial.setupInputs.push([a,0]);};
  setup(INPUT.D);for(let i=0;i<180;i++)setup(0);
  if(!g(0,81)||g(1,6)||g(1,31))throw new Error('Tapper failed to earn his starting stance');
  for(let i=0;i<90&&Math.abs(g(1,0)-g(0,0))>7500;i++)setup(dir(6,g(0,2)));
  for(let i=0;i<8;i++)setup(0);
  initial.baseHealth=g(1,3);initial.contactBase=g(0,73);
 }
 const start={state:snapshot(),inputs:[],route:[],hits:0,contacts:initial.contactBase??0,healthBase:initial.baseHealth??1000,damage:0,invalid:false,ended:false};
 const moves=data.characters[c].moves;
 if(c===0){for(let i=0;i<30;i++)tick(start,INPUT.left);start.state=snapshot();}
 const candidates=moves.flatMap((m,i)=>m.enabled&&(m.category!==4||m.actionType===8)&&(m.damage>0||m.mechanic===5||m.mechanic===4)?[i]:[]);
 const starters=stance?[35,36,37,38]:[32,3,7,11,...(process.env.COMBO_AIR==='1'?[19,20,21]:[]),...(c===4?[10]:[]),...(c===2?[43,44]:[])];
 let beam=starters.map(slot=>attempt(start,slot,0,moves)).filter(Boolean),best=[];
 for(let depth=1;depth<=depthLimit&&beam.length;depth++){
  const complete=beam.map(finish).filter(n=>!n.invalid&&n.hits>=2);
  const unique=new Map();
  for(const n of [...best,...complete].sort(compare)){
   const key=n.route.map(r=>r.slot).join(',');if(!unique.has(key))unique.set(key,n);
  }
  best=[...unique.values()].slice(0,12);
  console.log(`${id} depth ${depth}: ${best[0]?.damage??0} damage / ${best[0]?.hits??0} hits, ${trials} trials`);
  if(depth===depthLimit)break;
  const next=[];
  for(const n of beam)if(!n.ended)for(const slot of candidates)for(const delay of [0,3,7,12,18]){
   const child=attempt(n,slot,delay,moves);if(child)next.push(child);
  }
  const seen=new Set(),perRoute=new Map();beam=[];
  for(const n of next.sort(compare)){
   engine.restore(n.state);
   const route=n.route.map(r=>r.slot).join(',');if((perRoute.get(route)??0)>=2)continue;
   const key=[route,n.hits,Math.round(g(1,0)/200),Math.round(g(1,1)/200),g(0,5),g(1,6)].join('/');
   if(seen.has(key))continue;seen.add(key);beam.push(n);if(beam.length>=width)break;
   perRoute.set(route,(perRoute.get(route)??0)+1);
  }
 }
 const rows=best.map(n=>({route:n.route.map(r=>({...r,notation:notation(c,r.slot)})),damage:n.damage,hits:n.hits,inputs:n.inputs,frames:n.inputs.length,wallBreak:!!(()=>{engine.restore(n.state);return g(-1,4);})()}));
 const result={id,character:c,target,corner,initial,search:{beam:width,maxMoves:depthLimit,delaySamples:[0,3,7,12,18],trials},candidates:rows};
 writeFileSync(`${out}/${id}.json`,JSON.stringify(result,null,2)+'\n');results.push(result);
 console.log('BEST',id,rows.slice(0,3).map(r=>`${r.damage}/${r.hits}: ${r.route.map(a=>a.notation).join(' > ')}`).join('\n'));
 if(stance)break;
}
writeFileSync(`${out}/search-build.json`,JSON.stringify({schema:2,source:manifest,wasmSha256:sha256(wasm),configurationSha256:sha256(readFileSync(`${out}/configuration.bin`)),note:'Bounded beam search of real inputs on the native configuration. Defender guards after the first hit; resets, blocked contacts and broken combos are rejected. Results are high-damage routes found, not a proof of global optimality.'},null,2)+'\n');
