export const BUTTONS = ['P', 'K', 'S', 'Hs', 'D'];
export const MOVE_IDS = ['5P','5K','5S','5Hs','2P','2K','2S','2Hs','6P','6K','6S','6Hs','6D','5D','236P','236S','623Hs','j.P','j.K','j.S','j.Hs','j.D','2D','4P+K','6P+K','236K','236S>6S','236S>2S','214S','j.214P','214S>P','j.214P>P'];
export const CHARACTERS = ['Anvil', 'Hammer', 'Smoke', 'Tapper', 'Shark', 'Fillet'];
export const FIELDS = ['button','category','direction','motion','air','startup','active','recovery','damage','hitstun','blockstun','hitstop','pushback','reach','bottom','height','specialCancel','jumpCancel','whiffCancel','selfCancel','advance','simpleDirection','simpleButton','normalRoutes','commandRoutes','hitLevel','chipDamage','guardBreak','counterHitstun','counterHitstop','reversalEligible','hitboxBack','airPushback','blockPushback','launch','airLaunch','knockdown','knockdownFrames','wakeupFrames','wallDamage','throwRange','enabled','artPose','followFrom','followFrom2','followHit','travelSpeed','inertiaPercent','pullFrames','pullGap','hitAngle',"normalCancelStart","normalCancelEnd","specialCancelStart","specialCancelEnd","jumpCancelStart","jumpCancelEnd","followCancelStart","followCancelEnd","cancelOn","starterProration","comboScaling","minimumDamage","landingRecovery","attackLevel","counterTier","counterVulnerable","counterFreezeFrames","counterSlowFrames"];
export const INPUT = { left:1,right:2,down:4,up:8,P:16,K:32,S:64,Hs:128,D:256,dash:512,simple:1024,faultless:2048 };
export const MOVEMENT_FIELDS = ['forwardStyle', 'walkSpeed', 'runSpeed', 'runAcceleration', 'stepSpeed', 'stepFrames', 'backSpeed', 'backFrames', 'attackFriction'];
const RULES = ['buttonBuffer','motionWindow','motionGap'];
const MOMENTUM_RULES = ['movementGain','attackGain','blockedAttackGain','damageTakenGain','guardGain','specialGain','fdDrain','fdBlockCost','fdDamageCost','fdPushPercent'];
const RECOVERY_RULES = ['gravityAfter','gravityStep','gravityCap','wallThreshold','wallRange','wallDecayDelay','wallDecay','wallSplatFrames','wallBreakFrames','wallBreakDamage','positiveFrames','positiveGainPercent','positiveRegen'];
const TUNING_RULES = ["fdAirDrain", "fdLevelCost", "cornerPushTransfer", "wallMidCap", "groundedWallPrime", "blockCarryover", "throwGraceFrames", "airLandingFrames", "repeatAfter", "repeatGravityStep"];
const JUMP_RULES = ['prejumpFrames', 'emptyLandingFrames'];
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
    this.defaultData=this.data();
    this.reset();
  }
  reset(characters=[5,4], simple=[false,false]) {
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
    const keys=['x','y','facing','health','move','age','stun','guarding','contact','combo','event','lastMove','raw','character','simple','momentum','faultless','blockReaction','blockAge','blockAdvantage','guardBreak','throwInvulnerable','comboDisplay','comboTime','comboAge','hitNotice','hitNoticeTime','reversalTime','reversalInputAge','posePhase','poseIndex','reaction','knockdown','recoveryTime','comboReceived','gravityPercent','wallDamage','wallSplatTime','positiveTime','vx','running','dashTicks','pullTime','pullOwner','weaponBackX','weaponBackY','weaponTipX','weaponTipY','weaponVisible','carryVx','carryTime',"landingTime","throwGrace","cancelMask","inputAge","lastDamage","damageScale","starterProration","comboScale","counterTier","repeatGravity","lastBaseDamage","prejumpTime","counterSlowTime","counterSlowHeld"];
    return {
      frame:this.frame, remaining:this.api.fg_get(-1,1), hitstop:this.api.fg_get(-1,2),winner:this.api.fg_get(-1,3),
      wallBreakTime:this.api.fg_get(-1,4),wallBreakActor:this.api.fg_get(-1,5),wallBreakSide:this.api.fg_get(-1,6),stage:this.api.fg_get(-1,7),wallBreakDuration:this.api.fg_get(-1,8),wallBreakX:[this.api.fg_get(-1,15),this.api.fg_get(-1,16)],wallBreakY:[this.api.fg_get(-1,17),this.api.fg_get(-1,18)],
      impactTime:this.api.fg_get(-1,9),impactDuration:this.api.fg_get(-1,10),impactActor:this.api.fg_get(-1,11),impactTier:this.api.fg_get(-1,12),impactX:this.api.fg_get(-1,13),impactY:this.api.fg_get(-1,14),
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
    return { schema:11, coreVersion:this.api.fg_version(),
      inputRules:Object.fromEntries(RULES.map((r,i)=>[r,this.api.fg_rule_get(i)])),
      momentumRules:Object.fromEntries(MOMENTUM_RULES.map((r,i)=>[r,this.api.fg_rule_get(i+3)])),
      recoveryRules:Object.fromEntries(RECOVERY_RULES.map((r,i)=>[r,this.api.fg_rule_get(i+13)])),
      tuningRules:Object.fromEntries(TUNING_RULES.map((r,i)=>[r,this.api.fg_rule_get(i+26)])),
      jumpRules:Object.fromEntries(JUMP_RULES.map((r,i)=>[r,this.api.fg_rule_get(i+36)])),
      characters:CHARACTERS.map((name,c)=>({name,movement:Object.fromEntries(MOVEMENT_FIELDS.map((key,f)=>[key,this.api.fg_mobility_get(c,f)])),moves:MOVE_IDS.map((id,m)=>({id,...this.move(c,m)}))})) };
  }
  loadData(data) {
    if([4,5,6].includes(data?.schema)&&data.coreVersion===data.schema) {
      data=structuredClone(data);const version=data.schema;
      if(data.characters?.length!==6) throw new Error('Character move list does not match this build');
      for(let c=0;c<6;++c) {
        const character=data.characters[c], slots=version<6?22:25;
        if(character.moves?.length!==slots) throw new Error('Character move list does not match this build');
        for(let i=0;i<slots;++i) {
          const m=character.moves[i];
          if(version===4) m.hitboxBack=1200;
          if(version<6) Object.assign(m,{airPushback:m.pushback,blockPushback:m.pushback,launch:0,airLaunch:850,
            knockdown:0,knockdownFrames:6,wakeupFrames:8,wallDamage:Math.min(5000,Math.max(0,m.damage*3+80)),throwRange:2000});
          for(const key of FIELDS.slice(41,51)) m[key]=this.defaultData.characters[c].moves[i][key];
        }
        character.moves.push(...structuredClone(this.defaultData.characters[c].moves.slice(slots)));
        character.movement=structuredClone(this.defaultData.characters[c].movement);
      }
      if(version<6) data.recoveryRules=structuredClone(this.defaultData.recoveryRules);
      data.schema=data.coreVersion=7;
    }
    if(data?.schema===7&&data.coreVersion===7) {
      data=structuredClone(data);
      if(data.characters?.length!==6) throw new Error('Character move list does not match this build');
      const defaults=[1,0,1,0,1,0,1,0,7,100,0,0,0,-1,-1,3];
      for(const character of data.characters) for(const m of character.moves) FIELDS.slice(51,67).forEach((key,i)=>m[key]=defaults[i]);
      data.tuningRules={...this.defaultData.tuningRules,fdAirDrain:data.momentumRules.fdDrain,fdLevelCost:0,repeatGravityStep:0};
      data.schema=data.coreVersion=8;
    }
    if(data?.schema===8&&data.coreVersion===8) {
      data=structuredClone(data);
      data.jumpRules={prejumpFrames:0,emptyLandingFrames:0};
      data.schema=data.coreVersion=9;
    }
    if(data?.schema===9&&data.coreVersion===9) {
      data=structuredClone(data);
      for(const character of data.characters) for(const move of character.moves) Object.assign(move,{counterFreezeFrames:-1,counterSlowFrames:0});
      data.schema=data.coreVersion=10;
    }
    if(data?.schema===10&&data.coreVersion===10) {
      data=structuredClone(data);data.schema=data.coreVersion=11;
    }
    if(data?.schema!==11||data.coreVersion!==this.api.fg_version()||data.characters?.length!==CHARACTERS.length) throw new Error('Unsupported move-data format');
    const previous=this.data();
    const apply=d=>{
      RULES.forEach((r,i)=>{ if(!Number.isInteger(d.inputRules?.[r])||!this.api.fg_rule_set(i,d.inputRules[r])) throw new Error(`Invalid ${r}`); });
      MOMENTUM_RULES.forEach((r,i)=>{ if(!Number.isInteger(d.momentumRules?.[r])||!this.api.fg_rule_set(i+3,d.momentumRules[r])) throw new Error(`Invalid ${r}`); });
      RECOVERY_RULES.forEach((r,i)=>{ if(!Number.isInteger(d.recoveryRules?.[r])||!this.api.fg_rule_set(i+13,d.recoveryRules[r])) throw new Error(`Invalid ${r}`); });
      TUNING_RULES.forEach((r,i)=>{ if(!Number.isInteger(d.tuningRules?.[r])||!this.api.fg_rule_set(i+26,d.tuningRules[r])) throw new Error(`Invalid ${r}`); });
      JUMP_RULES.forEach((r,i)=>{ if(!Number.isInteger(d.jumpRules?.[r])||!this.api.fg_rule_set(i+36,d.jumpRules[r])) throw new Error(`Invalid ${r}`); });
      d.characters.forEach((character,c)=>{
        if(character.name!==CHARACTERS[c]||character.moves?.length!==MOVE_IDS.length) throw new Error('Character move list does not match this build');
        MOVEMENT_FIELDS.forEach((key,f)=>{
          if(!Number.isInteger(character.movement?.[key])||!this.api.fg_mobility_set(c,f,character.movement[key])) throw new Error(`Invalid movement ${key}`);
        });
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
