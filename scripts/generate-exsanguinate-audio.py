#!/usr/bin/env python3
"""Original tightening knife crossings and deep final cash-out impact."""
import hashlib,json,wave
from pathlib import Path
import numpy as np
from scipy.signal import butter,sosfilt
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'godot/assets/audio/supers-v2';RATE=48000

def render(name):
    duration,base,decay={'open':(.36,135,.085),'cross':(.39,115,.09),'close':(.45,78,.11),'finish':(1.05,31,.26)}[name]
    t=np.arange(round(duration*RATE))/RATE
    rng=np.random.default_rng(int.from_bytes(hashlib.sha256(('exsanguinate/'+name).encode()).digest()[:8],'little'))
    noise=rng.normal(0,1,len(t))
    air=sosfilt(butter(2,[1200,9000],'bandpass',fs=RATE,output='sos'),noise)
    body=sosfilt(butter(2,[70,650],'bandpass',fs=RATE,output='sos'),noise)
    signal=air*(1.8*np.exp(-t/.005)+.5*np.exp(-t/.10))+body*2*np.exp(-t/decay)
    signal+=np.sin(2*np.pi*(base*t+80*.025*(1-np.exp(-t/.025))))*np.exp(-t/decay)
    for frequency,level in [(1700,.14),(2711,.09),(4320,.04)]:
        signal+=level*np.sin(2*np.pi*frequency*t)*np.exp(-t/(.12 if name=='cross' else .055))
    if name=='cross':signal+=air*.7*np.sin(np.pi*np.minimum(1,t/.16))**2*np.exp(-t/.10)
    if name=='finish':signal+=sosfilt(butter(2,180,fs=RATE,output='sos'),noise)*2.5*np.exp(-t/.24)
    signal-=signal.mean();signal=np.tanh(signal)*np.minimum(1,t/.0004)*np.minimum(1,(duration-t)/.03)
    signal*=.75/np.max(np.abs(signal));signal[0]=signal[-1]=0
    return np.round(signal*32767).astype('<i2')

def main():
    OUT.mkdir(parents=True,exist_ok=True);sounds=[]
    for name in ['open','cross','close','finish']:
        f=OUT/('exsanguinate_'+name+'.wav');pcm=render(name)
        with wave.open(str(f),'wb') as w:w.setparams((1,2,RATE,len(pcm),'NONE','not compressed'));w.writeframes(pcm.tobytes())
        sounds.append(dict(file=f.name,seconds=len(pcm)/RATE,sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
    (OUT/'exsanguinate.json').write_text(json.dumps(dict(source='Original synthesis; no external recordings',generator='scripts/generate-exsanguinate-audio.py',sounds=sounds),indent=2)+'\n')
    print('Exsanguinate: four original knife-cut and impact sounds.')
if __name__=='__main__':main()
