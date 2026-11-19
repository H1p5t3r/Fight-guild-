import {legacyPack,legacyData,stripExtensions} from './legacy-data.mjs';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
import {Engine,FIELDS,MOVEMENT_FIELDS,INPUT} from '../web/engine.mjs';
import {Workshop,validate,parseField,totalFrames,blockAdvantage,phaseAt,attackBoxes,defaultHurtboxes,META} from '../web/workbench/model.mjs';
import {SPECS,GROUPS} from '../web/workbench/specs.mjs';
import {validateReferences,MAX_REFERENCE_DATA} from '../web/workbench/references.mjs';

const shippedPack=JSON.parse(await readFile(new URL('../build/workbench-pack.json',import.meta.url),'utf8')),pack=legacyPack(shippedPack);
const wasm=await WebAssembly.compile(await readFile(new URL('../web/generated/fight.wasm',import.meta.url)));
const engine=async()=>new Engine(await WebAssembly.instantiate(wasm));

test('Shipped data and each editable field match the current combat core',async()=>{
  const e=await engine();assert.deepEqual(shippedPack.defaults,e.data());
  const controls=GROUPS.flatMap(g=>g.fields);
  assert.equal(new Set(controls).size,controls.length);
  assert.deepEqual(FIELDS.filter(k=>!controls.includes(k)),['wallDamage','smearMode','smearPart','smearStretch','smearFrame1','smearFrame2','smearFrame3','smearFrame4']); // inactive compatibility slots
  assert.equal(Object.keys(SPECS).length,FIELDS.length);
  for(let c=0;c<6;c++){
    for(const [field,key] of FIELDS.entries()){
      e.api.fg_defaults(); // Coupled startup limits depend on the default classification.
      if(key==='motion') {for(const value of [0,214,236,623])assert.equal(e.api.fg_move_set(c,0,field,value),1);continue;}
      const {min,max}=pack.limits.moves[c][key];
      for(const value of [min,max])assert.equal(e.api.fg_move_set(c,0,field,value),1,`${c} ${key} boundary`);
      for(const value of [min-1,max+1])assert.equal(e.api.fg_move_set(c,0,field,value),0,`${c} ${key} outside`);
    }
    for(const [field,key] of MOVEMENT_FIELDS.entries())for(const value of Object.values(pack.limits.movement[c][key]))assert.equal(e.api.fg_mobility_set(c,field,value),1);
  }
  let index=0;for(const fields of Object.values(pack.limits.rules))for(const range of Object.values(fields)){
    for(const value of [range.min,range.max])assert.equal(e.api.fg_rule_set(index,value),1);
    for(const value of [range.min-1,range.max+1])assert.equal(e.api.fg_rule_set(index,value),0);index++;
  }
});

test('Edits preserve the rest of the roster, rules and notes through a core round trip',async()=>{
  const w=new Workshop(pack),before=w.snapshot();
  w.change(5,0,'startup',7);w.change(5,0,'damage',44);w.change(5,0,'reach',9613);
  w.change(4,28,'airLaunch',1300);w.change(4,28,'normalRoutes',1);
  w.setNote(5,0,'windup','Lower the shoulder; lead with the knife.');
  const data=JSON.parse(w.export()),e=await engine();e.loadData(data);
  const withoutNotes=structuredClone(data);delete withoutNotes[META];assert.deepEqual(e.data(),withoutNotes);
  for(const key of Object.keys(before).filter(k=>k.endsWith('Rules')))assert.deepEqual(data[key],before[key]);
  assert.deepEqual(data.characters.slice(0,4),before.characters.slice(0,4));
  const restored=new Workshop(pack,data);assert.equal(restored.note(5,0).windup,w.note(5,0).windup);
  await writeFile(new URL('../build/workshop-roundtrip.json',import.meta.url),w.export());
});

test('Invalid imports and edits never partially change a draft',()=>{
  const w=new Workshop(pack);w.change(5,0,'damage',76);const saved=w.snapshot(),history=w.undoStack.length;
  const corruptions=[d=>d.schema=11,d=>d.characters.pop(),d=>d.characters[5].moves[31].startup=4,
    d=>d.characters[5].moves[31].startup=5.5,d=>d.characters[5].moves[31].reach=4294967396,
    d=>d.characters[5].moves[31].motion=215,d=>delete d.characters[0].movement,
    d=>d.characters[0].moves.reverse(),d=>d.momentumRules.fdDrain=0,
    d=>d[META]={version:1,notes:{'Fillet/5P':{windup:47}}}];
  for(const corrupt of corruptions){const data=w.snapshot();corrupt(data);assert.throws(()=>w.import(data));assert.deepEqual(w.snapshot(),saved);assert.equal(w.undoStack.length,history);}
  assert.throws(()=>w.change(5,0,'startup',2));assert.deepEqual(w.snapshot(),saved);
});

