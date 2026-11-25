#!/usr/bin/env python3
"""Preserve the uploaded songs and prepare level-matched Godot Vorbis resources."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/audio/fighter-themes-v1'
DEST = ROOT / 'godot/assets/audio/themes'
REPORT = ROOT / 'build/theme-audio'
TARGET_I = -18.0
PEAK_LIMIT = -2.0


def checksum(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def probe(path):
    return json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-select_streams', 'a:0', '-show_streams',
        '-show_format', '-of', 'json', str(path)], text=True))


def measure(path, log):
    result = subprocess.run([
        'ffmpeg', '-hide_banner', '-nostats', '-i', str(path), '-map', '0:a:0',
        '-af', 'loudnorm=I=-18:TP=-2:LRA=20:print_format=json', '-f', 'null', '-'],
        capture_output=True, text=True, check=True)
    log.write_text(result.stderr)
    return json.JSONDecoder().raw_decode(result.stderr[result.stderr.rfind('{'):])[0]


def prepare(track):
    source = SOURCE / 'sources' / track['source']
    if checksum(source) != track['source_sha256']:
        raise ValueError('Original upload checksum changed: ' + str(source))
    info = probe(source)
    audio = info['streams'][0]
    original = measure(source, REPORT / (track['fighter'].lower() + '-source.log'))
    # A constant gain preserves the song's dynamics. Leave true-peak headroom;
    # do not apply a compressor, trim the composition, or remove its lyrics.
    gain = min(TARGET_I - float(original['input_i']), PEAK_LIMIT - float(original['input_tp']))
    output = DEST / track['file']
    subprocess.run([
        'ffmpeg', '-y', '-v', 'error', '-i', str(source), '-map', '0:a:0', '-map_metadata', '-1',
        '-af', f'volume={gain:.4f}dB', '-ar', '48000', '-ac', '2', '-c:a', 'libvorbis', '-q:a', '6',
        '-metadata', 'title=' + track['title'], str(output)], check=True)
    encoded = probe(output)
    levels = measure(output, REPORT / (track['fighter'].lower() + '-runtime.log'))
    duration = float(encoded['format']['duration'])
    source_duration = float(audio.get('duration', info['format']['duration']))
    if abs(duration - source_duration) > 0.15:
        raise ValueError('Audio duration changed: ' + track['fighter'])
    if abs(float(levels['input_i']) - (float(original['input_i']) + gain)) > 0.5:
        raise ValueError('Unexpected encoded loudness: ' + track['fighter'])
    if float(levels['input_tp']) > -1.0:
        raise ValueError('Encoded track lost peak headroom: ' + track['fighter'])
    record = {key: track[key] for key in ['character', 'fighter', 'title', 'file']}
    record['duration'] = round(duration, 3)
    record['sha256'] = checksum(output)
    report = dict(track, source_codec=audio['codec_name'], source_duration=source_duration,
                  source_lufs=float(original['input_i']), gain_db=round(gain, 4),
                  runtime_lufs=float(levels['input_i']), runtime_true_peak_db=float(levels['input_tp']),
                  runtime_duration=duration, runtime_sha256=record['sha256'])
    print(f"{track['fighter']}: {duration:.2f}s, {levels['input_i']} LUFS, {levels['input_tp']} dBTP", flush=True)
    return record, report


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    REPORT.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((SOURCE / 'source-manifest.json').read_text())
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        outputs = list(pool.map(prepare, manifest['tracks']))
    (ROOT / 'godot/data/fighter_music.json').write_text(json.dumps({
        'version': 1, 'tracks': [record for record, report in outputs]}, indent=2) + '\n')
    (SOURCE / 'preparation.json').write_text(json.dumps({
        'format': '48 kHz stereo Ogg Vorbis, quality 6', 'target_lufs': TARGET_I,
        'method': 'Constant gain only; original song duration and dynamics preserved.',
        'tracks': [report for record, report in outputs]}, indent=2) + '\n')


if __name__ == '__main__':
    main()
