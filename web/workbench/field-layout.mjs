// Presentation only: these groups never change or clear saved combat values.
const group=(id,tab,title,intro,fields,optional=false)=>({id,tab,title,intro,fields,optional});
export const FIELD_GROUPS=[
 group('timing','timing','Attack timing','One frame is 1/60 of a second. Startup is the first active frame.',['startup','active','recovery']),
 group('damage','timing','Damage & impact','Base damage, blocked chip and the shared impact freeze.',['damage','chipDamage','hitstop']),
 group('stun','timing','Hitstun & blockstun','How long the target is unable to act after contact.',['hitstun','blockstun']),
 group('counter','timing','Counter hits & reversal','Counter strength, vulnerability and timing. Reversal eligibility does not grant invulnerability.',['attackLevel','counterTier','counterVulnerable','counterFreezeFrames','counterSlowFrames','counterHitstun','counterHitstop','reversalEligible']),
 group('scaling','timing','Combo damage scaling','Starter proration, scaling cost and the damage floor.',['starterProration','comboScaling','minimumDamage']),
 group('geometry','hit','Base hitbox','Used before the first active-frame key, or by keys that inherit base geometry.',['hitboxBack','reach','bottom','height']),
 group('attack-travel','hit','Attacker movement','Movement of the attacking fighter, before and during the hit.',['advance','startupTravel','travelSpeed','inertiaPercent']),
 group('ground-hit','hit','Grounded target','Knockback, launch and crumple when the target is grounded.',['pushback','launch','crumpleFrames']),
 group('air-hit','hit','Airborne target','Air knockback, launch and bounces.',['airPushback','airLaunch','groundBounce','wallBounce','airCounterKnockdown']),
 group('block','hit','On block','Guard height, defender pushback and guard break.',['hitLevel','blockPushback','guardBreak']),
 group('knockdown','hit','Knockdown & wakeup','Soft knockdown uses the back pose; hard knockdown uses the face-down pose.',['knockdown','knockdownFrames','wakeupFrames']),
 group('landing','hit','Landing','Recovery when an airborne attack lands.',['landingRecovery'],true),
 group('hook','hit','Hook & reel','A travelling diagonal hook and its pull, separate from the Drive tether.',['hitAngle','pullFrames','pullGap'],true),
 group('throw','hit','Throw reach','Extra reach beyond the two pushboxes.',['throwRange'],true),
 group('vulnerability','hurt','Phase hurtboxes','Body regions that can be hit in each phase.',['hurtMaskWindup','hurtMaskActive','hurtMaskRecovery']),
 group('hurt-window','hurt','Timed hurtbox protection','Narrow body-region protection to a specific window inside the move. Zero start disables it.',['hurtWindowStart','hurtWindowEnd','hurtWindowMask'],true),
 group('low-crush','hurt','Low & ground-throw avoidance','A low-crush window does not change which inputs the fighter can use. Zero start disables it.',['semiAirStart','semiAirEnd'],true),
 group('armor','hurt','Armor','Limited protection against mids and highs. Lows and throws still connect.',['armorFrames','armorHits'],true),
 group('input','routes','Input & move type','The saved slot ID stays fixed. These settings define the actual command.',['enabled','button','category','direction','motion','air']),
 group('simple','routes','Simple input','Modifier + direction + button. Choose a direction to enable this mapping.',['simpleDirection','simpleButton']),
 group('proximity','routes','Close-distance version','Replace this input with another move when close enough.',['proximityMove','proximityRange'],true),
 group('cancel','routes','Cancel conditions','Contact conditions and whether this move may repeat or cancel on whiff.',['cancelOn','whiffCancel','selfCancel']),
 group('normal-cancel','routes','Normal & command cancels','Unified uses the shared gatling rules. Windows use move frames; zero end means move end.',['normalRoutes','commandRoutes','normalCancelStart','normalCancelEnd']),
 group('special-cancel','routes','Special cancels','Allow special cancels and set their window.',['specialCancel','specialCancelStart','specialCancelEnd']),
 group('jump-cancel','routes','Jump cancels','Allow jump cancels and set their window.',['jumpCancel','jumpCancelStart','jumpCancelEnd']),
 group('follow-source','routes','Required previous move','This move becomes a contextual follow-up to the chosen source moves.',['followFrom','followFrom2','followHit'],true),
 group('follow-window','routes','Outgoing follow-up window','When other moves may follow this one. Set their source to this move.',['followCancelStart','followCancelEnd'],true),
 group('projectile-type','projectiles','Projectile type','Choose a moving projectile or a stationary object.',['projectileKind']),
 group('projectile-spawn','projectiles','Spawn & shape','Spawn position, size and lifetime.',['projectileSpawnFrame','projectileOffsetX','projectileOffsetY','projectileWidth','projectileHeight','projectileLife']),
 group('projectile-motion','projectiles','Projectile movement','Velocity and gravity apply to moving projectiles.',['projectileSpeedX','projectileSpeedY','projectileGravity']),
 group('projectile-contact','projectiles','Contact & clashes','Hit limits, clashes and persistence after the owner is hit.',['projectileHits','projectileRehit','projectileDurability','projectilePersist','projectileMelee']),
 group('drive-type','mechanics','Applied status','A status can change what this same input does on its next use.',['mechanic']),
 group('tether','mechanics','Tether pull','The pull moves the opponent toward the owner without dealing damage.',['tetherSpeed','tetherFrames']),
 group('line','mechanics','Line behavior','Tag on hit, then spend it with the separate 2D pull input.',['tetherDuration','tetherRange','tetherGap'],true),
 group('bleed','mechanics','Bleed & grey life','Grey life is stored damage. It is paid out by a successful cash-out grab.',['bleedInitial','bleedTickDamage','bleedTickFrames','bleedDuration','bleedBlockPercent','bleedCap']),
 group('variant-timing','mechanics','Conditional follow-up timing','These frames replace the original attack while its status is on the opponent.',['variantStartup','variantActive','variantRecovery']),
 group('cash-out','mechanics','Cash-out grab','Base damage plus stored grey life, with its own reach and leap.',['variantDamage','variantRange','variantSpeed','variantLift','variantHitstun','variantKnockdown']),
 group('stance-access','mechanics','Stance access & transition','Choose which stance can use this action, and whether it enters or exits rolling stance.',['stanceRequired','stanceChange']),
 group('action','stance','Action behavior','Choose the behavior used by this move. Its settings appear in the groups below.',['actionType']),
 group('held-follow','stance','Hold & charge transition','A held button may enter another move; charge actions use its active frames at full charge.',['holdFollow','holdFrame'],true),
 group('held-guard','stance','Held guard','Hold-button and counterattack settings for a held guard action.',['holdButton','guardFollow']),
 group('dive','stance','Dive / air recoil','Velocity for stall-and-dive or air projectile recoil.',['diveSpeedX','diveSpeedY']),
 group('capture','stance','Capture & finish','Time from capture to the single finishing hit in a grab sequence.',['grabFrames']),
 group('art-pose','art','Sprite selection','Select existing drawings. Art notes below describe future sprite changes.',['artPose','finishArtPose','finishArtFrame']),
];

