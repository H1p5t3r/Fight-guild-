#!/usr/bin/env python3
"""Original gas-field sound design: airy release, field bloom, contact pulse."""
import hashlib,json,wave
from pathlib import Path
import numpy as np
from scipy.signal import butter,sosfilt
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'godot/assets/audio/supers-v2';RATE=48000

def render(name):
    duration,decay={'release':(.48,.10),'bloom':(.85,.20),'pulse':(.30,.065)}[name]
    t=np.arange(round(duration*RATE))/RATE
    rng=np.random.default_rng(int.from_bytes(hashlib.sha256(('the-air-is-mine/'+name).encode()).digest()[:8],'little'))
    noise=rng.normal(0,1,len(t));air=sosfilt(butter(2,[450,8500],'bandpass',fs=RATE,output='sos'),noise);low=sosfilt(butter(2,360,fs=RATE,output='sos'),noise)
    attack=.006 if name=='pulse' else .015
    envelope=(1-np.exp(-t/attack))*np.exp(-t/decay)
    signal=air*envelope*(1.7+.25*np.sin(2*np.pi*32*t))+low*envelope*.8
    base=140 if name=='pulse' else 100
    signal+=.30*np.sin(2*np.pi*(base*t+45*.035*(1-np.exp(-t/.035))))*envelope
    if name=='bloom':signal+=.35*air*np.exp(-t/.32)*(1-np.exp(-t/.04))
    if name=='pulse':signal+=.5*air*np.exp(-t/.003)
    signal-=signal.mean();signal=np.tanh(signal)*np.minimum(1,t/.0005)*np.minimum(1,(duration-t)/.025)
    signal*=.70/np.max(np.abs(signal));signal[0]=signal[-1]=0
    return np.round(signal*32767).astype('<i2')

def main():
    OUT.mkdir(parents=True,exist_ok=True);sounds=[]
    for name in ['release','bloom','pulse']:
        f=OUT/('air_is_mine_'+name+'.wav');pcm=render(name)
        with wave.open(str(f),'wb') as w:w.setparams((1,2,RATE,len(pcm),'NONE','not compressed'));w.writeframes(pcm.tobytes())
        sounds.append(dict(file=f.name,seconds=len(pcm)/RATE,sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
    (OUT/'air_is_mine.json').write_text(json.dumps(dict(source='Original synthesis; no external recordings',generator='scripts/generate-air-is-mine-audio.py',sounds=sounds),indent=2)+'\n')
    print('The Air Is Mine: three original gas sounds.')
if __name__=='__main__':main()
