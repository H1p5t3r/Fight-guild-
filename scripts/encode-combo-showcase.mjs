// The replay duplicates recorded game frames; it never interpolates poses or
// alters a move's real-time timing. The only overlay change is the speed label.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
import {resolve} from 'node:path';
const json=p=>JSON.parse(readFileSync(p));
const dir=resolve('build/combo-showcase'),film=json(process.argv[2]??`${dir}/film.json`),chapters=json(`${dir}/chapters.json`);
const colors={5:'e1817f',2:'b9d17e',4:'7ac7ce'};
const filters=[`[0:v]scale=1280:720:flags=lanczos,setsar=1,split=${film.clips.length*2}${film.clips.map((_,i)=>`[live${i}][slow${i}]`).join('')}`];
const movieChapters=[];let total=0;
for(const [i,c]of film.clips.entries()){
 // Godot emits one setup frame before the harness and one final frame after it.
 const start=chapters.chapters[i].frame+1,end=(chapters.chapters[i+1]?.frame??chapters.frames)+1;
 const liveStart=start+105,liveEnd=liveStart+c.inputs.length;
 filters.push(`[live${i}]trim=start_frame=${start}:end_frame=${end},setpts=PTS-STARTPTS[v${i*2}]`);
 filters.push(`[slow${i}]trim=start_frame=${liveStart}:end_frame=${liveEnd},setpts=2*(PTS-STARTPTS),fps=60,tpad=stop_mode=clone:stop=1,trim=end_frame=${c.inputs.length*2},drawbox=x=1010:y=651:w=270:h=30:color=0x0b1118:t=fill,drawtext=fontfile='${resolve('godot/Content/Fonts/BarlowCondensedSemibold.woff2')}':text='1/2 SPEED REPLAY':fontsize=17:fontcolor=0x${colors[c.character]}:x=w-tw-24:y=659,tpad=stop_mode=clone:stop_duration=1.25[v${i*2+1}]`);
 const frames=end-start+c.inputs.length*2+75;
 movieChapters.push({id:c.id,startFrame:total,endFrame:total+frames,time:total/60,damage:c.damage,hits:c.hits});total+=frames;
}
filters.push(film.clips.map((_,i)=>`[v${i*2}][v${i*2+1}]`).join('')+`concat=n=${film.clips.length*2}:v=1:a=0[out]`);
writeFileSync(`${dir}/edit.ffmpeg`,filters.join(';\n'));
const metadata=[';FFMETADATA1','title=Fight Guild — Fillet, Smoke & Shark combo showcase',
 'comment=Normal-hit routes verified in the native combat core. Replays duplicate frames at half speed.',
 ...movieChapters.flatMap(c=>['[CHAPTER]','TIMEBASE=1/60',`START=${c.startFrame}`,`END=${c.endFrame}`,`title=${c.id.replaceAll('-',' ')} — ${c.damage} damage / ${c.hits} hits`])];
writeFileSync(`${dir}/chapters.ffmeta`,metadata.join('\n')+'\n');mkdirSync('exports',{recursive:true});
execFileSync('ffmpeg',['-hide_banner','-y','-i',`${dir}/showcase.avi`,'-i',`${dir}/chapters.ffmeta`,'-filter_complex_threads','2','-filter_complex_script',`${dir}/edit.ffmpeg`,'-map','[out]','-map_metadata','1','-map_chapters','1','-an','-c:v','libx264','-threads','2','-preset','fast','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',resolve('exports/FightGuild-Combo-Showcase.mp4')],{stdio:'inherit'});
writeFileSync(`${dir}/video-chapters.json`,JSON.stringify({fps:60,expectedFrames:total,chapters:movieChapters},null,2)+'\n');
