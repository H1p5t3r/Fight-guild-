import {loadEngine,CHARACTERS,MOVE_IDS,BUTTONS,FIELDS} from './engine.mjs';
import {RollbackSession,rollbackTrial,scriptedInput} from './rollback.mjs';
const $=id=>document.getElementById(id);
const status=(id,message,error=false)=>{ $(id).textContent=message; $(id).classList.toggle('error',error); };
const STORAGE='fight-guild-moves-v1';
const keyMaps=[{KeyA:1,KeyD:2,KeyS:4,KeyW:8,KeyJ:16,KeyK:32,KeyL:64,KeyI:128,KeyO:256,Space:512,ShiftLeft:1024},
  {ArrowLeft:1,ArrowRight:2,ArrowDown:4,ArrowUp:8,Numpad1:16,Numpad2:32,Numpad3:64,Numpad5:128,Numpad6:256,Numpad0:512,NumpadAdd:1024}];
let engine,mode='training',paused=false,showBoxes=true,selection={characters:[0,1],simple:[false,false]};
let net=null,keys=new Set(),history=[],lastRaw=0,accumulator=0;
const canvas=$('arena'),ctx=canvas.getContext('2d');
const editable=()=>['INPUT','SELECT','TEXTAREA','BUTTON'].includes(document.activeElement?.tagName);
const dialogOpen=()=>$('select-dialog').open||$('help-dialog').open;
function gamepadInput(index) {
  const pad=[...(navigator.getGamepads?.()??[])].filter(Boolean)[index];
  if(!pad) return 0;
  const down=i=>pad.buttons[i]?.pressed;
  let bits=0;
  if(down(14)||pad.axes[0]<-.35) bits|=1;
  if(down(15)||pad.axes[0]>.35) bits|=2;
  if(down(13)||pad.axes[1]>.35) bits|=4;
  if(down(12)||pad.axes[1]<-.35) bits|=8;
  [0,2,3,1,5,4,6].forEach((button,b)=>{ if(down(button)) bits|=16<<b; });
  return bits;
}
function readInput(p) {
  if(dialogOpen()||editable()) return 0;
  let input=gamepadInput(p);
  for(const key of keys) input|=keyMaps[p][key]??0;
  return input;
}
window.addEventListener('keydown',e=>{
  if(dialogOpen()||editable()) return;
  if(keyMaps.some(map=>map[e.code])) { e.preventDefault(); keys.add(e.code); }
});
window.addEventListener('keyup',e=>keys.delete(e.code));
window.addEventListener('blur',()=>keys.clear());
document.addEventListener('visibilitychange',()=>{keys.clear(); accumulator=0;});
function reset() {
  if(net) return;
  engine.reset(selection.characters,selection.simple); keys.clear(); history=[]; lastRaw=0; accumulator=0;
  $('input-history').textContent='—';
  paused=false; $('pause').textContent='Pause';
  canvas.focus();
}
function localStep() {
  let a=readInput(0),b=readInput(1);
  if(mode==='training') {
    const s=engine.state(),toward=s.players[1].x>s.players[0].x?1:2,away=toward===1?2:1;
    b=$('dummy').value==='guard'?away:$('dummy').value==='crouch'?away|4:$('dummy').value==='fight'?scriptedInput(s.frame,1):0;
  }
  engine.step(a,b); recordInput(a);
}
function recordInput(raw) {
  if(raw&&raw!==lastRaw) {
    const p=engine.state().players[net?.player??0];
    const x=(((raw&2)!==0)-((raw&1)!==0))*p.facing,y=((raw&8)!==0)-((raw&4)!==0);
    const dir=5+x+y*3;
    let text=['','↙','↓','↘','←','·','→','↖','↑','↗'][dir];
    for(let b=0;b<5;++b) if(raw&(16<<b)) text+=BUTTONS[b];
    if(raw&512) text+='Dash'; if(raw&1024) text+='*';
    history.push(text); history=history.slice(-8);
    $('input-history').replaceChildren(...history.map(value=>{const span=document.createElement('span');span.textContent=value;return span;}));
  }
  lastRaw=raw;
}

