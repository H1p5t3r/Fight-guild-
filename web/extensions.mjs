import {LINE_DEFAULTS} from './line-drive.mjs';
import {LAYOUT,DEFAULT_ART,LEGACY_FILLET} from './extension-layout.mjs';
export const ACTION_EXTENSION_FIELDS=714,CHARACTER_EXTENSION_FIELDS=947;
export const REGIONS=['legs','torsoArms','head','extension'];
const names=['normal','special','follow','bleed'];
// Keep these bounds aligned with core/extension_tables.inc. Validate before a
// draft changes, rather than relying on the preview to reject bad settings.
export function parameterRange(name,character=false){
  if(name==='policy')return [1,1];
  if(character)return ({bleedDuration:[1,3600],bleedInterval:[1,600],bleedCap:[0,999],halfWidth:[1,10000],standingHeight:[1,50000],crouchingHeight:[1,50000],walkStride:[1,50000],runStride:[1,50000],backdashLock:[0,120]})[name]||[0,50000];
  if(/^(ground|air)(Left|Bottom|Right|Top)$/.test(name))return [-1000000,1000000];
  return ({contactKind:[0,3],captureFreeze:[0,60],releaseFreeze:[0,60],pairTicks:[0,180],ownerRecovery:[0,120],victimRecovery:[0,120],throwGrace:[0,30],techTicks:[0,30],pairTrack:[0,3],groundedLift:[0,1],stopAtBody:[0,1]})[name]||[0,50000];
}
const record=v=>v!==null&&typeof v==='object'&&!Array.isArray(v);
const fail=message=>{throw new Error(`Extended combat data: ${message}`);};
const int=v=>{if(!Number.isInteger(v)||v< -1000000||v>1000000)fail('use bounded whole numbers for geometry and clocks.');return v;};
const keys=(obj,allowed,context)=>{if(!record(obj)||Object.keys(obj).some(k=>!allowed.includes(k)))fail(`unknown or malformed ${context}; the open draft has not changed.`);};
function box(b){if(!Array.isArray(b)||b.length!==4||b.some(v=>!Number.isInteger(v)||Math.abs(v)>1000000)||b[0]>=b[2]||b[1]>=b[3])fail('a box needs left < right and bottom < top.');return b;}
function body(b){keys(b,REGIONS,'body regions');return [REGIONS.reduce((n,r,i)=>n+(r in b?1<<i:0),0),...REGIONS.flatMap(r=>r in b?box(b[r]):[0,0,0,0])];}
function readBody(v){return Object.fromEntries(REGIONS.flatMap((r,i)=>v[0]&(1<<i)?[[r,v.slice(1+i*4,5+i*4)]]:[]));}
export function packExtension(ext,character=false){
  if(ext===undefined)return Array(character?947:714).fill(0);
  const allowed=character?['version','params','profiles','pairTracks','art']:['version','params','routes','hurtboxes','pushboxes','rootTrack','verticalRootKeys','art'];
  keys(ext,allowed,'extension fields');if(ext.version!==1)fail('unsupported extension version.');
  const paramNames=character?LAYOUT.characterParams:LAYOUT.actionParams;
  keys(ext.params,paramNames,'parameters');const out=paramNames.map(k=>int(ext.params[k]));
  if(out[0]!==1)fail('only the explicit v1 policy is supported; remove the extension to use legacy behavior.');
  for(const name of paramNames){const [min,max]=parameterRange(name,character);if(ext.params[name]<min||ext.params[name]>max)fail(`${name}: use a value from ${min} to ${max}.`);}
  if(character){if(ext.params.airTop<=ext.params.airBottom)fail('air push top must be above its bottom.');}
  else{for(const prefix of ['ground','air'])box(['Left','Bottom','Right','Top'].map(k=>ext.params[prefix+k]));if(ext.params.contactKind&&ext.params.pairTicks<1)fail('a paired capture needs at least one paired tick.');}
  if(ext.art!==undefined&&!record(ext.art))fail('art metadata must be an object.');
  if(character){
    keys(ext.profiles,LAYOUT.profiles,'collision profiles');
    for(const name of LAYOUT.profiles)out.push(...body(ext.profiles[name]));
    if(!Array.isArray(ext.pairTracks)||ext.pairTracks.length!==4)fail('four pair tracks are required.');
    for(const track of ext.pairTracks){
      if(!Array.isArray(track)||track.length<2||track.length>8)fail('pair tracks need 2–8 keys.');
      out.push(track.length);let previous=-1;
      for(const key of track){keys(key,['tick','owner','victim'],'pair key');int(key.tick);if(key.tick<=previous||key.tick>180||(previous===-1&&key.tick!==0))fail('pair ticks must increase from C0.');previous=key.tick;
        if(key.owner?.length!==2||key.victim?.length!==2)fail('pair roots need x and y.');out.push(key.tick,...key.owner.map(int),...key.victim.map(int));}
      out.push(...Array((8-track.length)*5).fill(0));
    }
  }else{
    keys(ext.routes,names,'cancel routes');
    for(const name of names){let lo=0,hi=0;const route=ext.routes[name];
      if(!Array.isArray(route)||new Set(route).size!==route.length)fail('named routes must be unique move slots.');
      for(const slot of route){if(!Number.isInteger(slot)||slot<0||slot>=47)fail('unknown move in cancel route.');if(slot<32)lo|=1<<slot;else hi|=1<<(slot-32);}out.push(lo,hi);}
    for(const [name,max,width,fields,convert] of [
      ['hurtboxes',32,18,['frame','boxes'],k=>[k.frame,...body(k.boxes)]],
      ['pushboxes',8,5,['frame','box'],k=>[k.frame,...box(k.box)]],
      ['rootTrack',8,5,['first','last','dx','dy','collision'],k=>[k.first,k.last,k.dx,k.dy,k.collision].map(int)],
      ['verticalRootKeys',8,2,['frame','y'],k=>[k.frame,int(k.y)]]]){
      const track=ext[name];if(!Array.isArray(track)||track.length>max)fail(`${name}: too many keys.`);
      out.push(track.length);let previous=0;
      for(const key of track){keys(key,fields,name);const frame=int(key.frame??key.first);if(frame<=previous||frame>420||(!previous&&name!=='rootTrack'&&frame!==1))fail(`${name}: frames must increase from 1.`);previous=frame;if(name==='rootTrack'&&(key.last<key.first||key.last>420||key.collision<0||key.collision>2))fail('root segments need a valid end frame and collision mode.');out.push(...convert(key));}
      out.push(...Array((max-track.length)*width).fill(0));
    }
  }
  return out;
}
export function unpackExtension(v,character=false,art){
  if(!v[0])return undefined;
  let at=0;const take=n=>{const r=v.slice(at,at+n);at+=n;return r;};
  const ext={version:1,params:Object.fromEntries((character?LAYOUT.characterParams:LAYOUT.actionParams).map(k=>[k,v[at++]]))};
  if(character){
    ext.profiles=Object.fromEntries(LAYOUT.profiles.map(name=>[name,readBody(take(17))]));
    ext.pairTracks=Array.from({length:4},()=>{const n=v[at++],r=Array.from({length:8},()=>{const k=take(5);return {tick:k[0],owner:k.slice(1,3),victim:k.slice(3)};});return r.slice(0,n);});
  }else{
    ext.routes=Object.fromEntries(names.map(name=>{const [lo,hi]=take(2);return [name,Array.from({length:47},(_,i)=>i).filter(i=>(i<32?lo&(1<<i):hi&(1<<(i-32))))];}));
    for(const [name,max,width,convert] of [
      ['hurtboxes',32,18,k=>({frame:k[0],boxes:readBody(k.slice(1))})],['pushboxes',8,5,k=>({frame:k[0],box:k.slice(1)})],
      ['rootTrack',8,5,k=>Object.fromEntries(['first','last','dx','dy','collision'].map((name,i)=>[name,k[i]]))],['verticalRootKeys',8,2,k=>({frame:k[0],y:k[1]})]]){
      const count=v[at++];ext[name]=Array.from({length:max},()=>convert(take(width))).slice(0,count);
    }
  }
  if(art!==undefined)ext.art=structuredClone(art);return ext;
}
export function upgradeExtensions(data,defaults){
  if(data?.schema!==22||data.coreVersion!==22)return data;
  const next=structuredClone(data);
  if(next.characters?.length!==6)fail('six characters are required.');
  for(let c=0;c<6;++c){const character=next.characters[c];if(character.moves?.length!==45)fail('version 22 requires 45 stable slots.');
    // Never silently activate a new kit, even when migrating an old Fillet save.
    if(character.extensions!==undefined||character.moves.some(m=>m.extensions!==undefined))fail('version 22 cannot contain version 23 extensions.');
    character.moves.push(...structuredClone(defaults.characters[c].moves.slice(45)).map(m=>{delete m.extensions;return {...m,enabled:0};}));}
  next.schema=next.coreVersion=23;return next;
}
export function defaultExtensionArt(c,m=-1){return DEFAULT_ART[c]?.[m<0?'character':m];}
export function extensionBody(move,frame){const track=move.extensions?.hurtboxes;if(!track?.length)return null;return track.findLast(k=>k.frame<=frame)?.boxes??null;}
export {LAYOUT};

export function migrationDefaults(defaults){const next=structuredClone(defaults);next.characters[5]=structuredClone(LEGACY_FILLET);if(defaults.schema>=24)for(const m of next.characters[5].moves)Object.assign(m,LINE_DEFAULTS);for(const c of next.characters){c.moves=c.moves.slice(0,45);delete c.extensions;for(const m of c.moves)delete m.extensions;}return next;}
