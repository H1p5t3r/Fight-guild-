#!/usr/bin/env python3
"""Join the twelve native reviews at their original 60 FPS, with audio and chapters."""
import argparse
import hashlib
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ORDER = [
    'sky-foundry', 'iron-dominion', 'freemason', 'grand-design',
    'flashpoint', 'the-air-is-mine', 'last-orders', 'whiskey-chaser',
    'no-safe-harbour', 'undertow', 'bloodletting', 'exsanguinate',
]
FIGHTERS = ['Anvil', 'Hammer', 'Smoke', 'Tapper', 'Shark', 'Fillet']


def probe(path):
    return json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-show_streams', '-show_format',
        '-of', 'json', str(path),
    ]))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--version', choices=['v2', 'v3'], default='v2')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    suffix = '-V3' if args.version == 'v3' else ''
    output = (args.output or ROOT / 'exports' /
              ('FightGuild-All-Supers-Animated' + suffix + '-2026-11-26.mp4')).resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    work = ROOT / 'build' / ('super-animation-showcase' + suffix.lower())
    work.mkdir(parents=True, exist_ok=True)

    command = ['ffmpeg', '-y', '-loglevel', 'warning', '-filter_complex_threads', '2']
    filters, concat, segments = [], [], []
    chapters = [';FFMETADATA1', 'title=Fight Guild — Full Super Animation Showcase']
    total = 0
    for index, slug in enumerate(ORDER):
        plan = json.loads((ROOT / 'art/characters' / ('supers-' + args.version) / slug /
                           'exposure-plan.json').read_text())
        name = plan['name']
        file = ROOT / 'exports' / ('FightGuild-' + name.replace(' ', '-') + suffix + '-' +
                                  plan.get('date', '2026-11-25') + '.mp4')
        info = probe(file)
        video = next(s for s in info['streams'] if s['codec_type'] == 'video')
        assert (video['width'], video['height'], video['r_frame_rate']) == (1440, 810, '60/1'), file
        assert any(s['codec_type'] == 'audio' for s in info['streams']), file

        # Native review: two initial frames, then 315 frames per demonstration.
        # Sky Foundry predates that review and has 321 frames per demonstration.
        # Use Exsanguinate's fifth case to show its real stored-bleed payout.
        start = 1262 if slug == 'exsanguinate' else 2
        length = 321 if slug == 'sky-foundry' else 315
        end = start + length
        assert int(video['nb_frames']) >= end, file
        command += ['-threads', '2', '-i', str(file)]
        filters += [
            f'[{index}:v:0]trim=start_frame={start}:end_frame={end},setpts=PTS-STARTPTS[v{index}]',
            f'[{index}:a:0]atrim=start={start / 60:.9f}:end={end / 60:.9f},asetpts=PTS-STARTPTS[a{index}]',
        ]
        concat += [f'[v{index}][a{index}]']
        label = FIGHTERS[plan['character']] + ' / ' + name
        chapters += ['[CHAPTER]', 'TIMEBASE=1/60', f'START={total}',
                     f'END={total + length}', 'title=' + label]
        segments.append({
            'name': name, 'fighter': FIGHTERS[plan['character']], 'input': plan['input'],
            'source': str(file.relative_to(ROOT)),
            'sha256': hashlib.sha256(file.read_bytes()).hexdigest(),
            'case': 'bleed' if slug == 'exsanguinate' else 'hit',
            'sourceStartFrame': start, 'sourceEndFrameExclusive': end,
            'timelineStartFrame': total, 'frames': length,
        })
        total += length
    filters.append(''.join(concat) + f'concat=n={len(ORDER)}:v=1:a=1[v][a]')
    chapter_file = work / 'chapters.ffmetadata'
    chapter_file.write_text('\n'.join(chapters) + '\n')
    filter_file = work / 'concat.txt'
    filter_file.write_text(';\n'.join(filters) + '\n')
    command += ['-f', 'ffmetadata', '-i', str(chapter_file),
                '-filter_complex', filter_file.read_text().strip(),
                '-map', '[v]', '-map', '[a]', '-map_metadata', str(len(ORDER)),
                '-map_chapters', str(len(ORDER)), '-c:v', 'libx264', '-threads', '4',
                '-crf', '18', '-preset', 'medium', '-pix_fmt', 'yuv420p',
                '-r', '60', '-fps_mode', 'cfr',
                '-c:a', 'aac', '-b:a', '160k', '-movflags', '+faststart', str(output)]
    subprocess.run(command, check=True)
    rendered = probe(output)
    video = next(s for s in rendered['streams'] if s['codec_type'] == 'video')
    assert int(video['nb_frames']) == total, 'Assembly dropped or duplicated frames'
    assert video['r_frame_rate'] == '60/1'
    manifest = {
        'title': 'Fight Guild — Full Super Animation Showcase',
        'version': args.version,
        'resolution': [1440, 810], 'fps': 60, 'frames': total,
        'seconds': total / 60, 'retimed': False, 'segments': segments,
        'note': 'Native Godot footage at full speed. Exsanguinate starts with 150 owned grey life.',
        'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
    }
    output.with_suffix('.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'{output}: {total} frames / {total / 60:.1f}s, native speed, original audio')


if __name__ == '__main__':
    main()
