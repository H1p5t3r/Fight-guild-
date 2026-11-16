import {upgradeHurtboxes} from './hurtboxes.mjs';
export const MAX_HIT_KEYS=32, MAX_HITBOXES=4, HIT_KEY_FIELDS=23, HIT_TRACK_FIELDS=738;
export const HIT_OVERRIDES=['damage','hitstun','blockstun','hitstop'];
const object=v=>v!==null&&typeof v==='object'&&!Array.isArray(v);
export const emptyHitTimeline=()=>({multiHit:false,keys:[]});
export function validateHitTimeline(track){
  if(!object(track)||typeof track.multiHit!=='boolean'||!Array.isArray(track.keys)||track.keys.length>MAX_HIT_KEYS)throw new Error('Hitbox timeline needs a multi-hit toggle and up to 32 keys.');
  let previous=0;
  for(const key of track.keys){
    if(!object(key)||!Number.isInteger(key.frame)||key.frame<=previous||key.frame>120||!Number.isInteger(key.hit)||key.hit<1||key.hit>32)throw new Error('Hitbox keys need unique increasing active frames (1–120) and hit numbers (1–32).');
    previous=key.frame;
    HIT_OVERRIDES.forEach((field,i)=>{if(!Number.isInteger(key[field])||key[field]<-1||key[field]>[1000,180,180,30][i])throw new Error(`${field}: use −1 to inherit, or a valid hit value.`);});
    if(key.boxes===null)continue;
    if(!Array.isArray(key.boxes)||key.boxes.length>MAX_HITBOXES)throw new Error('Use up to four hitboxes per key, or base geometry.');
    for(const b of key.boxes)if(!Array.isArray(b)||b.length!==4||b.some(v=>!Number.isInteger(v)||v< -50000||v>50000)||b[2]-b[0]<100||b[3]-b[1]<100)throw new Error('Hitbox edges must be within −500 to 500 px and each box at least 1×1 px.');
  }
  return track;
}
export const keyAt=(move,frame)=>move.category===4?undefined:move.hitboxTimeline?.keys.findLast(k=>k.frame<=frame);
export function makeHitKey(frame,source){return {frame,hit:source?.hit??1,boxes:structuredClone(source?.boxes??null),...Object.fromEntries(HIT_OVERRIDES.map(f=>[f,source?.[f]??-1]))};}
export function packHitKey(key){return [key.frame,key.hit,key.boxes===null?-1:key.boxes.length,...HIT_OVERRIDES.map(f=>key[f]),...Array.from({length:4},(_,i)=>key.boxes?.[i]||[0,0,0,0]).flat()];}
export function unpackHitKey(v){return {frame:v[0],hit:v[1],boxes:v[2]<0?null:Array.from({length:v[2]},(_,i)=>v.slice(7+i*4,11+i*4)),...Object.fromEntries(HIT_OVERRIDES.map((f,i)=>[f,v[3+i]]))};}
export function upgradeHitboxes(value){
  let data=upgradeHurtboxes(value);
  if(data?.schema===13&&data.coreVersion===13){
    data=structuredClone(data);data.schema=data.coreVersion=14;
    if(Array.isArray(data.characters))for(const c of data.characters)if(Array.isArray(c?.moves))for(const m of c.moves)if(object(m))m.hitboxTimeline??=emptyHitTimeline();
  }
  return data;
}