test('Fixed-point units and frame convention are exact',()=>{
  const limit=pack.limits.moves[5];assert.equal(parseField('reach','86.13',limit.reach),8613);
  assert.equal(parseField('bottom','-0.01',limit.bottom),-1);
  for(const input of ['', '2', '5.1','Infinity','5e20'])assert.throws(()=>parseField('startup',input,limit.startup));
  assert.throws(()=>parseField('reach','86.131',limit.reach));
  const m=pack.defaults.characters[5].moves[0];assert.equal(totalFrames(m),16);assert.equal(blockAdvantage(m),0);
  assert.equal(phaseAt(m,4),'windup');assert.equal(phaseAt(m,5),'active');assert.equal(phaseAt(m,7),'active');assert.equal(phaseAt(m,8),'recovery');
});

test('Undo, redo, reset and import keep independent art notes and unknown data',()=>{
  const w=new Workshop(pack),initial=w.snapshot();w.change(5,0,'startup',6);w.change(5,0,'startup',7);
  assert.equal(w.undoStack.length,1);w.undo();assert.deepEqual(w.snapshot(),initial);w.redo();assert.equal(w.move(5,0).startup,7);
  w.setNote(5,0,'active','<script>literal art notes</script>');w.resetMove(5,0);assert.equal(w.move(5,0).startup,5);assert.ok(w.note(5,0).active);
  w.undo();assert.equal(w.move(5,0).startup,7);
  const next=w.snapshot();next.futureMetadata={kept:true};next.characters[3].moves[8].futureField=5;w.import(next);
  assert.deepEqual(JSON.parse(w.export()).futureMetadata,{kept:true});assert.equal(JSON.parse(w.export()).characters[3].moves[8].futureField,5);
  assert.match(w.brief(),/literal art notes/);w.undo();assert.equal(w.snapshot().futureMetadata,undefined);
});

test('Resetting an older Fillet draft cannot install part of the new kit',()=>{
  const w=new Workshop(shippedPack,legacyData(shippedPack.defaults));
  const before=w.snapshot();
  w.change(5,0,'damage',77);w.setNote(5,0,'active','Keep this older pose direction.');
  w.resetMove(5,0);w.resetMove(5,45);w.resetMovement(5);
  const data=JSON.parse(w.export()),fillet=data.characters[5];
  assert.deepEqual(fillet.moves[0],before.characters[5].moves[0]);
  assert.equal(fillet.extensions,undefined);assert.ok(fillet.moves.every(m=>!m.extensions));
  assert.ok(fillet.moves.slice(45).every(m=>!m.enabled));
  assert.deepEqual(fillet.movement,before.characters[5].movement);
  assert.equal(w.note(5,0).active,'Keep this older pose direction.');
  const current=new Workshop(shippedPack);
  current.change(5,0,'damage',77);current.resetMove(5,0);
  assert.deepEqual(current.move(5,0),shippedPack.defaults.characters[5].moves[0]);
  assert.ok(current.data.characters[5].extensions);
});

test('Pose references travel with JSON, count as edits and survive stat resets and history',()=>{
  const w=new Workshop(pack),png='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==';
  const ref={id:'pose-1',phase:'windup',caption:'Rear foot planted',name:'stance.png',src:png};
  w.addReferences(5,0,[ref]);assert.equal(w.changed(5,0),true);assert.equal(w.changes().length,1);
  w.editReference(5,0,'pose-1','phase','active');w.editReference(5,0,'pose-1','caption','Long arm, square hips');
  const imported=new Workshop(pack,JSON.parse(w.export()));assert.deepEqual(imported.note(5,0).references,w.note(5,0).references);
  assert.equal(imported.note(4,0).references,undefined);assert.match(w.brief(),/Active · stance.png — Long arm, square hips/);assert.match(w.brief(),/embedded in the companion JSON/);
  w.change(5,0,'startup',7);w.resetMove(5,0);assert.equal(w.note(5,0).references.length,1);
  w.removeReference(5,0,'pose-1');assert.equal(w.note(5,0).references.length,0);w.undo();assert.equal(w.note(5,0).references[0].src,png);
  w.redo();assert.equal(w.note(5,0).references.length,0);
  const before=imported.snapshot();
  const invalid=[{...ref,id:'pose-2',src:'https://example.com/reference.png'}, {...ref,id:'pose-2',src:'data:image/svg+xml;base64,PHN2Zz4='},
    {...ref,id:'pose-2',src:'data:image/png;base64,PHN2Zz4='}, {...ref,id:'pose-2',phase:'unknown'}, {...ref,id:'pose-2',caption:'x'.repeat(1001)},
    {...ref,id:'pose-2',src:png+'x'.repeat(MAX_REFERENCE_DATA)},ref];
  for(const image of invalid){assert.throws(()=>imported.addReferences(5,0,[image]));assert.deepEqual(imported.snapshot(),before);}
  assert.throws(()=>imported.addReferences(5,0,[{...ref,id:'2'},{...ref,id:'3'},{...ref,id:'4'}]));assert.deepEqual(imported.snapshot(),before);
  const broken=structuredClone(before);broken[META].notes['Fillet/5P'].references[0].src='data:text/html;base64,PHN2Zz4=';
  assert.throws(()=>imported.import(broken));assert.deepEqual(imported.snapshot(),before);
  assert.equal(validateReferences([ref]),png.length);
});

