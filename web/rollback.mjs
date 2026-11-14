// Transport-independent input prediction. Only the C++ core owns combat state.
export class RollbackSession {
  constructor(engine,{maxPrediction=12,history=240}={}) {
    if(engine.frame!==0) throw new Error('Rollback sessions must begin at frame zero');
    this.engine=engine; this.maxPrediction=maxPrediction; this.history=history;
    this.actual=new Map(); this.records=new Map(); this.confirmed=[-1,-1];
    this.rollbacks=0; this.replayed=0; this.largest=0; this.baseInputs=[0,0];
  }
  submit(player,frame,input) {
    if(![0,1].includes(player)||!Number.isInteger(frame)||frame<0||frame>this.engine.frame+120
       ||!Number.isInteger(input)||input<0||input>4095) throw new Error('Invalid remote input');
    if(frame<Math.max(0,this.engine.frame-this.history)) throw new Error('Input arrived outside the rollback history; restart the match');
    const actual=this.actual.get(frame)??[null,null];
    if(actual[player]!==null&&actual[player]!==input) throw new Error('A peer changed an already submitted input');
    actual[player]=input; this.actual.set(frame,actual);
    while(this.actual.get(this.confirmed[player]+1)?.[player]!=null) ++this.confirmed[player];
    const old=this.records.get(frame);
    if(old&&old.inputs[player]!==input) {
      const end=this.engine.frame;
      this.engine.restore(old.before);
      for(let f=frame;f<end;++f) this.simulate();
      ++this.rollbacks; this.replayed+=end-frame; this.largest=Math.max(this.largest,end-frame);
    }
  }
  canAdvance() { return this.engine.frame-Math.min(...this.confirmed)<=this.maxPrediction; }
  simulate() {
    const frame=this.engine.frame;
    const previous=this.records.get(frame-1)?.inputs??this.baseInputs;
    const actual=this.actual.get(frame)??[null,null];
    const inputs=actual.map((v,p)=>v??previous[p]);
    const before=this.engine.snapshot();
    this.engine.step(...inputs);
    this.records.set(frame,{before,inputs,hash:this.engine.hash});
  }
  advance() {
    if(!this.canAdvance()) return false;
    this.simulate();
    const expired=this.engine.frame-this.history-1;
    if(expired>=0) {
      this.baseInputs=this.records.get(expired)?.inputs??this.baseInputs;
      this.records.delete(expired); this.actual.delete(expired);
    }
    return true;
  }
  confirmedHash(frame) {
    return frame<=Math.min(...this.confirmed)?this.records.get(frame)?.hash:undefined;
  }
}

export function scriptedInput(frame,player=0) {
  const cycle=(frame+player*37)%120;
  const toward=player?1:2,away=player?2:1;
  if(cycle<16) return toward;
  if(cycle===20) return 16;
  if(cycle===30) return 32;
  if(cycle===41) return 4;
  if(cycle===42) return 4|toward;
  if(cycle===43) return toward|64;
  if(cycle===75) return 8;
  if(cycle===80) return 128;
  return cycle>92?away:0;
}

export function rollbackTrial(reference,predicted,{frames=600,latency=6,jitter=3}={}) {
  const session=new RollbackSession(predicted,{maxPrediction:20});
  const pending=[];
  for(let frame=0;frame<frames;++frame) {
    const inputs=[scriptedInput(frame,0),scriptedInput(frame,1)];
    reference.step(...inputs);
    session.submit(0,frame,inputs[0]);
    pending.push({at:frame+latency+(frame*7%(jitter+1)),frame,input:inputs[1]});
    for(let i=pending.length-1;i>=0;--i) if(pending[i].at<=frame) {
      const packet=pending.splice(i,1)[0]; session.submit(1,packet.frame,packet.input);
    }
    if(!session.advance()) throw new Error('Trial exceeded prediction budget');
  }
  for(const packet of pending) session.submit(1,packet.frame,packet.input);
  return {pass:reference.hash===predicted.hash,reference:reference.hash,corrected:predicted.hash,
    frames,rollbacks:session.rollbacks,replayed:session.replayed,largest:session.largest};
}
