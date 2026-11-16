import {FIELDS, MOVE_IDS, CHARACTERS} from '../engine.mjs';
import {SPECS, ART_FIELDS} from './specs.mjs';
import {validateReferences,MAX_REFERENCE_TOTAL,MAX_IMPORT_BYTES,REFERENCE_PHASES} from './references.mjs';
export {FIELDS,MOVE_IDS,CHARACTERS};
export const clone = value => structuredClone(value);
export const META = '_moveWorkshop';
const record = value => value !== null && typeof value === 'object' && !Array.isArray(value);
function integer(value, limit, name) {
  if(!Number.isInteger(value)||value<limit.min||value>limit.max) throw new Error(`${name}: use a whole number from ${limit.min} to ${limit.max}.`);
}
export function validate(data, pack) {
  if(!record(data)||data.schema!==pack.defaults.schema||data.coreVersion!==pack.defaults.coreVersion)
    throw new Error('This editor needs a current Fight Guild move export (version 12). Your open draft has not changed.');
  if(!Array.isArray(data.characters)||data.characters.length!==CHARACTERS.length) throw new Error('The file must contain all six fighters.');
  for(const [group,limits] of Object.entries(pack.limits.rules)) {
    if(!record(data[group])) throw new Error(`Missing ${group}.`);
    for(const [key,range] of Object.entries(limits)) integer(data[group][key],range,`${group} / ${key}`);
  }
  data.characters.forEach((c,i)=>{
    if(!record(c)||c.name!==CHARACTERS[i]||!Array.isArray(c.moves)||c.moves.length!==MOVE_IDS.length) throw new Error(`Incomplete or reordered move list for ${CHARACTERS[i]}.`);
    if(!record(c.movement)) throw new Error(`Missing movement profile for ${c.name}.`);
    for(const [key,limit] of Object.entries(pack.limits.movement[i])) integer(c.movement[key],limit,`${c.name} / ${key}`);
    c.moves.forEach((move,j)=>{
      if(!record(move)||move.id!==MOVE_IDS[j]) throw new Error(`Move slot ${MOVE_IDS[j]} is missing or reordered.`);
      FIELDS.forEach(key=>{
        integer(move[key],pack.limits.moves[i][key],`${c.name} ${move.id} / ${SPECS[key].label}`);
        if(key==='motion'&&![0,214,236,623].includes(move[key])) throw new Error(`${c.name} ${move.id}: motion must be 0, 214, 236 or 623.`);
      });
    });
  });
  if(data[META]!==undefined) {
    if(!record(data[META])||data[META].version!==1||!record(data[META].notes)) throw new Error('Artwork notes are not in the supported workshop format.');
    let referenceBytes=0;
    for(const notes of Object.values(data[META].notes)) {
      if(!record(notes)) throw new Error('Malformed artwork notes.');
      for(const [key,,,max] of ART_FIELDS) if(notes[key]!==undefined&&(typeof notes[key]!=='string'||notes[key].length>max)) throw new Error(`Artwork note ${key} is too long or is not text.`);
      if(notes.references!==undefined)referenceBytes+=validateReferences(notes.references);
    }
    if(referenceBytes>MAX_REFERENCE_TOTAL)throw new Error('This draft has reached its 12 MB pose-reference allowance. Remove a reference before adding another.');
  }
  if(new TextEncoder().encode(JSON.stringify(data,null,2)).byteLength>MAX_IMPORT_BYTES)throw new Error('The move file must fit within 32 MB.');
  return data;
}
export function parseField(key, input, limit) {
  const spec=SPECS[key];
  if(String(input).trim()==='') throw new Error(`${spec.label} needs a value.`);
  const number=Number(input),raw=number*spec.scale,rounded=Math.round(raw);
  if(!Number.isFinite(raw)||Math.abs(raw-rounded)>1e-6||rounded<limit.min||rounded>limit.max)
    throw new Error(`${spec.label}: ${limit.min/spec.scale}–${limit.max/spec.scale}${spec.unit?' '+spec.unit:''}${spec.scale===1?'; whole numbers only.':'; up to two decimal places.'}`);
  return rounded;
}
export const totalFrames=m=>m.startup-1+m.active+m.recovery;
export const blockAdvantage=m=>m.blockstun-(m.active-1+m.recovery);
export function phaseAt(m,frame) {return frame<m.startup?'windup':frame<m.startup+m.active?'active':'recovery';}
export function inputName(m) {
  const button=m.category===4?'P+K':['P','K','S','Hs','D'][m.button];
  return `${m.air?'j.':''}${m.motion||m.direction}${button}`;
}
export function geometryWarnings(m) {
  const notes=[];
  if(m.hitboxBack>=m.reach) notes.push('The back edge is beyond the front edge. The game sorts the edges; check that this is intentional.');
  for(const prefix of ['normal','special','jump','follow']) if(m[`${prefix}CancelEnd`]&&m[`${prefix}CancelEnd`]<m[`${prefix}CancelStart`]) notes.push(`${prefix==='follow'?'Follow-up':prefix} cancel window closes before it opens.`);
  if(m.hitAngle) notes.push('Hook preview shows the travel path. The game uses moving spear hitboxes; the rope does not hit.');
  return notes;
}
export class Workshop {
  constructor(pack,data=pack.defaults) {
    this.pack=pack;this.data=clone(validate(data,pack));this.undoStack=[];this.redoStack=[];
  }
  move(c,m){return this.data.characters[c].moves[m];}
  key(c,m){return `${CHARACTERS[c]}/${MOVE_IDS[m]}`;}
  note(c,m){return this.data[META]?.notes?.[this.key(c,m)]||{};}
  snapshot(){return clone(this.data);}
  remember(before,group='') {
    if(JSON.stringify(before)===JSON.stringify(this.data))return false;
    const previous=this.undoStack.at(-1),now=Date.now();
    if(!group||!previous||previous.group!==group||now-previous.time>850)this.undoStack.push({data:before,group,time:now});
    else previous.time=now;
    if(this.undoStack.length>40)this.undoStack.shift();
    this.redoStack=[];return true;
  }
  change(c,m,key,value){
    const before=this.snapshot();
    this.move(c,m)[key]=value;
    try {validate(this.data,this.pack);} catch(error){this.data=before;throw error;}
    return this.remember(before,`${c}/${m}/${key}`);
  }
  setNote(c,m,key,value,group=`note/${c}/${m}/${key}`){
    const before=this.snapshot();
    this.data[META]??={version:1,notes:{}};
    this.data[META].notes[this.key(c,m)]??={};
    this.data[META].notes[this.key(c,m)][key]=value;
    try {validate(this.data,this.pack);} catch(error){this.data=before;throw error;}
    return this.remember(before,group);
  }
  addReferences(c,m,references){return this.setNote(c,m,'references',[...(this.note(c,m).references||[]),...clone(references)],'');}
  editReference(c,m,id,key,value){
    if(!['phase','caption'].includes(key))throw new Error('Unsupported reference edit.');
    const refs=clone(this.note(c,m).references||[]),ref=refs.find(r=>r.id===id);
    if(!ref)throw new Error('This pose reference is no longer in the draft.');
    ref[key]=value;return this.setNote(c,m,'references',refs,`reference/${c}/${m}/${id}/${key}`);
  }
  removeReference(c,m,id){return this.setNote(c,m,'references',(this.note(c,m).references||[]).filter(r=>r.id!==id),'');}
  import(data){const next=clone(validate(data,this.pack)),before=this.snapshot();this.data=next;this.remember(before);}
  resetMove(c,m){const before=this.snapshot();this.data.characters[c].moves[m]=clone(this.pack.defaults.characters[c].moves[m]);this.remember(before);}
  undo(){if(!this.undoStack.length)return false;const item=this.undoStack.pop();this.redoStack.push({data:this.snapshot()});this.data=item.data;return true;}
  redo(){if(!this.redoStack.length)return false;const item=this.redoStack.pop();this.undoStack.push({data:this.snapshot(),group:'',time:0});this.data=item.data;return true;}
  changed(c,m){return FIELDS.some(k=>this.move(c,m)[k]!==this.pack.defaults.characters[c].moves[m][k])||!!this.note(c,m).references?.length||Object.values(this.note(c,m)).some(v=>typeof v==='string'&&v.trim());}
  changes(){return this.data.characters.flatMap((c,i)=>c.moves.map((_,m)=>({c:i,m}))).filter(p=>this.changed(p.c,p.m));}
  export(){return JSON.stringify(validate(this.data,this.pack),null,2);}
  brief(){
    const lines=['# Fight Guild — move and animation brief','','Export the companion JSON for authoritative gameplay values.',''];
    for(const {c,m} of this.changes()) {
      const move=this.move(c,m),note=this.note(c,m);
      lines.push(`## ${CHARACTERS[c]} · ${move.id}${note.label?' — '+note.label:''}`,'',`Input: ${inputName(move)}. Startup ${move.startup}f / active ${move.active}f / recovery ${move.recovery}f. Damage ${move.damage}. First-active block advantage ${blockAdvantage(move)>=0?'+':''}${blockAdvantage(move)}f.`,
        `Hitbox: back ${move.hitboxBack/100}px, front ${move.reach/100}px, bottom ${move.bottom/100}px, height ${move.height/100}px. Knockdown: ${['none','soft','hard'][move.knockdown]}.`,
        `Ground / air / block push: ${move.pushback/100} / ${move.airPushback/100} / ${move.blockPushback/100}px. Ground / air launch: ${move.launch/100} / ${move.airLaunch/100}px per frame.`, '');
      for(const [key,label] of ART_FIELDS.slice(1)) if(note[key]?.trim())lines.push(`**${label}**`,note[key].trim(),'');
      if(note.references?.length){
        lines.push('**Pose references**','Image files are embedded in the companion JSON.','');
        for(const ref of note.references)lines.push(`- ${REFERENCE_PHASES.find(([id])=>id===ref.phase)[1]} · ${ref.name}${ref.caption?' — '+ref.caption:''}`);
        lines.push('');
      }
    }
    lines.push('Art rules: use windup and active poses first; weapons have no hurtboxes; use no more than four body hurtboxes per pose.');
    return lines.join('\n');
  }
}