test('Per-attack hurtboxes migrate, export, affect the engine and reject invalid profiles atomically',async()=>{
  const w=new Workshop(pack),legacy=w.snapshot();legacy.schema=legacy.coreVersion=12;stripExtensions(legacy);
  for(const c of legacy.characters)for(const m of c.moves)delete m.hurtboxes;
  legacy.characters[5].moves[0].damage=77;legacy[META]={version:1,notes:{'Fillet/5P':{windup:'Keep these old notes.'}}};
  const migrated=new Workshop(pack,legacy);assert.equal(migrated.data.schema,23);assert.equal(migrated.move(5,0).damage,77);assert.deepEqual(migrated.move(5,0).hurtboxes,{});assert.equal(migrated.note(5,0).windup,'Keep these old notes.');
  const active=defaultHurtboxes(pack,5,w.move(5,0),5);active.torsoArms=[-2000,6000,4000,11000];delete active.extension;
  w.setHurtPhase(5,0,'active',active);assert.equal(w.changed(5,0),true);assert.deepEqual(w.move(5,4).hurtboxes,{});
  const e=await engine(),fingerprint=e.fingerprint();e.loadData(JSON.parse(w.export()));assert.notEqual(e.fingerprint(),fingerprint);
  e.reset([5,0]);e.step(INPUT.P,0);for(let i=1;i<5;i++)e.step(0,0);
  const f=e.state().players[0],boxes=e.boxes(0,0).map(b=>[b[0]-f.x,b[1]-f.y,b[2]-f.x,b[3]-f.y]);
  assert.equal(boxes.length,3);assert.deepEqual(boxes[1],active.torsoArms);assert.deepEqual(e.data(),w.snapshot());
  const before=w.snapshot(),fingerprintEdited=e.fingerprint();
  const broken=[{...active,weapon:[0,0,100,100]}, {...active,head:undefined}, {...active,head:[0,0,0,100]}, {...active,head:[0,0,100,99]}, {...active,head:[0,0,100,50001]}, {...active,head:[0,0,100,100.5]}];
  for(const bad of broken){
    assert.throws(()=>w.setHurtPhase(5,0,'active',bad));assert.deepEqual(w.snapshot(),before);
    const data=structuredClone(before);data.characters[5].moves[31].hurtboxes={active:bad};assert.throws(()=>e.loadData(data));assert.equal(e.fingerprint(),fingerprintEdited);
  }
  w.setHurtPhase(5,0,'active',null);assert.deepEqual(w.move(5,0).hurtboxes,{});w.undo();assert.deepEqual(w.move(5,0).hurtboxes.active,active);w.redo();assert.deepEqual(w.move(5,0).hurtboxes,{});
});

test('Straight, throw and both diagonal hook previews use the core collision geometry',async()=>{
  // Rebind each tested slot to 5P, disabling the other slots. This exercises the
  // real simulation at every active frame without needing test-only core APIs.
  for(const [c,slot] of [[5,0],[5,23],[4,28],[4,29]]){
    const e=await engine(),data=legacyData(e.data()),m=data.characters[c].moves[slot];
    for(const move of data.characters[c].moves)move.enabled=0;
    Object.assign(m,{enabled:1,button:0,direction:5,motion:0,air:0,category:slot===23?4:2,followFrom:-1,followFrom2:-1});
    e.loadData(data);e.reset([c,0]);e.step(slot===23?INPUT.left|INPUT.P|INPUT.K:INPUT.P,0);assert.equal(e.state().players[0].move,slot);
    const checked=new Set();
    for(let i=0;i<totalFrames(m)+60;i++){
      const f=e.state().players[0],boxes=e.boxes(0,2);
      if(boxes.length){
        const local=boxes.map(b=>[b[0]-f.x,b[1]-f.y,b[2]-f.x,b[3]-f.y]);
        assert.deepEqual(attackBoxes(m,f.age,pack.collisions[c].push),local,`${c}/${slot} frame ${f.age}`);checked.add(f.age);
      }
      e.step(0,0);
    }
    assert.equal(checked.size,m.active);
  }
});