export function inactiveReason(key,m){
 if(m.mechanic===4&&(key.startsWith('projectile')||['damage','chipDamage','hitstop','hitstun','blockstun','attackLevel','counterTier','counterFreezeFrames','counterSlowFrames','counterHitstun','counterHitstop','starterProration','comboScaling','minimumDamage','hitboxBack','reach','bottom','height','pushback','launch','crumpleFrames','airPushback','airLaunch','groundBounce','wallBounce','airCounterKnockdown','hitLevel','blockPushback','guardBreak','knockdown','knockdownFrames','wakeupFrames','hitAngle','pullFrames','pullGap','throwRange'].includes(key)))return 'Reel In only moves the target. It ignores guard and applies no damage, hitstop or new stun.';
 if(key==='tetherSpeed'&&m.mechanic!==1)return 'Used by legacy tether. Reel In uses duration and gap.';
 if(key==='tetherFrames'&&![1,4].includes(m.mechanic))return 'Used by Reel In or legacy tether.';
 if(key==='tetherDuration'&&m.mechanic!==3)return 'Used by Attach line.';
 if(key==='tetherRange'&&m.mechanic<3)return 'Used by line actions.';
 if(key==='tetherGap'&&m.mechanic!==4)return 'Used by Reel In.';
 if(key.startsWith('bleed')&&m.mechanic!==2)return 'Used by Bleed → cash-out grab.';
 if(['variantStartup','variantActive','variantRecovery'].includes(key)&&![1,2].includes(m.mechanic))return 'Enable an applied status to use conditional follow-up timing.';
 if(['variantDamage','variantRange','variantSpeed','variantLift','variantHitstun','variantKnockdown'].includes(key)&&m.mechanic!==2)return 'Used by the bleed cash-out grab; tether pulls deal no damage.';
 if(key.startsWith('projectile')&&key!=='projectileKind'){
  if(!m.projectileKind)return 'Choose a projectile type first.';
  if(m.category===4)return 'Throws do not spawn projectiles.';
  if(['projectileSpeedX','projectileSpeedY','projectileGravity'].includes(key)&&m.projectileKind!==1)return 'Stationary objects ignore velocity and gravity.';
 }
 if(['pullFrames','pullGap'].includes(key)&&!m.hitAngle)return 'Choose a diagonal hook direction to use the reel.';
 if(key==='throwRange'&&m.category!==4)return 'Used by throw moves. Cash-out grabs have their own range.';
 if(key==='simpleButton'&&!m.simpleDirection)return 'Choose a simple-input direction first.';
 if(key==='proximityRange'&&m.proximityMove<0)return 'Choose a close-distance move first.';
 if(['specialCancelStart','specialCancelEnd'].includes(key)&&!m.specialCancel)return 'Enable Special cancel to use this window.';
 if(['jumpCancelStart','jumpCancelEnd'].includes(key)&&!m.jumpCancel)return 'Enable Jump cancel to use this window.';
 if(key==='followHit'&&m.followFrom<0&&m.followFrom2<0)return 'Choose at least one previous move first.';
 if(key==='holdFrame'&&m.holdFollow<0&&m.actionType!==5)return 'Choose a held-input destination or Hold to charge behavior.';
 if(['holdButton','guardFollow'].includes(key)&&m.actionType!==1)return 'Used by Held guard behavior.';
 if(['diveSpeedX','diveSpeedY'].includes(key)&&![3,6].includes(m.actionType))return 'Used by Stall and dive or Air projectile recoil behavior.';
 if(key==='grabFrames'&&m.actionType!==4)return 'Used by Grab sequence behavior.';
 if(['hurtWindowEnd','hurtWindowMask'].includes(key)&&!m.hurtWindowStart)return 'Set a positive Hurtbox window begins frame first.';
 if(key==='semiAirEnd'&&!m.semiAirStart)return 'Set a positive Low-crush window begins frame first.';
 if(key==='armorHits'&&!m.armorFrames)return 'Set a positive armor duration first.';
 if(key==='finishArtFrame'&&!m.finishArtPose)return 'Choose a finisher artwork pose first.';
 return '';
}

export function groupEnabled(g,m,character){
 if(g.active)return g.active(m,character);
 if(g.id==='hook')return !!m.hitAngle;
 if(g.id==='landing')return !!m.air||!!m.landingRecovery;
 if(g.id==='hurt-window')return !!m.hurtWindowStart;
 if(g.id==='low-crush')return !!m.semiAirStart;
 if(g.id==='armor')return !!m.armorFrames;
 if(g.id==='proximity')return m.proximityMove>=0;
 if(g.id==='follow-source')return m.followFrom>=0||m.followFrom2>=0;
 if(g.id==='follow-window')return character.moves.some(n=>n.enabled&&(n.followFrom===character.moves.indexOf(m)||n.followFrom2===character.moves.indexOf(m)));
 if(g.id==='held-follow')return m.holdFollow>=0||m.actionType===5;
 return g.fields.some(key=>!inactiveReason(key,m));
}