function rect(x,y,w,h,color) {ctx.fillStyle=color;ctx.fillRect(x,y,w,h);}
function text(value,x,y,size=12,color='#dce3e6',align='left',weight=500) {
  ctx.fillStyle=color;ctx.font=`${weight} ${size}px system-ui, sans-serif`;ctx.textAlign=align;ctx.fillText(value,x,y);
}
function makeSprite(character) {
  const sprite=document.createElement('canvas'); sprite.width=64;sprite.height=96;
  const g=sprite.getContext('2d');
  const r=(x,y,w,h,c)=>{g.fillStyle=c;g.fillRect(x,y,w,h);};
  const coat=character?'#a37a58':'#708b9c',light=character?'#d9ae79':'#b1c3cb',dark='#26353f';
  // Original pixel placeholders. Art direction and production animation are separate work.
  r(18,77,11,16,dark);r(39,76,10,17,dark);r(14,88,17,7,'#17232c');r(37,88,18,7,'#17232c');
  r(16,33,34,46,dark);r(20,34,26,39,coat);r(20,35,7,29,light);r(16,65,34,8,'#332f2a');r(29,65,9,7,'#dfad59');
  r(23,9,24,26,'#252c30');r(26,14,20,17,'#d8b18e');r(25,10,23,8,character?'#bd9f78':'#a1adb1');r(34,21,11,3,'#303943');
  r(25,29,20,8,character?'#b18b58':'#b6c7ce');r(10,39,10,29,coat);r(46,38,10,28,light);r(48,60,9,9,'#d8b18e');
  if(character) {r(52,16,4,58,'#674a35');r(43,5,21,21,'#394b58');r(44,7,20,7,'#a2b5bf');r(49,6,4,21,'#d1b674');}
  else {r(6,47,23,34,'#1c3544');r(7,48,21,4,'#c2d0d2');r(9,53,17,24,'#738f9e');r(15,58,6,13,'#dbb16a');r(53,45,3,27,'#765c43');r(48,41,14,9,'#c1c7c3');}
  return sprite;
}
const sprites=[makeSprite(0),makeSprite(1)];
function draw() {
  if(!engine) return;
  const state=engine.state();
  const gradient=ctx.createLinearGradient(0,0,0,560); gradient.addColorStop(0,'#1b2731');gradient.addColorStop(1,'#35454e');ctx.fillStyle=gradient;ctx.fillRect(0,0,1100,560);
  for(let i=0;i<12;++i) {rect(i*100,95,1,365,'#91afbc0d');rect(0,100+i*50,1100,1,'#91afbc08');}
  ctx.strokeStyle='#c5d2d708';ctx.lineWidth=2;
  for(let i=-8;i<14;++i){ctx.beginPath();ctx.moveTo(550+i*70,450);ctx.lineTo(550+i*180,560);ctx.stroke();}
  text('F G',550,270,110,'#bacbd20a','center',900);text('COMBAT DEVELOPMENT',550,299,10,'#b5c9d223','center',600);
  rect(0,450,1100,3,'#879ba6');rect(0,453,1100,2,'#17242d');
  state.players.forEach((p,index)=>{
    const left=index===0; const x=left?40:650;
    text(CHARACTERS[p.character].toUpperCase(),left?40:1060,35,16,'#f0ede5',left?'left':'right',700);
    text(`${net?`PLAYER ${index+1}`:index===1&&mode==='training'?'DUMMY':'PLAYER '+(index+1)} / ${p.simple?'SIMPLE + MOTIONS':'MOTION INPUTS'}`,left?40:1060,52,9,'#a7bac7',left?'left':'right');
    rect(x,65,410,14,'#101b22');const w=410*p.health/1000;rect(left?x:x+410-w,65,w,14,index?'#8aafc2':'#edba72');
    rect(x,65,410,1,'#e3e8e138');text(String(p.health),left?40:1060,95,10,'#a4b6c1',left?'left':'right');
    const px=p.x/100*1.1,py=450-p.y/100*1.1;
    ctx.fillStyle='#07121a55';ctx.beginPath();ctx.ellipse(px,454,40,8,0,0,Math.PI*2);ctx.fill();
    const m=p.move>=0?engine.move(p.character,p.move):null;
    const active=m&&p.age>=m.startup&&p.age<m.startup+m.active;
    const crouched=p.y===0&&(p.raw&4),height=crouched?108:165;
    ctx.save();ctx.translate(px,py);ctx.scale(p.facing,1);ctx.imageSmoothingEnabled=false;
    if(p.stun&&!p.guarding) {ctx.rotate(-.09);ctx.globalAlpha=.85;}
    ctx.drawImage(sprites[p.character],-54,-height,110,height);
    if(m) {
      rect(22,-height*.65,active?70:35,13,index?'#d7ae77':'#a5c1cb');
      if(active) {rect(m.reach/100-25,-height*.6,5,35,'#f7cc7a');rect(m.reach/100-35,-height*.6-8,15,4,'#f7cc7a');}
    }
    if(p.guarding) {ctx.strokeStyle='#83b9d7';ctx.lineWidth=3;ctx.beginPath();ctx.arc(10,-height*.5,60,-1.3,1.3);ctx.stroke();}
    ctx.restore();
    if(showBoxes) {
      ctx.strokeStyle='#80bfd088';ctx.lineWidth=1;ctx.strokeRect(px-24,py-(crouched?99:165),48,crouched?99:165);
      if(active) {
        const back=p.x/100+p.facing*12,front=p.x/100+p.facing*m.reach/100;
        ctx.fillStyle='#ffaf4033';ctx.strokeStyle='#ffc06c';
        const bx=Math.min(back,front)*1.1,by=py-(m.bottom+m.height)/100*1.1,bw=Math.abs(front-back)*1.1,bh=m.height/100*1.1;
        ctx.fillRect(bx,by,bw,bh);ctx.strokeRect(bx,by,bw,bh);
      }
    }
    text(m?`${MOVE_IDS[p.move]} · ${p.age}f`:p.stun?(p.guarding?'BLOCKSTUN':'HITSTUN'):'READY',px,py+25,10,'#c1cdd3','center');
    if(p.combo>1&&state.players[1-index].stun) text(`${p.combo} HITS`,index?920:180,180,28,'#f4bf77','center',700);
  });
  text(String(Math.ceil(state.remaining/60)).padStart(2,'0'),550,70,40,'#eee9dd','center',600);
  if(paused) text('PAUSED',550,125,12,'#f4bf77','center');
  if(state.winner>=0) {
    rect(0,175,1100,140,'#10191ee8');
    text(state.winner===2?'DRAW':`${CHARACTERS[state.players[state.winner].character].toUpperCase()} TAKES THE ROUND`,550,232,30,'#f0c385','center',700);
    text(net?'Leave and create a new room to rematch.':'Press Reset to run it back.',550,272,13,'#b7c6ce','center');
  }
  $('frame-count').textContent=`FRAME ${String(state.frame).padStart(5,'0')}`;
  const p=state.players[net?.player??0],m=p.move>=0?engine.move(p.character,p.move):null;
  $('combat-state').textContent=state.hitstop?`HITSTOP · ${state.hitstop}f`:m?(p.age<m.startup?'STARTUP':p.age<m.startup+m.active?'ACTIVE':'RECOVERY')+' · '+(p.contact?'CONTACT CONFIRMED':'NO CONTACT'):p.stun?`${p.guarding?'BLOCK':'HIT'}STUN · ${p.stun}f`:'NEUTRAL';
  $('last-action').textContent=p.lastMove<0?'Ready':`${MOVE_IDS[p.lastMove]}${p.contact?' · '+(p.event===2?'BLOCK':'HIT'):''}`;
}

