import http from 'node:http';
import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import path from 'node:path';
import {WebSocketServer,WebSocket} from 'ws';
import {randomBytes} from 'node:crypto';

export function createServer() {
  const root=fileURLToPath(new URL('../web/',import.meta.url));
  const server=http.createServer(async(req,res)=>{
    try {
      if(req.method!=='GET'&&req.method!=='HEAD') { res.writeHead(405).end(); return; }
      const url=new URL(req.url,'http://localhost');
      const relative=decodeURIComponent(url.pathname)==='/'?'index.html':decodeURIComponent(url.pathname).slice(1);
      const target=path.resolve(root,relative);
      if(!target.startsWith(root)) { res.writeHead(403).end(); return; }
      const body=await readFile(target);
      const types={'.html':'text/html; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css','.wasm':'application/wasm','.svg':'image/svg+xml','.png':'image/png'};
      res.writeHead(200,{'Content-Type':types[path.extname(target)]??'application/octet-stream','Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});
      res.end(req.method==='HEAD'?undefined:body);
    } catch { res.writeHead(404).end('Not found'); }
  });
  const rooms=new Map();
  const wss=new WebSocketServer({server,path:'/netplay',maxPayload:4096});
  const send=(socket,data)=>{if(socket?.readyState===WebSocket.OPEN) socket.send(JSON.stringify(data));};
  const leave=socket=>{
    const room=rooms.get(socket.room);
    if(!room) return;
    rooms.delete(socket.room);
    room.peers.forEach(peer=>{peer.room=null; if(peer!==socket) send(peer,{type:'ended',message:'Opponent disconnected. Start a new room to continue.'});});
    socket.room=null;
  };
  wss.on('connection',socket=>{
    socket.frames=0; socket.window=Date.now();
    socket.on('message',bytes=>{
      try {
        if(Date.now()-socket.window>1000) { socket.frames=0; socket.window=Date.now(); }
        if(++socket.frames>300) throw new Error('Message rate exceeded');
        const msg=JSON.parse(bytes.toString());
        if(msg.type==='host'||msg.type==='join') {
          if(socket.room) throw new Error('Already in a room');
          if(typeof msg.fingerprint!=='string'||!/^\d+-[0-9a-f]{8}(?:-[0-9a-f]{8})?$/.test(msg.fingerprint)) throw new Error('Invalid rules fingerprint');
          if(![0,1].includes(msg.character)||typeof msg.simple!=='boolean') throw new Error('Invalid fighter selection');
          if(msg.type==='host') {
            if(rooms.size>=100) throw new Error('Server is full');
            const code=randomBytes(3).toString('hex').toUpperCase();
            rooms.set(code,{peers:[socket],fingerprint:msg.fingerprint,selections:[{character:msg.character,simple:msg.simple}]});
            socket.room=code; socket.player=0;
            send(socket,{type:'waiting',code});
          } else {
            const code=String(msg.code).toUpperCase(); const room=rooms.get(code);
            if(!room||room.peers.length!==1) throw new Error('Room not found or full');
            if(room.fingerprint!==msg.fingerprint) throw new Error('Move data differs. Both players must import the same data or restore defaults.');
            room.peers.push(socket); room.selections.push({character:msg.character,simple:msg.simple});
            socket.room=code; socket.player=1;
            room.peers.forEach((peer,player)=>send(peer,{type:'start',player,code,selections:room.selections}));
          }
          return;
        }
        if(msg.type==='leave') { leave(socket); return; }
        const room=rooms.get(socket.room);
        if(!room||room.peers.length!==2) throw new Error('Match has not started');
        if(msg.type==='input') {
          if(!Number.isInteger(msg.frame)||msg.frame<0||msg.frame>3600000||!Number.isInteger(msg.input)||msg.input<0||msg.input>4095) throw new Error('Invalid input packet');
          send(room.peers[1-socket.player],{type:'input',frame:msg.frame,input:msg.input});
        } else if(msg.type==='hash') {
          if(!Number.isInteger(msg.frame)||msg.frame<0||!Number.isInteger(msg.hash)||msg.hash<0||msg.hash>0xffffffff) throw new Error('Invalid checksum');
          send(room.peers[1-socket.player],{type:'hash',frame:msg.frame,hash:msg.hash});
        } else throw new Error('Unknown message');
      } catch(error) { send(socket,{type:'error',message:error.message}); }
    });
    socket.on('close',()=>leave(socket));
    socket.on('error',()=>leave(socket));
  });
  server.on('close',()=>wss.close());
  return {server,wss,rooms};
}
if(process.argv[1]===fileURLToPath(import.meta.url)) {
  const port=Number(process.env.PORT??8080),host=process.env.HOST??'127.0.0.1';
  const {server}=createServer();
  server.listen(port,host,()=>console.log(`Fight Guild combat lab listening on ${host}:${port}`));
}