// Same local strike geometry as Simulation::attack_box, in integer core units.
// Preview origin/pose can differ from a live match; the authored rectangle does not.
export function attackBoxes(m,frame,push) {
  if(m.category===4)return [[0,0,push.halfWidth+m.throwRange,push.standingHeight]];
  if(!m.hitAngle)return [[Math.min(m.hitboxBack,m.reach),m.bottom,Math.max(m.hitboxBack,m.reach),m.bottom+m.height]];
  const age=Math.max(0,Math.min(m.active-1,frame-m.startup));
  const length=Math.min(8000,Math.abs(m.reach-m.hitboxBack)),travel=Math.max(0,m.reach-m.hitboxBack-length);
  const extension=Math.trunc(travel*age/Math.max(1,m.active-1));
  const back=m.hitboxBack+extension,tip=back+length,bottom=m.bottom+m.hitAngle*extension,top=m.bottom+m.hitAngle*(extension+length);
  return Array.from({length:8},(_,segment)=>{
    const a=back+Math.trunc((tip-back)*segment/8),b=back+Math.trunc((tip-back)*(segment+1)/8);
    const c=bottom+Math.trunc((top-bottom)*segment/8),d=bottom+Math.trunc((top-bottom)*(segment+1)/8);
    return [Math.min(a,b),Math.min(c,d)-Math.trunc(m.height/2),Math.max(a,b),Math.max(c,d)+Math.trunc((m.height+1)/2)];
  });
}
