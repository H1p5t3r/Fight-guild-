#!/usr/bin/env python3
"""Original alternating hook cracks, low body thud and final heavy hook."""
import hashlib,json,wave
from pathlib import Path
import numpy as np
from scipy.signal import butter,sosfilt
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'godot/assets/audio/supers-v2';RATE=48000

def render(name):
    duration,base,decay={'hook':(.32,95,.06),'cross':(.34,115,.065),'body':(.40,58,.10),'finish':(.85,36,.21)}[name]
    t=np.arange(round(duration*RATE))/RATE
    rng=np.random.default_rng(int.from_bytes(hashlib.sha256(('whiskey_chaser/'+name).encode()).digest()[:8],'little'))
    noise=rng.normal(0,1,len(t));crack=sosfilt(butter(2,[900,10500],'bandpass',fs=RATE,output='sos'),noise);body=sosfilt(butter(2,[90,700],'bandpass',fs=RATE,output='sos'),noise)
    signal=crack*(2.1*np.exp(-t/.004)+.12*np.exp(-t/.04))+body*2.8*np.exp(-t/decay)
    signal+=.9*np.sin(2*np.pi*(base*t+50*.018*(1-np.exp(-t/.018))))*np.exp(-t/decay)
    if name in ['hook','cross']:signal+=crack*.2*np.exp(-t/.10)
    if name=='body':signal+=.24*np.sin(2*np.pi*710*t)*np.exp(-t/.012)
    if name=='finish':
        signal+=sosfilt(butter(2,180,fs=RATE,output='sos'),noise)*2*np.exp(-t/.22)
        signal+=.2*crack*(t>.018)*np.exp(-np.maximum(t-.018,0)/.025)
    signal-=signal.mean();signal=np.tanh(signal)*np.minimum(1,t/.0004)*np.minimum(1,(duration-t)/.03)
    signal*=.75/np.max(np.abs(signal));signal[0]=signal[-1]=0
    return np.round(signal*32767).astype('<i2')

def main():
    OUT.mkdir(parents=True,exist_ok=True);sounds=[]
    for name in ['hook','cross','body','finish']:
        f=OUT/('whiskey_chaser_'+name+'.wav');pcm=render(name)
        with wave.open(str(f),'wb') as w:w.setparams((1,2,RATE,len(pcm),'NONE','not compressed'));w.writeframes(pcm.tobytes())
        sounds.append(dict(file=f.name,seconds=len(pcm)/RATE,sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
    (OUT/'whiskey_chaser.json').write_text(json.dumps(dict(source='Original synthesis; no external recordings',generator='scripts/generate-whiskey-chaser-audio.py',sounds=sounds),indent=2)+'\n')
    print('Whiskey Chaser: four original physical impact sounds.')
if __name__=='__main__':main()
