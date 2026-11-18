import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';

export async function serveWorkshop(port=8081,host='127.0.0.1') {
  const html=await readFile(new URL('../build/FightGuild-Move-Workshop.html',import.meta.url));
  const server=createServer((request,response)=>{
    if(!['GET','HEAD'].includes(request.method)) {response.writeHead(405);response.end();return;}
    const pathname=new URL(request.url,'http://localhost').pathname;
    if(!['/','/index.html'].includes(pathname)) {response.writeHead(404);response.end();return;}
    response.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-cache','X-Content-Type-Options':'nosniff'});
    response.end(request.method==='HEAD'?undefined:html);
  });
  await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(port,host,resolve);});
  return server;
}

export async function serveWorkshopSite(port=8081,host='127.0.0.1',mount='/') {
  if(!/^\/(?:[\w.-]+\/)*$/.test(mount))throw new Error('Site mount must start and end with a slash.');
  const folder=new URL('../build/move-workshop/',import.meta.url);
  const types={html:'text/html; charset=utf-8',js:'text/javascript; charset=utf-8',css:'text/css; charset=utf-8',webp:'image/webp',woff2:'font/woff2',json:'application/json',txt:'text/plain; charset=utf-8'};
  const server=createServer(async(request,response)=>{
    if(!['GET','HEAD'].includes(request.method)){response.writeHead(405);response.end();return;}
    const pathname=new URL(request.url,'http://localhost').pathname;
    if(mount!=='/'&&pathname===mount.slice(0,-1)){response.writeHead(308,{Location:mount});response.end();return;}
    const relative=pathname.startsWith(mount)?pathname.slice(mount.length):null;
    const name=relative===''?'index.html':relative;
    const hashed=/^assets\/[a-f0-9]{64}\.(?:webp|woff2|css|js)$/.test(name??'');
    if(!hashed&&!['index.html','version.json','FightGuild-moves.json','START_HERE.txt'].includes(name)){response.writeHead(404);response.end();return;}
    try{
      const body=await readFile(new URL(name,folder));
      response.writeHead(200,{'Content-Type':types[name.split('.').at(-1)],'Content-Length':body.length,'Cache-Control':hashed?'public, max-age=31536000, immutable':'no-cache','X-Content-Type-Options':'nosniff'});
      response.end(request.method==='HEAD'?undefined:body);
    }catch{response.writeHead(404);response.end();}
  });
  await new Promise((resolve,reject)=>{server.once('error',reject);server.listen(port,host,resolve);});
  return server;
}

if(process.argv[1]===fileURLToPath(import.meta.url)) {
  const server=await serveWorkshopSite(Number(process.env.PORT||8081),process.env.HOST||'127.0.0.1');
  console.log(`Move Workshop: http://${server.address().address}:${server.address().port}`);
}
