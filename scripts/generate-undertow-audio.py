#!/usr/bin/env python3
"""Original low hook sweep, rising metal reel and reverse-direction finish."""
import hashlib,json,wave
from pathlib import Path
import numpy as np
from scipy.signal import butter,sosfilt
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'godot/assets/audio/supers-v2';RATE=48000

def render(name):
    duration,base,decay={'sweep':(.55,82,.14),'lift':(.48,130,.16),'turn':(.52,60,.15),'finish':(.95,34,.25)}[name]
    t=np.arange(round(duration*RATE))/RATE
    rng=np.random.default_rng(int.from_bytes(hashlib.sha256(('undertow/'+name).encode()).digest()[:8],'little'))
    noise=rng.normal(0,1,len(t))
    air=sosfilt(butter(2,[1200,9000],'bandpass',fs=RATE,output='sos'),noise)
    body=sosfilt(butter(2,[70,650],'bandpass',fs=RATE,output='sos'),noise)
    signal=air*(1.8*np.exp(-t/.005)+.5*np.exp(-t/.10))+body*2*np.exp(-t/decay)
    signal+=np.sin(2*np.pi*(base*t+80*.025*(1-np.exp(-t/.025))))*np.exp(-t/decay)
    for frequency,level in [(920,.18),(1467,.12),(2530,.06)]:
        signal+=level*np.sin(2*np.pi*frequency*t)*np.exp(-t/(.12 if name=='lift' else .055))
    if name=='lift':signal+=air*.7*np.sin(np.pi*np.minimum(1,t/.16))**2*np.exp(-t/.10)
    if name=='finish':signal+=sosfilt(butter(2,180,fs=RATE,output='sos'),noise)*2.5*np.exp(-t/.24)
    signal-=signal.mean();signal=np.tanh(signal)*np.minimum(1,t/.0004)*np.minimum(1,(duration-t)/.03)
    signal*=.75/np.max(np.abs(signal));signal[0]=signal[-1]=0
    return np.round(signal*32767).astype('<i2')

def main():
    OUT.mkdir(parents=True,exist_ok=True);sounds=[]
    for name in ['sweep','lift','turn','finish']:
        f=OUT/('undertow_'+name+'.wav');pcm=render(name)
        with wave.open(str(f),'wb') as w:w.setparams((1,2,RATE,len(pcm),'NONE','not compressed'));w.writeframes(pcm.tobytes())
        sounds.append(dict(file=f.name,seconds=len(pcm)/RATE,sha256=hashlib.sha256(f.read_bytes()).hexdigest()))
    (OUT/'undertow.json').write_text(json.dumps(dict(source='Original synthesis; no external recordings',generator='scripts/generate-undertow-audio.py',sounds=sounds),indent=2)+'\n')
    print('Undertow: four original hook and impact sounds.')
if __name__=='__main__':main()