const numericFields=[
  ['frame-fields','startup','Startup',1,120],['frame-fields','active','Active',1,120],['frame-fields','recovery','Recovery',0,180],
  ['frame-fields','damage','Damage',0,1000],['frame-fields','hitstun','Hitstun',0,180],['frame-fields','blockstun','Blockstun',0,180],
  ['frame-fields','hitstop','Hitstop',0,30],['frame-fields','pushback','Push (px)',0,200,100],['frame-fields','advance','Advance (px)',-100,100,100],
  ['box-fields','reach','Reach',1,500,100],['box-fields','bottom','Bottom',-500,500,100],['box-fields','height','Height',1,500,100],
  ['advanced-fields','direction','Direction',1,9],['advanced-fields','simpleDirection','Simple dir.',0,9],['advanced-fields','normalRoutes','Normal routes',-1,31],['advanced-fields','commandRoutes','Command routes',-1,31]
];
function setupEditor() {
  MOVE_IDS.forEach((id,i)=>$('edit-move').add(new Option(id,i)));
  for(const [parent,key,label,min,max,scale=1] of numericFields) {
    const el=document.createElement('label');el.textContent=label;
    const input=document.createElement('input');Object.assign(input,{type:'number',id:`field-${key}`,min,max,step:scale===100?.01:1,required:true});
    input.dataset.scale=scale;el.append(input);$(parent).append(el);
  }
  for(const [key,label] of [['specialCancel','Special cancel'],['jumpCancel','Jump cancel'],['whiffCancel','Whiff cancel'],['selfCancel','Self cancel']]) {
    const el=document.createElement('label'),input=document.createElement('input');input.type='checkbox';input.id=`field-${key}`;el.append(input,document.createTextNode(label));$('cancel-fields').append(el);
  }
  for(const [key,label,values] of [
    ['button','Button',BUTTONS.map((b,i)=>[i,b])],['category','Category',[[0,'Normal'],[1,'Command'],[2,'Special'],[3,'Drive']]],
    ['motion','Motion',[[0,'None'],[236,'236'],[214,'214'],[623,'623']]],['air','State',[[0,'Ground'],[1,'Air']]],
    ['simpleButton','Simple button',BUTTONS.map((b,i)=>[i,b])],['hitLevel','Guard level',[[0,'Mid'],[1,'Low'],[2,'Overhead']]]
  ]) {
    const el=document.createElement('label');el.textContent=label;const select=document.createElement('select');select.id=`field-${key}`;
    values.forEach(([value,text])=>select.add(new Option(text,value)));el.append(select);$('advanced-fields').append(el);
  }
  populateEditor();
}
function populateEditor() {
  const c=Number($('edit-character').value),id=Number($('edit-move').value),m=engine.move(c,id);
  FIELDS.forEach(key=>{ const input=$(`field-${key}`);if(input) {if(input.type==='checkbox') input.checked=Boolean(m[key]);else input.value=m[key]/Number(input.dataset.scale??1);}});
  $('move-name').textContent=MOVE_IDS[id];$('move-kind').textContent=['NORMAL','COMMAND','SPECIAL','DRIVE'][m.category];
  $('move-summary').textContent=`${BUTTONS[m.button]} · ${m.air?'airborne':'grounded'}`;
  const routes=MOVE_IDS.filter((_,to)=>engine.api.fg_can_cancel(c,id,to,1));
  $('cancel-summary').textContent=`On contact → ${routes.join(', ')||'no attack cancels'}${m.jumpCancel?' / jump':''}. State restrictions still apply.`;
  $('buffer').value=engine.api.fg_rule_get(0);$('motion-window').value=engine.api.fg_rule_get(1);$('motion-gap').value=engine.api.fg_rule_get(2);
}
function lockNetwork(locked) {
  ['move-form','buffer-panel'].forEach(id=>{const scope=id==='move-form'?$(id):document.querySelector('.buffer-panel');scope.querySelectorAll('input,select,button').forEach(e=>e.disabled=locked);});
  for(const id of ['reset','pause','step','select-open','training-mode','versus-mode','dummy','import','restore','host','join']) $(id).disabled=locked;
  $('disconnect').hidden=!locked;
}
function stopNetwork(message='Offline · local play',error=false) {
  if(net) {const socket=net.socket;net=null;socket.close();}
  lockNetwork(false);reset();status('network-status',message,error);
}
function connect(type) {
  if(net) return;
  const socket=new WebSocket(`${location.protocol==='https:'?'wss':'ws'}://${location.host}/netplay`);
  net={socket,session:null,player:0,hashes:new Map(),lastHash:-1};lockNetwork(true);paused=false;
  status('network-status','Connecting…');
  socket.onopen=()=>socket.send(JSON.stringify({type,code:$('room-code').value.trim(),fingerprint:engine.fingerprint(),character:selection.characters[0],simple:selection.simple[0]}));
  socket.onmessage=e=>{
    if(net?.socket!==socket) return;
    try {
      const msg=JSON.parse(e.data);
      if(msg.type==='waiting') {status('network-status',`Room ${msg.code} · waiting for an opponent`);$('room-code').value=msg.code;}
      if(msg.type==='start') {
        engine.reset(msg.selections.map(s=>s.character),msg.selections.map(s=>s.simple));
        net.player=msg.player;net.session=new RollbackSession(engine);net.code=msg.code;
        // Both peers agree on two neutral startup frames (fixed input delay).
        for(let f=0;f<2;++f) for(let p=0;p<2;++p) net.session.submit(p,f,0);
        history=[];keys.clear();accumulator=0;canvas.focus();
      }
      if(msg.type==='input'&&net.session) net.session.submit(1-net.player,msg.frame,msg.input);
      if(msg.type==='hash') net.hashes.set(msg.frame,msg.hash);
      if(msg.type==='ended'||msg.type==='error') stopNetwork(msg.message,true);
    } catch(error) {stopNetwork(error.message,true);}
  };
  socket.onclose=()=>{if(net?.socket===socket) stopNetwork('Connection closed. Start a new room to reconnect.',true);};
  socket.onerror=()=>{if(net?.socket===socket) stopNetwork('Cannot reach the room server.',true);};
}
function networkStep() {
  if(!net?.session) return;
  try {
    const {session,player,socket}=net;
    const frame=engine.frame+2;
    if(session.actual.get(frame)?.[player]==null) {
      const input=readInput(0);session.submit(player,frame,input);
      socket.send(JSON.stringify({type:'input',frame,input}));recordInput(input);
    }
    const advanced=session.advance();
    const confirmed=Math.min(...session.confirmed,engine.frame-1);
    const checkpoint=Math.floor(confirmed/60)*60;
    if(checkpoint>=0&&checkpoint>net.lastHash) {
      const hash=session.confirmedHash(checkpoint);
      if(hash!==undefined) {socket.send(JSON.stringify({type:'hash',frame:checkpoint,hash}));net.lastHash=checkpoint;}
    }
    for(const [frame,hash] of net.hashes) {
      const own=session.confirmedHash(frame);
      if(own!==undefined) {
        if(own!==hash) throw new Error(`Desync at frame ${frame}. Match stopped; verify both clients use the same build and data.`);
        net.verifiedThrough=Math.max(net.verifiedThrough??-1,frame);net.hashes.delete(frame);
      }
    }
    status('network-status',`Room ${net.code} · Player ${player+1} · ${advanced?'connected':'waiting for input'} · ${session.rollbacks} rollbacks / max ${session.largest}f`);
  } catch(error) {stopNetwork(error.message,true);}
}
function bindUI() {
  $('select-open').onclick=()=>$('select-dialog').showModal();
  $('select-dialog').addEventListener('cancel',()=>{if(!engine.frame) canvas.focus();});
  $('selection').onsubmit=e=>{e.preventDefault();selection={characters:[Number($('p1-character').value),Number($('p2-character').value)],simple:[$('p1-simple').checked,$('p2-simple').checked]};$('select-dialog').close();reset();};
  $('help-open').onclick=()=>$('help-dialog').showModal();$('help-close').onclick=()=>{$('help-dialog').close();canvas.focus();};
  $('reset').onclick=reset;
  $('pause').onclick=()=>{paused=!paused;$('pause').textContent=paused?'Resume':'Pause';canvas.focus();};
  $('step').onclick=()=>{paused=true;$('pause').textContent='Resume';canvas.focus();localStep();draw();};
  $('boxes').onclick=()=>{showBoxes=!showBoxes;$('boxes').textContent=`Hitboxes ${showBoxes?'on':'off'}`;$('boxes').setAttribute('aria-pressed',showBoxes);canvas.focus();};
  for(const next of ['training','versus']) $(`${next}-mode`).onclick=()=>{mode=next;['training','versus'].forEach(m=>$(`${m}-mode`).classList.toggle('selected',m===mode));$('dummy').disabled=mode==='versus';reset();};
  $('edit-character').onchange=populateEditor;$('edit-move').onchange=populateEditor;
  $('move-form').onsubmit=e=>{
    e.preventDefault();if(net) return;
    try {
      const data=engine.data(),c=Number($('edit-character').value),id=Number($('edit-move').value);
      FIELDS.forEach(key=>{const input=$(`field-${key}`);if(input)data.characters[c].moves[id][key]=input.type==='checkbox'?Number(input.checked):Math.round(Number(input.value)*Number(input.dataset.scale??1));});
      engine.loadData(data);populateEditor();reset();status('editor-status',`${CHARACTERS[c]} ${MOVE_IDS[id]} applied. Save locally to keep this set.`);
    } catch(error) {status('editor-status',error.message,true);}
  };
  $('save').onclick=()=>{try{localStorage.setItem(STORAGE,JSON.stringify(engine.data()));status('editor-status','Move set saved in this browser. Export JSON for a portable backup.');}catch(e){status('editor-status',`Save failed: ${e.message}`,true);}};
  $('export').onclick=()=>{const url=URL.createObjectURL(new Blob([JSON.stringify(engine.data(),null,2)],{type:'application/json'}));const a=document.createElement('a');a.href=url;a.download='fight-guild-moves.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);status('editor-status','Move set exported.');};
  $('import').onclick=()=>$('import-file').click();
  $('import-file').onchange=async()=>{
    if(net) return;const file=$('import-file').files[0];if(!file)return;
    try{if(file.size>1000000)throw new Error('Move file exceeds 1 MB');engine.loadData(JSON.parse(await file.text()));populateEditor();reset();status('editor-status','Move set imported. Save locally to keep it.');}catch(e){status('editor-status',`Import failed: ${e.message}`,true);}finally{$('import-file').value='';}
  };
  $('restore').onclick=()=>{if(net)return;engine.api.fg_defaults();populateEditor();reset();status('editor-status','Defaults restored for this session. Save locally to replace the saved set.');};
  $('apply-buffer').onclick=()=>{
    if(net)return;try{const data=engine.data();['buttonBuffer','motionWindow','motionGap'].forEach((key,i)=>data.inputRules[key]=Number($(['buffer','motion-window','motion-gap'][i]).value));engine.loadData(data);reset();status('editor-status','Input settings applied.');}catch(e){status('editor-status',e.message,true);}
  };
  $('rollback-check').onclick=async()=>{
    $('rollback-check').disabled=true;status('rollback-result','Running 600 frames…');
    try{const reference=await loadEngine(),predicted=await loadEngine();for(const e of [reference,predicted]){e.loadData(engine.data());e.reset(selection.characters,selection.simple);}const result=rollbackTrial(reference,predicted);status('rollback-result',`${result.pass?'PASS':'FAIL'} · ${result.rollbacks} corrections · matching state ${result.corrected.toString(16)}`,!result.pass);}catch(e){status('rollback-result',e.message,true);}finally{$('rollback-check').disabled=false;}
  };
  $('host').onclick=()=>connect('host');$('join').onclick=()=>connect('join');$('disconnect').onclick=()=>stopNetwork();
  if(globalThis.FIGHT_STANDALONE) {
    $('host').disabled=$('join').disabled=true;
    status('network-status','Standalone build · local play and latency checks available. Run the repository server for room matches.');
  }
}
async function main() {
  try {
    engine=await loadEngine();
    try{const saved=localStorage.getItem(STORAGE);if(saved){engine.loadData(JSON.parse(saved));status('editor-status','Loaded your saved move set.');}}catch(error){status('editor-status',`Saved set could not be loaded: ${error.message}`,true);}
    setupEditor();bindUI();$('select-dialog').showModal();draw();
    // Exposes read-only diagnostics for automated smoke checks and bug reports.
    window.fightLab={state:()=>engine.state(),hash:()=>engine.hash,data:()=>engine.data(),net:()=>net?.session?{player:net.player,rollbacks:net.session.rollbacks,confirmed:[...net.session.confirmed],verifiedThrough:net.verifiedThrough??-1}:null};
    let previous=performance.now();
    const loop=now=>{
      const elapsed=Math.min(now-previous,100);previous=now;
      if(!dialogOpen()&&!paused) {
        accumulator+=elapsed;
        let count=0;
        while(accumulator>=1000/60&&count++<6) {if(net)networkStep();else localStep();accumulator-=1000/60;}
      } else accumulator=0;
      draw();requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
  } catch(error) {status('combat-state',error.message,true);status('editor-status',error.stack,true);}
}
main();
