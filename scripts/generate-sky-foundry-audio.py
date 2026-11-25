#!/usr/bin/env python3
"""Original, deterministic clamp/lift/fall/ground-strike sound design."""
import hashlib
import json
import wave
from pathlib import Path

import numpy as np
from scipy.signal import butter, sosfilt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'godot/assets/audio/supers-v2'
RATE = 48000


def render(name):
    duration = {'clamp':.23,'lift':.48,'fall':.30,'slam':.72}[name]
    t = np.arange(round(duration*RATE))/RATE
    rng = np.random.default_rng(int.from_bytes(hashlib.sha256(name.encode()).digest()[:8],'little'))
    noise = rng.normal(0,1,len(t))
    grit = sosfilt(butter(2,[250,8000],'bandpass',fs=RATE,output='sos'),noise)
    air = sosfilt(butter(2,[1400,12000],'bandpass',fs=RATE,output='sos'),noise)
    if name in ['lift','fall']:
        attack = .012 if name=='lift' else .003
        decay = .10 if name=='lift' else .060
        env = (1-np.exp(-t/attack))*np.exp(-t/decay)
        freq = 100+500*t/duration if name=='lift' else 210-160*t/duration
        angle = 2*np.pi*np.cumsum(freq)/RATE
        signal = (1.9*air+.45*grit+.25*np.sin(angle))*env
        signal += .13*np.sin(angle*.48)*np.exp(-t/.14)
    else:
        decay = .028 if name=='clamp' else .095
        signal = grit*np.exp(-t/.006)*2.5+grit*np.exp(-t/decay)*.9
        hz = 100 if name=='clamp' else 44
        angle = 2*np.pi*(hz*t+hz*.9*.018*(1-np.exp(-t/.018)))
        signal += np.sin(angle)*np.exp(-t/decay)*1.15
        for hz,gain in [(470,.18),(810,.12),(1370,.06)]:
            signal += gain*np.sin(2*np.pi*hz*t)*np.exp(-t/(decay*1.3))
        if name=='slam':
            rubble = sosfilt(butter(2,900,fs=RATE,output='sos'),noise)
            signal += rubble*np.exp(-t/.15)*.65
            for delay in [.018,.039,.065,.09,.145]:
                dt=np.maximum(0,t-delay)
                signal += grit*(t>=delay)*np.exp(-dt/.017)*.35
    signal -= signal.mean()
    signal = np.tanh(signal)
    signal *= np.minimum(1,t/.0004)*np.minimum(1,(duration-t)/.02)
    signal *= .75/max(.001,np.abs(signal).max())
    signal[0]=signal[-1]=0
    return np.round(signal*32767).astype('<i2')


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    sounds=[]
    for name in ['clamp','lift','fall','slam']:
        path=OUT/('sky_foundry_'+name+'.wav');pcm=render(name)
        with wave.open(str(path),'wb') as wav:
            wav.setparams((1,2,RATE,len(pcm),'NONE','not compressed'));wav.writeframes(pcm.tobytes())
        sounds.append({'file':path.name,'seconds':len(pcm)/RATE,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    (OUT/'sky-foundry.json').write_text(json.dumps({'source':'Original synthesis; no external recordings','generator':'scripts/generate-sky-foundry-audio.py','sounds':sounds},indent=2)+'\n')
    print('Sky Foundry: four original 48 kHz sounds.')


if __name__=='__main__':main()
