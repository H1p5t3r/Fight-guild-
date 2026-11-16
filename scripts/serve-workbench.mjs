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

if(process.argv[1]===fileURLToPath(import.meta.url)) {
  const server=await serveWorkshop(Number(process.env.PORT||8081),process.env.HOST||'127.0.0.1');
  console.log(`Move Workshop: http://${server.address().address}:${server.address().port}`);
}
