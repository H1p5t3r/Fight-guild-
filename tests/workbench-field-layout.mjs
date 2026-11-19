import {legacyPack,legacyData,stripExtensions} from './legacy-data.mjs';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {MOVEMENT_FIELDS} from '../web/engine.mjs';
import {FIELD_GROUPS,inactiveReason,groupEnabled} from '../web/workbench/field-layout.mjs';
import {MOVEMENT_GROUPS,movementInactiveReason} from '../web/workbench/movement-editor.mjs';
import {driveKit} from '../web/workbench/drive-editor.mjs';
import {findSettings,SETTING_INDEX} from '../web/workbench/setting-search.mjs';
const shippedPack=JSON.parse(await readFile(new URL('../build/workbench-pack.json',import.meta.url),'utf8')),pack=legacyPack(shippedPack);

test('Every active movement control and relocated move setting stays discoverable',()=>{
 const movement=MOVEMENT_GROUPS.flatMap(([, ,fields])=>fields.map(([key])=>key));
 assert.equal(new Set(movement).size,movement.length);
 assert.deepEqual(MOVEMENT_FIELDS.filter(key=>!movement.includes(key)),['smearMode','smearPart','smearStretch']);
 for(const [key,tab]of [['startupTravel','hit'],['groundBounce','hit'],['armorFrames','hurt'],['hurtWindowStart','hurt'],['stanceRequired','mechanics'],['proximityRange','routes'],['artPose','art']]){
  assert.equal(SETTING_INDEX.find(e=>e.key===key).tab,tab);
  assert.ok(findSettings(key).some(e=>e.key===key));
 }
 assert.ok(findSettings('air forward pause').some(e=>e.key==='movement-airDashPauseFrames'));
});

test('Drive overview uses actual enabled kit entries, stance attacks and exits',()=>{
 const data=structuredClone(pack.defaults),before=JSON.stringify(data);
 const shark=driveKit(data.characters[4]),fillet=driveKit(data.characters[5]),tapper=driveKit(data.characters[3]);
 assert.ok(shark.entries.length&&shark.entries.every(e=>e.move.mechanic===3));
 assert.deepEqual(shark.spends.map(e=>e.move.mechanic).sort(),[4,5]);
 assert.ok(fillet.entries.length&&fillet.entries.every(e=>e.move.mechanic===2));
 assert.ok(tapper.entries.some(e=>e.move.category===4));
 assert.ok(tapper.stance.some(e=>e.slot===40));
 assert.ok(tapper.exits.every(e=>e.move.stanceChange===2));assert.ok(tapper.exits.length);
 assert.equal(JSON.stringify(data),before);
 data.characters[3].moves[40].enabled=0;
 assert.ok(!driveKit(data.characters[3]).stance.some(e=>e.slot===40));
});

test('Visibility follows status, projectile and action behavior without rewriting retained values',()=>{
 const move=structuredClone(pack.defaults.characters[4].moves[13]);
 const before=JSON.stringify(move);
 assert.ok(inactiveReason('tetherSpeed',move));assert.equal(inactiveReason('tetherDuration',move),'');assert.ok(inactiveReason('bleedInitial',move));
 assert.ok(inactiveReason('variantDamage',move));assert.ok(inactiveReason('variantStartup',move));
 assert.equal(JSON.stringify(move),before);
 move.mechanic=2;assert.equal(inactiveReason('bleedInitial',move),'');assert.ok(inactiveReason('tetherSpeed',move));
 move.projectileKind=2;assert.ok(inactiveReason('projectileSpeedX',move));assert.equal(inactiveReason('projectileLife',move),'');
 move.projectileKind=1;assert.equal(inactiveReason('projectileSpeedX',move),'');
 move.actionType=4;assert.equal(inactiveReason('grabFrames',move),'');assert.ok(inactiveReason('diveSpeedX',move));
 move.actionType=3;assert.equal(inactiveReason('diveSpeedX',move),'');assert.ok(inactiveReason('grabFrames',move));
 // Airborne contacts can cause a soft knockdown even with no authored knockdown.
 move.knockdown=0;move.airCounterKnockdown=0;move.variantKnockdown=0;move.mechanic=0;
 assert.equal(inactiveReason('knockdownFrames',move),'');assert.equal(inactiveReason('wakeupFrames',move),'');
});

test('Outgoing follow-up windows belong to the source move, not the target',()=>{
 const character=structuredClone(pack.defaults.characters[5]),source=character.moves[0],target=character.moves[1];
 const group=FIELD_GROUPS.find(g=>g.id==='follow-window');
 for(const m of character.moves){m.followFrom=-1;m.followFrom2=-1;}
 target.enabled=1;target.followFrom=0;
 assert.equal(groupEnabled(group,source,character),true);
 assert.equal(groupEnabled(group,target,character),false);
 target.enabled=0;assert.equal(groupEnabled(group,source,character),false);
});

test('Movement relevance keeps shared air-teleport distances and pause/burst timing available',()=>{
 const p=structuredClone(pack.defaults.characters[5].movement);
 Object.assign(p,{forwardStyle:0,backStyle:1,airDashEnabled:1,airDashStyle:3,airBackdashEnabled:0});
 assert.equal(movementInactiveReason('teleportDistance',p),'');
 assert.equal(movementInactiveReason('airDashPauseFrames',p),'');
 assert.equal(movementInactiveReason('airDashFrames',p),'');
 assert.ok(movementInactiveReason('airDashSpeed',p));
 assert.ok(movementInactiveReason('teleportStartup',p));assert.ok(movementInactiveReason('hoverHeight',p));
 p.airDashStyle=2;assert.ok(movementInactiveReason('hoverHeight',p));assert.ok(movementInactiveReason('teleportDistance',p));
 p.backStyle=2;assert.equal(movementInactiveReason('hoverHeight',p),'');
 p.backStyle=0;p.forwardStyle=1;assert.equal(movementInactiveReason('runAcceleration',p),'');
});
