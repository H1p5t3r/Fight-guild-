#!/usr/bin/env python3
"""Original shield-super impact synthesis, separate from ordinary hit sounds."""
import hashlib
import json
import wave
from pathlib import Path
import numpy as np
from scipy.signal import butter, sosfilt

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/assets/audio/supers-v2'
RATE=48000

def render(name):
    duration,base,decay={'ram':(.32,64,.060),'press':(.36,88,.065),'crush':(.42,57,.080),'finish':(.8,36,.14)}[name]
    t=np.arange(round(duration*RATE))/RATE
    rng=np.random.default_rng(int.from_bytes(hashlib.sha256(('iron/'+name).encode()).digest()[:8],'little'))
    noise=rng.normal(0,1,len(t))
    metal=sosfilt(butter(2,[600,10500],'bandpass',fs=RATE,output='sos'),noise)
    weight=sosfilt(butter(2,440,fs=RATE,output='sos'),noise)
    # Dry shield edge, lower chest thump, then a short inharmonic plate ring.
    signal=metal*(2.8*np.exp(-t/.004)+.6*np.exp(-t/.026))
    phase=2*np.pi*(base*t+base*.8*.018*(1-np.exp(-t/.018)))
    signal+=1.3*np.sin(phase)*np.exp(-t/decay)+.6*weight*np.exp(-t/.08)
    for frequency,gain in [(330,.22),(547,.18),(887,.12),(1537,.05)]:
        signal+=gain*np.sin(2*np.pi*frequency*t)*(1-np.exp(-t/.0008))*np.exp(-t/(decay*1.5))
    if name=='finish':
        for delay in [.02,.047,.083,.13,.19]:
            signal+=metal*(t>=delay)*np.exp(-np.maximum(0,t-delay)/.025)*.35
        signal+=weight*np.exp(-t/.2)*.9
    signal-=signal.mean()
    signal=np.tanh(signal)*np.minimum(1,t/.0004)*np.minimum(1,(duration-t)/.03)
    signal*=.75/np.max(np.abs(signal));signal[0]=signal[-1]=0
    return np.round(signal*32767).astype('<i2')

def main():
    OUT.mkdir(parents=True,exist_ok=True);sounds=[]
    for name in ['ram','press','crush','finish']:
        path=OUT/('iron_dominion_'+name+'.wav');pcm=render(name)
        with wave.open(str(path),'wb') as f:
            f.setparams((1,2,RATE,len(pcm),'NONE','not compressed'));f.writeframes(pcm.tobytes())
        sounds.append(dict(file=path.name,seconds=len(pcm)/RATE,sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
    (OUT/'iron-dominion.json').write_text(json.dumps(dict(source='Original synthesis; no external recordings',generator='scripts/generate-iron-dominion-audio.py',sounds=sounds),indent=2)+'\n')
    print('Iron Dominion: four original 48 kHz shield impacts.')

if __name__=='__main__':main()
