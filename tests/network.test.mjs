import {test} from 'node:test';
import assert from 'node:assert/strict';
import {WebSocket} from 'ws';
import {createServer} from '../scripts/server.mjs';
import {readFile} from 'node:fs/promises';
import {Engine} from '../web/engine.mjs';
import {RollbackSession,scriptedInput} from '../web/rollback.mjs';

test('Room relay matches clients, forwards inputs, rejects data mismatch, and cleans up',async()=>{
  const {server,wss,rooms}=createServer();
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const port=server.address().port;
  const sockets=[];
  async function client(){
    const ws=new WebSocket(`ws://127.0.0.1:${port}/netplay`);sockets.push(ws);
    const queue=[],waiting=[];
    ws.on('message',bytes=>{const msg=JSON.parse(bytes);const resolver=waiting.shift();if(resolver)resolver(msg);else queue.push(msg);});
    await new Promise(resolve=>ws.on('open',resolve));
    return {ws,send:data=>ws.send(JSON.stringify(data)),next:()=>queue.length?Promise.resolve(queue.shift()):new Promise((resolve,reject)=>{
      const timeout=setTimeout(()=>reject(new Error('Timed out waiting for server')),3000);
      waiting.push(value=>{clearTimeout(timeout);resolve(value);});
    })};
  }
  try {
    const response=await fetch(`http://127.0.0.1:${port}/generated/fight.wasm`);assert.equal(response.status,200);assert.equal(response.headers.get('content-type'),'application/wasm');
    const a=await client(),b=await client(),bad=await client();
    a.send({type:'host',fingerprint:'1-12345678',character:0,simple:true});const room=await a.next();assert.equal(room.type,'waiting');
    bad.send({type:'join',code:room.code,fingerprint:'1-87654321',character:1,simple:false});assert.match((await bad.next()).message,/Move data differs/);
    b.send({type:'join',code:room.code,fingerprint:'1-12345678',character:1,simple:false});
    assert.equal((await a.next()).player,0);assert.equal((await b.next()).player,1);
    const module=await WebAssembly.compile(await readFile(new URL('../web/generated/fight.wasm',import.meta.url)));
    const engines=await Promise.all([0,1,2].map(async()=>new Engine(await WebAssembly.instantiate(module))));
    engines.forEach(e=>e.reset([0,1],[true,false]));
    const peers=engines.slice(0,2).map(e=>new RollbackSession(e));
    for(let f=0;f<180;++f) {
      const inputs=[scriptedInput(f,0),scriptedInput(f,1)];engines[2].step(...inputs);
      peers[0].submit(0,f,inputs[0]);peers[1].submit(1,f,inputs[1]);
      peers.forEach(p=>p.advance()); // Predict before this frame's packet arrives.
      a.send({type:'input',frame:f,input:inputs[0]});b.send({type:'input',frame:f,input:inputs[1]});
      const [toA,toB]=await Promise.all([a.next(),b.next()]);
      peers[0].submit(1,toA.frame,toA.input);peers[1].submit(0,toB.frame,toB.input);
      assert.equal(engines[0].hash,engines[2].hash);assert.equal(engines[1].hash,engines[2].hash);
    }
    a.send({type:'leave'});assert.equal((await b.next()).type,'ended');assert.equal(rooms.size,0);
  } finally {sockets.forEach(s=>s.terminate());await new Promise(resolve=>wss.close(resolve));await new Promise(resolve=>server.close(resolve));}
});
