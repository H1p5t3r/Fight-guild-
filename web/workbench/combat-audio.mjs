// Explicit opt-in, gesture-unlocked sound. Scrubbing/repainting is always silent.
export function soundFor(cue,manifest){
  if(manifest.kinds[cue.kind])return manifest.kinds[cue.kind];
  const profile=manifest.characters[cue.character],family=profile.moves[cue.move]??profile.family;
  return (cue.kind===8?'swing_':'hit_')+family;
}
export class CombatAudio {
  constructor(pack){this.pack=pack;this.enabled=false;this.buffers=new Map();this.sources=new Set();this.played=0;}
  async sounds(){
    if(this.pack.audio.sounds)return this.pack.audio.sounds;
    if(!globalThis.FIGHT_WORKSHOP_SOUNDS){
      // A deferred classic script also works in the extracted file:// ZIP.
      await new Promise((resolve,reject)=>{
        const script=document.createElement('script');script.src=this.pack.audio.script;
        script.onload=()=>{script.remove();resolve();};
        script.onerror=()=>{script.remove();reject(new Error('Sound could not load. Try again when the connection is available.'));};
        document.head.append(script);
      });
    }
    return globalThis.FIGHT_WORKSHOP_SOUNDS;
  }
  async enable(){
    const Context=globalThis.AudioContext??globalThis.webkitAudioContext;
    if(!Context)throw new Error('Sound is not supported in this browser.');
    this.context??=new Context();await this.context.resume();
    if(!this.limiter){
      this.limiter=this.context.createDynamicsCompressor();
      this.limiter.threshold.value=-3;this.limiter.knee.value=0;this.limiter.ratio.value=20;
      this.limiter.attack.value=.001;this.limiter.release.value=.06;this.limiter.connect(this.context.destination);
    }
    await Promise.all(Object.entries(await this.sounds()).map(async([key,url])=>{
      if(this.buffers.has(key))return;
      const bytes=Uint8Array.from(atob(url.split(',')[1]),c=>c.charCodeAt(0));
      this.buffers.set(key,await this.context.decodeAudioData(bytes.buffer));
    }));
    this.enabled=true;
  }
  silence(){for(const s of this.sources){try{s.stop();}catch{}}this.sources.clear();}
  disable(){this.enabled=false;this.silence();}
  play(cue){
    if(!this.enabled||this.context?.state!=='running')return;
    const key=soundFor(cue,this.pack.audio.manifest),buffer=this.buffers.get(key);if(!buffer)return;
    if(this.sources.size>=16){const oldest=this.sources.values().next().value;oldest.stop();this.sources.delete(oldest);}
    const source=this.context.createBufferSource(),gain=this.context.createGain();source.buffer=buffer;
    source.playbackRate.value=.97+((cue.serial*7+cue.actor*3)%7)*.01;
    gain.gain.value=.65*10**((-14+cue.strength*.6-(cue.kind===8?5:cue.kind===9&&!cue.strength?6:0))/20);
    source.connect(gain);gain.connect(this.limiter);source.onended=()=>this.sources.delete(source);
    this.sources.add(source);source.start();this.played++;
    if(cue.kind===3)this.play({...cue,kind:1});
  }
  advance(record,from,to){
    if(to<=from)return;
    // At 60/30 Hz every intervening contact plays. After a stalled tab, skip stale audio.
    for(let i=Math.max(from+1,to-5);i<=to;i++)for(const cue of record.frames[i]?.cues??[])this.play(cue);
  }
}
