import {COMBO_FIELDS} from '../combo-rules.mjs';
import STANCE_FIELDS from '../../godot/data/stance_fields.json' with {type:'json'};
import {MECHANIC_SPECS} from './mechanics-specs.mjs';
import {FIELD_GROUPS} from './field-layout.mjs';
export const GROUPS=FIELD_GROUPS;
export const TABS=[
  ['timing','Timing & damage'],['hit','Hitboxes & impact'],['hurt','Hurtboxes & defense'],
  ['sequence','Sequence test'],['routes','Inputs & cancels'],['movement','Character movement'],
  ['projectiles','Projectiles'],['mechanics','Drive system'],['stance','Move behavior'],['art','Art & notes'],
].map(([id,label])=>({id,label,groups:GROUPS.filter(g=>g.tab===id).map(g=>g.id)}));
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
  hitLevel:[[0,'Mid'],[1,'Low'],[2,'Overhead']], knockdown:[[0,'None'],[1,'Soft · on back'],[2,'Hard · face down']],
  hitAngle:[[-1,'Downward 45° hook'],[0,'Straight strike'],[1,'Upward 45° hook']],
  counterTier:[[-1,'Use attack level'],[0,'Smallest'],[1,'Small'],[2,'Medium'],[3,'Large']],
  attackLevel:[[-1,'Use move type'],[0,'Level 0'],[1,'Level 1'],[2,'Level 2'],[3,'Level 3'],[4,'Level 4']],
};
const hints = {
  startup:'First active frame. Minimum: throws 2f, P normals 3f, other attacks 5f. A 2f startup has 1 windup frame.', active:'How many consecutive frames can hit.', recovery:'Time after the last active frame before acting again.',
  hitboxBack:'Horizontal offset from the fighter. Weapons can hit without gaining hurtboxes.', reach:'The front edge, measured from the fighter, rather than box width.', bottom:'Height of the lower edge above the fighter’s feet.', height:'Vertical size; for a hook, this controls the moving strike thickness.',
  advance:'Immediate forward displacement when the attack starts.', travelSpeed:'Forward movement per active frame. Negative moves backward.', inertiaPercent:'Velocity carried from a run or step dash into this move.',
  pushback:'Distance budget, applied over six action frames.', airPushback:'Distance budget against an airborne target.', blockPushback:'Immediate separation on block.', launch:'Upward speed when hitting a grounded opponent.', airLaunch:'Upward speed against an airborne opponent. Negative sends them down.',
  guardBreak:'Uses blockstun duration. Removes blockstun throw immunity and prevents backdash.', followHit:'Requires the source move to hit. Blocking does not unlock this follow-up.',
  counterFreezeFrames:'−1 uses the move’s normal stop plus Counter extra stop.', counterSlowFrames:'Defender-only alternate-frame slowdown after the shared freeze.',
  attackLevel:'Sets default attack-level behavior when a separate counter tier is not chosen.',
  counterVulnerable:'Attack phases in which this move can receive a counter hit.',
  artPose:'0 uses button artwork. Other values select this fighter’s existing signature drawings.',
  normalCancelEnd:'0 closes at the end of the move. All window values are move-frame numbers.', specialCancelEnd:'0 closes at the end of the move.', jumpCancelEnd:'0 closes at the end of the move.', followCancelEnd:'0 closes at the end of the move.',
  specialCancel:'All normals are special-cancelable by default unless deliberately opted out.',
};
Object.assign(labels,{"projectileKind": "Projectile type", "projectileSpawnFrame": "Spawn frame", "projectileSpeedX": "Horizontal speed", "projectileSpeedY": "Upward speed", "projectileGravity": "Projectile gravity", "projectileLife": "Lifetime", "projectileOffsetX": "Spawn forward offset", "projectileOffsetY": "Spawn height", "projectileWidth": "Projectile width", "projectileHeight": "Projectile height", "projectileHits": "Hits before disappearing", "projectileRehit": "Re-hit interval", "projectileDurability": "Clash durability", "projectilePersist": "Survives owner being hit", "projectileMelee": "Keep the body strike too", "smearMode": "Smear timing", "smearPart": "Moving part", "smearStretch": "Stretch", "smearFrame1": "Custom beat 1", "smearFrame2": "Custom beat 2", "smearFrame3": "Custom beat 3", "smearFrame4": "Custom beat 4"});
for(const key of ['projectileOffsetX','projectileOffsetY','projectileWidth','projectileHeight'])pixel.add(key);
for(const key of ['projectileSpeedX','projectileSpeedY','projectileGravity'])speed.add(key);
for(const key of ['projectilePersist','projectileMelee'])flags.add(key);
percent.add('smearStretch');
Object.assign(options,{projectileKind:[[0,'None'],[1,'Moving projectile'],[2,'Stationary object']]});
Object.assign(hints,{"projectileSpawnFrame": "0 spawns on the first active frame. Other values are absolute move frames (clamped to the move’s startup minimum). Values beyond the move do not spawn; throws do not spawn projectiles.", "projectileSpeedX": "Positive travels forward from the launch facing. Negative travels backward. Stationary objects ignore speed and gravity.", "projectileSpeedY": "Positive rises; negative falls.", "projectileGravity": "Downward acceleration per frame (px/f\u00b2). Negative accelerates upward.", "projectileLife": "Action frames alive; shared hitstop freezes the lifetime.", "projectileRehit": "Minimum action frames between contacts with the same target.", "projectileDurability": "Opposing projectiles subtract durability. Equal strength destroys both.", "projectileMelee": "Enable to retain the attack\u2019s normal hitboxes as well as its projectile.", "projectilePersist": "Otherwise disappears when its owner is hit. All projectiles clear during wall travel and round resets."});
Object.assign(labels,{hurtMaskWindup:'Windup hurtboxes',hurtMaskActive:'Active hurtboxes',hurtMaskRecovery:'Recovery hurtboxes'});
for(const key of ['hurtMaskWindup','hurtMaskActive','hurtMaskRecovery'])masks[key]=['Legs','Torso & arms','Head','Body extension'];
// Smear fields are inactive compatibility data; no renderer or editor control uses them.
for(const key of Object.keys(labels).filter(key=>key.startsWith('smear'))){labels[key]='Legacy '+labels[key].toLowerCase();hints[key]='Retained for older JSON drafts; has no effect.';}
for(const [key,label,,, ,hint] of MECHANIC_SPECS){labels[key]=label;hints[key]=hint;}
for(const key of ['tetherSpeed','variantSpeed','variantLift'])speed.add(key);pixel.add('variantRange');pixel.add('tetherRange');pixel.add('tetherGap');pixel.add('driveDistance');percent.add('bleedBlockPercent');
labels.mechanic='Drive role';
options.mechanic=[[0,'None'],[1,'Tether → pull'],[2,'Bleed → cash-out grab'],[3,'Attach line'],[4,'Reel In · spend line'],[5,'Break Step · enhance a normal']];
options.variantKnockdown=options.knockdown;
for(const f of STANCE_FIELDS){labels[f.key]=f.label;hints[f.key]=f.help;if(f.scale===100)(/Speed|Travel|Bounce/.test(f.key)?speed:pixel).add(f.key);}
Object.assign(options,{stanceRequired:[[0,'Any'],[1,'Normal stance'],[2,'Rolling stance']],stanceChange:[[0,'None'],[1,'Enter on hit'],[2,'Exit on start']],actionType:[[0,'Strike'],[1,'Held guard'],[2,'Stance exit'],[3,'Stall and dive'],[4,'Grab sequence'],[5,'Hold to charge'],[6,'Air projectile recoil']],airCounterKnockdown:options.knockdown,holdButton:options.button});
masks.hurtWindowMask=['Legs','Torso & arms','Head','Body extension'];
for(const f of COMBO_FIELDS){labels[f.key]=f.label;hints[f.key]=f.help;if(f.scale===100)speed.add(f.key);}
labels.pushback='Legacy ground distance / throw separation';labels.airPushback='Legacy air distance / throw separation';
hints.pushback='Throws use this immediate separation. Strikes use it only in legacy physics mode; modern strikes use Ground hit speed.';
hints.airPushback='Air throws use this separation. Modern air strikes use Air hit speed.';
export const SPECS = Object.fromEntries(Object.entries(labels).map(([key,label])=>[key,{
  key,label,scale:pixel.has(key)||speed.has(key)?100:1,
  unit:key==='projectileGravity'?'px/f²':['drivePlus','driveNeutralFrames','tetherDuration','variantStartup','variantActive','variantRecovery','bleedDuration','projectileLife','projectileRehit','projectileSpawnFrame','smearFrame1','smearFrame2','smearFrame3','smearFrame4'].includes(key)?'f':pixel.has(key)?'px':speed.has(key)?'px/f':percent.has(key)?'%': /startup|active|recovery|stun|stop|Frames|Start|End/i.test(key)?'f':'',
  type:flags.has(key)?'flag':masks[key]?'mask':options[key]||['followFrom','followFrom2','artPose','finishArtPose','holdFollow','guardFollow','proximityMove'].includes(key)?'select':'number',
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
