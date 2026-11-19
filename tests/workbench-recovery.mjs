import {legacyPack,legacyData,stripExtensions} from './legacy-data.mjs';
import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {CombatPreview} from '../web/workbench/simulation.mjs';
const shippedPack=JSON.parse(await readFile('build/workbench-pack.json','utf8')),pack=legacyPack(shippedPack);

test('Every fighter uses back/soft and face-down/hard clips through the real preview simulation',()=>{
  const preview=new CombatPreview(pack);
  for(let target=0;target<6;target++)for(const kind of [1,2])for(const facing of [-1,1]){
    const data=structuredClone(pack.defaults),m=data.characters[5].moves[0];
    Object.assign(m,{knockdown:kind,knockdownFrames:12,wakeupFrames:20,launch:600,damage:1,pushback:0});
    const record=preview.record(data,5,0,{target,gap:0,facing});
    assert.equal(record.contacts.length,1);
    const down=record.frames.filter(f=>f.state.players[1].reaction===2),wake=record.frames.filter(f=>f.state.players[1].reaction===3);
    const phase=kind===2?9:10;
    assert.ok(down.length>=12,`${target}/${kind} never downed`);
    assert.ok(down.every(f=>f.state.players[1].posePhase===phase&&f.state.players[1].poseIndex===0));
    assert.equal(wake.length,20);assert.ok(wake.every(f=>f.state.players[1].posePhase===phase));
    assert.deepEqual([...new Set(wake.map(f=>f.state.players[1].poseIndex))],[1,2,3,4,5]);
    assert.equal(new Set([...down,...wake].map(f=>f.state.players[1].x)).size,1,'Recovery must tech in place');
    assert.equal(record.frames.at(-1).state.players[1].reaction,0);
  }
});

test('Tapper reuses fixed source calibration across idle, moves and movement',()=>{
  const tapper=pack.art[3],byFrame=new Map();
  for(const sheet of Object.values(tapper))if(sheet?.frames)for(const frame of sheet.frames){
    const key=(frame.file??sheet.file)+'/'+frame.region.join(','),height=frame.body_height??sheet.body_height;
    if(byFrame.has(key))assert.equal(height,byFrame.get(key),`Scale changed for reused frame ${key}`);
    byFrame.set(key,height);
  }
  const ready=tapper.ready.frames[0],readyHeight=(ready.bounds[3]-ready.bounds[1])*150/ready.body_height;
  assert.ok(readyHeight>=145&&readyHeight<=155,'Tapper ready must match the roster standing scale');
  for(const phase of ['knockdown','knockdown_back'])for(const fighter of pack.art){
    assert.equal(fighter[phase].frames.length,6);
    assert.ok(fighter[phase].frames.every(f=>!f.body_height||f.body_height===fighter[phase].body_height),'Lying/crouching poses must not resize themselves');
  }
});
