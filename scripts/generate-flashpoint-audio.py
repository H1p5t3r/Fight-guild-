#!/usr/bin/env python3
"""Original alchemical-fire layers: ignition, lift, compression and detonation."""
import hashlib,json,wave
from pathlib import Path
import numpy as np
from scipy.signal import butter,sosfilt
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'godot/assets/audio/supers-v2';RATE=48000

def render(name):
    duration,base,tail={'backhand':(.38,75,.08),'lift':(.58,95,.13),'compress':(.36,65,.07),'ignite':(.95,32,.22)}[name]
    t=np.arange(round(duration*RATE))/RATE
    rng=np.random.default_rng(int.from_bytes(hashlib.sha256(('flashpoint/'+name).encode()).digest()[:8],'little'))
    noise=rng.normal(0,1,len(t));air=sosfilt(butter(2,[650,9000],'bandpass',fs=RATE,output='sos'),noise);rumble=sosfilt(butter(2,300,fs=RATE,output='sos'),noise)
    signal=air*(1.9*np.exp(-t/.006)+.45*np.exp(-t/tail))
    signal+=np.sin(2*np.pi*(base*t+base*.7*.025*(1-np.exp(-t/.025))))*np.exp(-t/tail)
    signal+=rumble*.9*np.exp(-t/(tail*1.5))
    if name=='lift':
        signal+=air*.55*np.sin(np.pi*np.minimum(1,t/.35))**2*np.exp(-t/.28)
        signal+=.13*np.sin(2*np.pi*(170*t+360*t*t))*np.exp(-t/.15)
    if name=='compress':signal+=air*.5*(t/.13)*np.exp(-t/.10)
    if name=='ignite':
        for at in [.02,.041,.073,.11,.16,.22,.30,.4]:signal+=air*.38*(t>=at)*np.exp(-np.maximum(t-at,0)/.025)
        signal+=rumble*np.exp(-t/.28)
    signal-=signal.mean();signal=np.tanh(signal)*np.minimum(1,t/.0004)*np.minimum(1,(duration-t)/.03)
    signal*=.75/np.max(np.abs(signal));signal[0]=signal[-1]=0
    return np.round(signal*32767).astype('<i2')

def main():
    OUT.mkdir(parents=True,exist_ok=True);sounds=[]
    for name in ['backhand','lift','compress','ignite']:
        f=OUT/('flashpoint_'+name+'.wav');pcm=render(name)
        with wave.open(str(f),'wb') as w:w.setparams((1,2,RATE,len(pcm),'NONE','not compressed'));w.writeframes(pcm.tobytes())
        sounds.append(dict(file=f.name,seconds=len(pcm)/RATE,sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
    (OUT/'flashpoint.json').write_text(json.dumps(dict(source='Original synthesis; no external recordings',generator='scripts/generate-flashpoint-audio.py',sounds=sounds),indent=2)+'\n')
    print('Flashpoint: four original fire sounds.')
if __name__=='__main__':main()
