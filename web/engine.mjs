export const BUTTONS = ['P', 'K', 'S', 'Hs', 'D'];
export const MOVE_IDS = ['5P','5K','5S','5Hs','2P','2K','2S','2Hs','6P','6K','6S','6Hs','6D','5D','236P','236S','623Hs','j.P','j.K','j.S','j.Hs','j.D'];
export const CHARACTERS = ['Anvil', 'Hammer', 'Smoke', 'Tapper', 'Shark', 'Fillet'];
export const FIELDS = ['button','category','direction','motion','air','startup','active','recovery','damage','hitstun','blockstun','hitstop','pushback','reach','bottom','height','specialCancel','jumpCancel','whiffCancel','selfCancel','advance','simpleDirection','simpleButton','normalRoutes','commandRoutes','hitLevel','chipDamage','guardBreak','counterHitstun','counterHitstop','reversalEligible','hitboxBack'];
export const INPUT = { left:1,right:2,down:4,up:8,P:16,K:32,S:64,Hs:128,D:256,dash:512,simple:1024,faultless:2048 };
const RULES = ['buttonBuffer','motionWindow','motionGap'];
const MOMENTUM_RULES = ['movementGain','attackGain','blockedAttackGain','damageTakenGain','guardGain','specialGain','fdDrain','fdBlockCost','fdDamageCost','fdPushPercent'];
let compiled;
export async function loadEngine() {
  compiled ??= (globalThis.FIGHT_WASM
    ? Promise.resolve(Uint8Array.from(atob(globalThis.FIGHT_WASM), c=>c.charCodeAt(0)))
    : fetch('./generated/fight.wasm').then(r => {
    if(!r.ok) throw new Error('Combat core missing. Run npm run build, then reload.');
    return r.arrayBuffer();
  })).then(WebAssembly.compile);
  return new Engine(await WebAssembly.instantiate(await compiled));
}
export class Engine {
  constructor(instance) {
    this.api = instance.exports;
    this.api.fg_defaults();
    this.reset();
  }
  reset(characters=[0,1], simple=[false,false]) {
    this.api.fg_reset(...characters,...simple.map(Number));
  }
  step(a,b) { this.api.fg_step(a,b); }
  get frame() { return this.api.fg_get(-1,0); }
  get hash() { return this.api.fg_checksum() >>> 0; }
  snapshot() {
    return new Uint8Array(this.api.memory.buffer,this.api.fg_state_ptr(),this.api.fg_state_size()).slice();
  }
  restore(bytes) {
    if(!(bytes instanceof Uint8Array)||bytes.byteLength!==this.api.fg_state_size()) throw new Error('Invalid snapshot');
    new Uint8Array(this.api.memory.buffer,this.api.fg_state_ptr(),bytes.length).set(bytes);
  }
  state() {
    const keys=['x','y','facing','health','move','age','stun','guarding','contact','combo','event','lastMove','raw','character','simple','momentum','faultless','blockReaction','blockAge','blockAdvantage','guardBreak','throwInvulnerable','comboDisplay','comboTime','comboAge','hitNotice','hitNoticeTime','reversalTime','reversalInputAge','posePhase','poseIndex'];
    return {
      frame:this.frame, remaining:this.api.fg_get(-1,1), hitstop:this.api.fg_get(-1,2),winner:this.api.fg_get(-1,3),
      players:[0,1].map(p=>Object.fromEntries(keys.map((key,f)=>[key,this.api.fg_get(p,f)])))
    };
  }
  boxes(player,kind) {
    return Array.from({length:this.api.fg_box_count(player,kind)},(_,i)=>
      Array.from({length:4},(_,edge)=>this.api.fg_box_get(player,kind,i,edge)));
  }
  move(c,m) { return Object.fromEntries(FIELDS.map((key,f)=>[key,this.api.fg_move_get(c,m,f)])); }
  setMove(c,m,key,value) {
    if(!Number.isInteger(value)||!this.api.fg_move_set(c,m,FIELDS.indexOf(key),value)) throw new Error(`Invalid ${key}: ${value}`);
  }
  data() {
    return { schema:5, coreVersion:this.api.fg_version(),
      inputRules:Object.fromEntries(RULES.map((r,i)=>[r,this.api.fg_rule_get(i)])),
      momentumRules:Object.fromEntries(MOMENTUM_RULES.map((r,i)=>[r,this.api.fg_rule_get(i+3)])),
      characters:CHARACTERS.map((name,c)=>({name,moves:MOVE_IDS.map((id,m)=>({id,...this.move(c,m)}))})) };
  }
  loadData(data) {
    if(data?.schema===4&&data.coreVersion===4) { data=structuredClone(data); data.schema=data.coreVersion=5; for(const c of data.characters??[]) for(const m of c.moves??[]) m.hitboxBack=1200; }
    if(data?.schema!==5||data.coreVersion!==this.api.fg_version()||data.characters?.length!==CHARACTERS.length) throw new Error('Unsupported move-data format');
    const previous=this.data();
    const apply=d=>{
      RULES.forEach((r,i)=>{ if(!Number.isInteger(d.inputRules?.[r])||!this.api.fg_rule_set(i,d.inputRules[r])) throw new Error(`Invalid ${r}`); });
      MOMENTUM_RULES.forEach((r,i)=>{ if(!Number.isInteger(d.momentumRules?.[r])||!this.api.fg_rule_set(i+3,d.momentumRules[r])) throw new Error(`Invalid ${r}`); });
      d.characters.forEach((character,c)=>{
        if(character.name!==CHARACTERS[c]||character.moves?.length!==MOVE_IDS.length) throw new Error('Character move list does not match this build');
        character.moves.forEach((m,i)=>{
          if(m.id!==MOVE_IDS[i]) throw new Error(`Missing move ${MOVE_IDS[i]}`);
          FIELDS.forEach(key=>this.setMove(c,i,key,m[key]));
        });
      });
    };
    try { apply(data); } catch(error) { apply(previous); throw error; }
  }
  fingerprint() {
    let hash=2166136261;
    for(const c of JSON.stringify(this.data())) hash=Math.imul(hash^c.charCodeAt(0),16777619)>>>0;
    return `${this.api.fg_version()}-${(this.api.fg_collision_hash()>>>0).toString(16).padStart(8,'0')}-${hash.toString(16).padStart(8,'0')}`;
  }
}
