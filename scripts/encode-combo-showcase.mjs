// Slow replays duplicate frames; never interpolate poses or change live timing.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {resolve,dirname} from 'node:path';
const json=p=>JSON.parse(readFileSync(p));
const path=resolve(process.argv[2]??'build/combo-showcase-current/film.json');
const dir=dirname(path),film=json(path),chapters=json(`${dir}/chapters.json`);
const colors=['aeb4bc','99b0c2','a8ba76','d99a59','5ab5b5','dc143c'];
const names=['anvil','hammer','smoke','tapper','shark','fillet'];
const filters=[`[0:v]scale=1280:720:flags=lanczos,setsar=1,split=${film.clips.length*2}${film.clips.map((_,i)=>`[live${i}][slow${i}]`).join('')}`];
const movieChapters=[];let total=0;
for(const [i,c]of film.clips.entries()){
 // Movie writer adds one setup frame before the first awaited frame.
 const start=chapters.chapters[i].frame+1,end=(chapters.chapters[i+1]?.frame??chapters.frames)+1;
 const liveStart=start+105,liveEnd=liveStart+c.inputs.length;
 filters.push(`[live${i}]trim=start_frame=${start}:end_frame=${end},setpts=PTS-STARTPTS[v${i*2}]`);
 filters.push(`[slow${i}]trim=start_frame=${liveStart}:end_frame=${liveEnd},setpts=2*(PTS-STARTPTS),fps=60,tpad=stop_mode=clone:stop=1,trim=end_frame=${c.inputs.length*2},drawbox=x=1010:y=651:w=270:h=30:color=0x0b1118:t=fill,drawtext=fontfile='${resolve('godot/Content/Fonts/BarlowCondensedSemibold.woff2')}':text='1/2 SPEED REPLAY':fontsize=17:fontcolor=0x${colors[c.character]}:x=w-tw-24:y=659,tpad=stop_mode=clone:stop_duration=1.25[v${i*2+1}]`);
 const frames=end-start+c.inputs.length*2+75;
 movieChapters.push({id:c.id,character:c.character,startFrame:total,endFrame:total+frames,time:total/60,damage:c.damage,hits:c.hits});total+=frames;
}
filters.push(film.clips.map((_,i)=>`[v${i*2}][v${i*2+1}]`).join('')+`concat=n=${film.clips.length*2}:v=1:a=0[out]`);
const fighters=[...new Set(movieChapters.map(c=>c.character))];
const audioInputs=[];
for(const [i,c]of fighters.entries()){
 const rows=movieChapters.filter(row=>row.character===c),duration=(rows.at(-1).endFrame-rows[0].startFrame)/60;
 audioInputs.push('-stream_loop','-1','-ss','20','-i',resolve(`godot/assets/audio/themes/${names[c]}.ogg`));
 filters.push(`[${i+2}:a]atrim=duration=${duration},asetpts=PTS-STARTPTS,aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,volume=0.65,afade=t=in:d=0.3,afade=t=out:st=${duration-0.6}:d=0.6[a${i}]`);
}
filters.push(fighters.map((_,i)=>`[a${i}]`).join('')+`concat=n=${fighters.length}:v=0:a=1[music]`);
writeFileSync(`${dir}/edit.ffmpeg`,filters.join(';\n'));
const metadata=[';FFMETADATA1',`title=Fight Guild — all six fighters — ${film.date}`,
 'comment=Current native build. Verified ordinary inputs. Explicit half-speed replays. User-provided fighter themes.',
 ...movieChapters.flatMap(c=>['[CHAPTER]','TIMEBASE=1/60',`START=${c.startFrame}`,`END=${c.endFrame}`,`title=${c.id.replaceAll('-',' ')} — ${c.damage} damage / ${c.hits} hits`])];
writeFileSync(`${dir}/chapters.ffmeta`,metadata.join('\n')+'\n');mkdirSync('exports',{recursive:true});
const output=resolve(`exports/FightGuild-Combo-Showcase-${film.date}.mp4`);
execFileSync('ffmpeg',['-hide_banner','-y','-i',`${dir}/showcase.avi`,'-i',`${dir}/chapters.ffmeta`,...audioInputs,'-filter_complex_threads','2','-filter_complex_script',`${dir}/edit.ffmpeg`,'-map','[out]','-map','[music]','-map_metadata','1','-map_chapters','1','-c:v','libx264','-threads','2','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',output],{stdio:'inherit'});
writeFileSync(`${dir}/video-chapters.json`,JSON.stringify({fps:60,expectedFrames:total,chapters:movieChapters},null,2)+'\n');
// One convenient download per fighter as well as the combined chaptered film.
for(const c of fighters){
 const rows=movieChapters.filter(row=>row.character===c),start=rows[0].startFrame/60,duration=(rows.at(-1).endFrame-rows[0].startFrame)/60;
 const name=names[c][0].toUpperCase()+names[c].slice(1);
 execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-y','-ss',String(start),'-i',output,'-t',String(duration),'-map','0:v:0','-map','0:a:0','-map_chapters','-1','-metadata',`title=Fight Guild — ${name} combos — ${film.date}`,'-c:v','libx264','-threads','2','-preset','fast','-crf','21','-pix_fmt','yuv420p','-c:a','aac','-b:a','160k','-movflags','+faststart',resolve(`exports/FightGuild-${names[c]}-Combos-${film.date}.mp4`)],{stdio:'inherit'});
}
