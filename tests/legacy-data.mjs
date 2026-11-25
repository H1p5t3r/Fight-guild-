// Old behavior fixtures exercise migration and compatibility, independently of
// the selected v1 kit covered by fillet-v1.test.mjs / fillet_v1_test.cpp.
import {readFileSync} from 'node:fs';
const anvil=JSON.parse(readFileSync(new URL('../godot/tests/fixtures/anvil-pre-grappler.json',import.meta.url)));
const fillet=JSON.parse(readFileSync(new URL('../godot/data/legacy_fillet_v22.json',import.meta.url)));
const draftFillet=JSON.parse(readFileSync(new URL('../godot/data/workshop/2026-11-19-slash-sweeps/FightGuild-Slash-Sweeps.json',import.meta.url))).characters[5];
export function legacyData(data,source=fillet){
 const next=structuredClone(data),additions=next.characters[5].moves.slice(45).map(m=>{delete m.extensions;return {...m,enabled:0};});
 next.characters[0]=structuredClone(anvil);
 next.characters[5]=structuredClone(source);next.characters[5].moves.push(...additions);if(next.schema>=24)for(const m of next.characters[5].moves)Object.assign(m,{tetherDuration:180,tetherRange:45000,tetherGap:6000});if(next.schema>=26){next.comboRules.comboPhysics=0;for(const m of next.characters[5].moves)Object.assign(m,{comboDecay:5,starterDecay:0,groundHitSpeed:Math.ceil(m.pushback/6),airHitSpeed:Math.ceil(m.airPushback/6)});}if(next.schema>=27)for(const m of next.characters[5].moves)Object.assign(m,{driveDistance:0,drivePlus:4,driveNeutralFrames:12});return next;
}
export function stripExtensions(data){
 for(const c of data.characters??[]){delete c.extensions;if(c.moves.length===47)c.moves.length=45;for(const m of c.moves)delete m.extensions;}
 return data;
}
export function legacyPack(pack){return {...pack,defaults:legacyData(pack.defaults),draft:{...pack.draft,data:legacyData(pack.draft.data,draftFillet)}};}

// The user has frozen the browser workshop. Its JSON adapter intentionally
// does not implement native-only Anvil policy 2 yet. Keep those adapter tests
// on its published Anvil fixture; the native Anvil suites test the new kit.
export function frozenBrowserData(data){
 const next=structuredClone(data);next.characters[0]=structuredClone(anvil);return next;
}
export function frozenBrowserEngine(engine){engine.loadData(frozenBrowserData(engine.data()));return engine;}
