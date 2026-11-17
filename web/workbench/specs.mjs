import {MECHANIC_SPECS} from './mechanics-specs.mjs';
export const GROUPS = [
  {id:'timing', title:'Frame data', intro:'Tune the pace and reward. One frame is 1/60 of a second.', fields:['startup','active','recovery','damage','hitstun','blockstun','hitstop','chipDamage']},
  {id:'geometry', title:'Hitbox & movement', intro:'Distances use game pixels. The preview keeps the existing artwork while you change its attack geometry.', fields:['hitboxBack','reach','bottom','height','advance','travelSpeed','inertiaPercent','hitAngle','throwRange']},
  {id:'reaction', title:'Hit & block reaction', intro:'Soft knockdowns automatically tech in place. Hard knockdown is reserved for tools such as 2D and throws.', fields:['hitLevel','guardBreak','knockdown','pushback','airPushback','blockPushback','launch','airLaunch','knockdownFrames','wakeupFrames','landingRecovery','pullFrames','pullGap']},
  {id:'cancel', title:'Cancel routes', intro:'Use Unified to follow the shared gatling rules. Custom routes select the destination buttons.', fields:['specialCancel','jumpCancel','whiffCancel','selfCancel','normalRoutes','commandRoutes','cancelOn','normalCancelStart','normalCancelEnd','specialCancelStart','specialCancelEnd','jumpCancelStart','jumpCancelEnd','followCancelStart','followCancelEnd','followFrom','followFrom2','followHit']},
  {id:'input', title:'Inputs & identity', intro:'Move slots keep their IDs for game compatibility. These fields control the actual input and move type.', fields:['enabled','button','category','direction','motion','air','simpleDirection','simpleButton','artPose']},
  {id:'counter', title:'Counter hits & scaling', intro:'Reversal eligibility recognizes first-frame execution; it does not add invulnerability.', fields:['attackLevel','counterTier','counterVulnerable','counterFreezeFrames','counterSlowFrames','counterHitstun','counterHitstop','reversalEligible','starterProration','comboScaling','minimumDamage']},
];
GROUPS.push({id:'projectiles',title:'Projectile',intro:'Moving shots travel independently; stationary objects stay where they spawn. They use this move’s damage, stun, launch and block rules. No projectile is created until enabled.',fields:["projectileKind", "projectileSpawnFrame", "projectileSpeedX", "projectileSpeedY", "projectileGravity", "projectileLife", "projectileOffsetX", "projectileOffsetY", "projectileWidth", "projectileHeight", "projectileHits", "projectileRehit", "projectileDurability", "projectilePersist", "projectileMelee"]});
GROUPS.push({id:'vulnerability',title:'Vulnerable body regions',intro:'Choose which regions can receive hits in each attack phase. Disabled regions retain their coordinates.',fields:['hurtMaskWindup','hurtMaskActive','hurtMaskRecovery']});
GROUPS.push({id:'mechanics',title:'Drive mechanics',intro:'Tether and bleed attach on hit. Reuse the applying input for its conditional follow-up. Getting hit clears your statuses. All values below are provisional tuning.',fields:MECHANIC_SPECS.map(row=>row[0])});
export const TABS = [
  {id:'mechanics',label:'Drive mechanics',groups:['mechanics']},
  {id:'movement',label:'Movement & defense',groups:[]},
  {id:'projectiles',label:'Projectiles',groups:['projectiles']},
  {id:'timing',label:'Timing',groups:['timing','counter']},
  {id:'hit',label:'Hit & movement',groups:['geometry','reaction']},
  {id:'routes',label:'Cancels & inputs',groups:['cancel','input']},
  {id:'hurt',label:'Hurtboxes',groups:[]},
  {id:'art',label:'Art brief',groups:[]},
];
const labels = {
  startup:'Startup', active:'Active', recovery:'Recovery', damage:'Damage', hitstun:'Hitstun', blockstun:'Blockstun', hitstop:'Hitstop', chipDamage:'Chip damage',
  hitboxBack:'Back edge', reach:'Front edge', bottom:'Bottom', height:'Height', advance:'Opening step', travelSpeed:'Active travel', inertiaPercent:'Run / dash carry', hitAngle:'Hook direction', throwRange:'Throw reach',
  hitLevel:'Guard level', guardBreak:'Guard break on block', knockdown:'Knockdown', pushback:'Ground knockback', airPushback:'Air knockback', blockPushback:'Block pushback', launch:'Ground launch', airLaunch:'Air launch', knockdownFrames:'Down duration', wakeupFrames:'Wakeup duration', landingRecovery:'Landing recovery', pullFrames:'Hook pull duration', pullGap:'Pull extra gap',
  specialCancel:'Special cancel', jumpCancel:'Jump cancel', whiffCancel:'Cancel on whiff', selfCancel:'Repeat this move', normalRoutes:'Normal destinations', commandRoutes:'Command destinations', cancelOn:'Cancel events', normalCancelStart:'Normal window opens', normalCancelEnd:'Normal window closes', specialCancelStart:'Special window opens', specialCancelEnd:'Special window closes', jumpCancelStart:'Jump window opens', jumpCancelEnd:'Jump window closes', followCancelStart:'Follow-up window opens', followCancelEnd:'Follow-up window closes', followFrom:'First follow-up source', followFrom2:'Second follow-up source', followHit:'Follow-up requires contact',
  enabled:'Move enabled', button:'Button', category:'Move type', direction:'Direction', motion:'Motion', air:'Airborne move', simpleDirection:'Simple direction', simpleButton:'Simple button', artPose:'Artwork pose',
  attackLevel:'Attack level', counterTier:'Counter tier', counterVulnerable:'Counter vulnerability', counterFreezeFrames:'Counter freeze', counterSlowFrames:'Counter slowdown', counterHitstun:'Counter extra stun', counterHitstop:'Counter extra stop', reversalEligible:'Eligible for reversal timing', starterProration:'Starter damage', comboScaling:'Scaling cost', minimumDamage:'Minimum damage',
  // Retired compatibility field: preserve and validate it, but never offer it as
  // an effective tuning control. Wall damage is driven by collision velocity.
  wallDamage:'Legacy wall damage'
};
const pixel = new Set(['hitboxBack','reach','bottom','height','advance','throwRange','pushback','airPushback','blockPushback','pullGap']);
const speed = new Set(['travelSpeed','launch','airLaunch']);
const percent = new Set(['inertiaPercent','starterProration','comboScaling','minimumDamage']);
const flags = new Set(['enabled','air','specialCancel','jumpCancel','whiffCancel','selfCancel','guardBreak','reversalEligible','followHit']);
const masks = {normalRoutes:['P','K','S','Hs','D'],commandRoutes:['P','K','S','Hs','D'],cancelOn:['Hit','Block','Whiff'],counterVulnerable:['Startup','Active','Recovery']};
const directions = Array.from({length:9},(_,i)=>[i+1,`${i+1} · ${['down-back','down','down-forward','back','neutral','forward','up-back','up','up-forward'][i]}`]);
const buttons = ['P','K','S','Hs','D'].map((s,i)=>[i,s]);
const options = {
  button:buttons, simpleButton:buttons, category:[[0,'Normal'],[1,'Command normal'],[2,'Special'],[3,'Drive'],[4,'Throw']],
  direction:directions, simpleDirection:[[0,'No simple mapping'],...directions], motion:[[0,'None'],[236,'236'],[214,'214'],[623,'623']],
  hitLevel:[[0,'Mid'],[1,'Low'],[2,'Overhead']], knockdown:[[0,'None'],[1,'Soft · auto tech'],[2,'Hard']],
  hitAngle:[[-1,'Downward 45° hook'],[0,'Straight strike'],[1,'Upward 45° hook']],
  counterTier:[[-1,'Use attack level'],[0,'Smallest'],[1,'Small'],[2,'Medium'],[3,'Large']],
  attackLevel:[[-1,'Use move type'],[0,'Level 0'],[1,'Level 1'],[2,'Level 2'],[3,'Level 3'],[4,'Level 4']],
};
const hints = {
  startup:'First active frame; minimum 5. A 5f startup has 4 windup frames.', active:'How many consecutive frames can hit.', recovery:'Time after the last active frame before acting again.',
  hitboxBack:'Horizontal offset from the fighter. Weapons can hit without gaining hurtboxes.', reach:'The front edge, measured from the fighter, rather than box width.', bottom:'Height of the lower edge above the fighter’s feet.', height:'Vertical size; for a hook, this controls the moving strike thickness.',
  advance:'Immediate forward displacement when the attack starts.', travelSpeed:'Forward movement per active frame. Negative moves backward.', inertiaPercent:'Velocity carried from a run or step dash into this move.',
  pushback:'Distance budget, applied over six action frames.', airPushback:'Distance budget against an airborne target.', blockPushback:'Immediate separation on block.', launch:'Upward speed when hitting a grounded opponent.', airLaunch:'Upward speed against an airborne opponent. Negative sends them down.',
  guardBreak:'Uses blockstun duration. Removes blockstun throw immunity and prevents backdash.', followHit:'Requires the source move to hit. Blocking does not unlock this follow-up.',
  counterFreezeFrames:'−1 uses the move’s normal stop plus Counter extra stop.', counterSlowFrames:'Defender-only alternate-frame slowdown after the shared freeze.',
  attackLevel:'Sets default attack-level behavior when a separate counter tier is not chosen.',
  counterVulnerable:'Attack phases in which this move can receive a counter hit.',
  artPose:'0 uses button artwork. Signature poses are available only for Fillet and Shark.',
  normalCancelEnd:'0 closes at the end of the move. All window values are move-frame numbers.', specialCancelEnd:'0 closes at the end of the move.', jumpCancelEnd:'0 closes at the end of the move.', followCancelEnd:'0 closes at the end of the move.',
  specialCancel:'All normals are special-cancelable by default unless deliberately opted out.',
};
Object.assign(labels,{"projectileKind": "Projectile type", "projectileSpawnFrame": "Spawn frame", "projectileSpeedX": "Horizontal speed", "projectileSpeedY": "Upward speed", "projectileGravity": "Projectile gravity", "projectileLife": "Lifetime", "projectileOffsetX": "Spawn forward offset", "projectileOffsetY": "Spawn height", "projectileWidth": "Projectile width", "projectileHeight": "Projectile height", "projectileHits": "Hits before disappearing", "projectileRehit": "Re-hit interval", "projectileDurability": "Clash durability", "projectilePersist": "Survives owner being hit", "projectileMelee": "Keep the body strike too", "smearMode": "Smear timing", "smearPart": "Moving part", "smearStretch": "Stretch", "smearFrame1": "Custom beat 1", "smearFrame2": "Custom beat 2", "smearFrame3": "Custom beat 3", "smearFrame4": "Custom beat 4"});
for(const key of ['projectileOffsetX','projectileOffsetY','projectileWidth','projectileHeight'])pixel.add(key);
for(const key of ['projectileSpeedX','projectileSpeedY','projectileGravity'])speed.add(key);
for(const key of ['projectilePersist','projectileMelee'])flags.add(key);
percent.add('smearStretch');
Object.assign(options,{projectileKind:[[0,'None'],[1,'Moving projectile'],[2,'Stationary object']]});
Object.assign(hints,{"projectileSpawnFrame": "0 spawns on the first active frame. Other values are absolute move frames (earliest 5). Values beyond the move do not spawn; throws do not spawn projectiles.", "projectileSpeedX": "Positive travels forward from the launch facing. Negative travels backward. Stationary objects ignore speed and gravity.", "projectileSpeedY": "Positive rises; negative falls.", "projectileGravity": "Downward acceleration per frame (px/f\u00b2). Negative accelerates upward.", "projectileLife": "Action frames alive; shared hitstop freezes the lifetime.", "projectileRehit": "Minimum action frames between contacts with the same target.", "projectileDurability": "Opposing projectiles subtract durability. Equal strength destroys both.", "projectileMelee": "Enable to retain the attack\u2019s normal hitboxes as well as its projectile.", "projectilePersist": "Otherwise disappears when its owner is hit. All projectiles clear during wall travel and round resets."});
Object.assign(labels,{hurtMaskWindup:'Windup hurtboxes',hurtMaskActive:'Active hurtboxes',hurtMaskRecovery:'Recovery hurtboxes'});
for(const key of ['hurtMaskWindup','hurtMaskActive','hurtMaskRecovery'])masks[key]=['Legs','Torso & arms','Head','Body extension'];
// Smear fields are inactive compatibility data; no renderer or editor control uses them.
for(const key of Object.keys(labels).filter(key=>key.startsWith('smear'))){labels[key]='Legacy '+labels[key].toLowerCase();hints[key]='Retained for older JSON drafts; has no effect.';}
for(const [key,label,,, ,hint] of MECHANIC_SPECS){labels[key]=label;hints[key]=hint;}
for(const key of ['tetherSpeed','variantSpeed','variantLift'])speed.add(key);pixel.add('variantRange');percent.add('bleedBlockPercent');
options.mechanic=[[0,'None'],[1,'Tether → pull'],[2,'Bleed → cash-out grab']];
options.variantKnockdown=options.knockdown;
export const SPECS = Object.fromEntries(Object.entries(labels).map(([key,label])=>[key,{
  key,label,scale:pixel.has(key)||speed.has(key)?100:1,
  unit:key==='projectileGravity'?'px/f²':['variantStartup','variantActive','variantRecovery','bleedDuration','projectileLife','projectileRehit','projectileSpawnFrame','smearFrame1','smearFrame2','smearFrame3','smearFrame4'].includes(key)?'f':pixel.has(key)?'px':speed.has(key)?'px/f':percent.has(key)?'%': /startup|active|recovery|stun|stop|Frames|Start|End/i.test(key)?'f':'',
  type:flags.has(key)?'flag':masks[key]?'mask':options[key]||['followFrom','followFrom2','artPose'].includes(key)?'select':'number',
  options:options[key],mask:masks[key],unified:key==='normalRoutes'||key==='commandRoutes',hint:hints[key]||''
}]));
export const ART_FIELDS = [
  ['label','Move nickname','Optional, e.g. Rising Carve',100],
  ['intent','Gameplay intent','What should this tool be good at? What should punish it?',3000],
  ['windup','Windup pose','Describe the weight shift, silhouette and visual tell.',3000],
  ['active','Active pose / weapon path','Describe direction, contact height and how the weapon travels.',3000],
  ['effects','Hit & block effects','Smear shape, color, impact or guard reaction ideas.',3000],
  ['recovery','Follow-through & recovery','Optional notes for the later animation pass.',3000],
];
export const GUILDS = ['Blacksmiths','Masons','Alchemists','Brewers','Fishermen','Butchers'];
export const COLORS = ['#dfb36c','#99b0c2','#a8ba76','#d99a59','#5ab5b5','#d67570'];
export const KINDS = ['Normal','Command','Special','Drive','Throw'];
