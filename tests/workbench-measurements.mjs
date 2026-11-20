import {test} from 'node:test';
import assert from 'node:assert/strict';
import {measureDistances,pixels,distanceSummary} from '../web/workbench/measurements.mjs';

test('Distance guides use root positions and pushbox edges, independent of sprite or height',()=>{
  const players=[{x:10000,y:0,facing:1},{x:20000,y:12000,facing:-1}];
  const measures=measureDistances(players,[[8000,0,12000,15000],[18000,12000,22000,27000]],[[1000,2000,3500,7000]],[100,200,1334,5200]);
  assert.equal(measures.roots.value,10000);assert.equal(measures.body.value,6000);assert.equal(measures.body.overlap,false);
  assert.deepEqual(measures.reach,{from:10000,to:13500,value:3500,top:7000});
  assert.deepEqual(measures.selected,{width:1234,height:5000});
  assert.match(distanceSummary(measures),/Selected box 12.34 px × 50 px/);
});
test('Left-facing, rearward and multi-box reach measure actual authored coordinates',()=>{
  const players=[{x:50000,y:6000,facing:-1},{x:40000,y:0,facing:1}];
  const measures=measureDistances(players,[[48000,6000,52000,21000],[38000,0,42000,15000]],[[0,0,2500,8000],[-1000,1000,5500,9000]]);
  assert.equal(measures.roots.value,10000);assert.equal(measures.body.value,6000);
  assert.deepEqual(measures.reach,{from:50000,to:44500,value:5500,top:15000});
  assert.equal(measureDistances(players,[],[[-5000,0,-1000,1000]]).reach.value,-1000);
  assert.equal(measureDistances(players,[],[]).reach,null);
});
test('Touching and overlapping pushbox projections have explicit gap/overlap labels',()=>{
  const players=[{x:0,y:0,facing:1},{x:5000,y:0,facing:-1}];
  const touching=measureDistances(players,[[-2000,0,2000,10000],[2000,0,7000,10000]]);
  assert.equal(touching.body.value,0);assert.equal(touching.body.overlap,false);
  const contained=measureDistances(players,[[-2000,0,7000,10000],[2000,5000,5000,15000]]);
  assert.equal(contained.body.value,3000);assert.equal(contained.body.overlap,true);assert.match(distanceSummary(contained),/Body overlap 30 px/);
  assert.equal(pixels(8700),'87 px');assert.equal(pixels(-125),'-1.25 px');assert.equal(pixels(0),'0 px');
});
