# Fighter themes

The six supplied songs are installed in the native Godot game.

| Fighter | Theme |
| --- | --- |
| Anvil | Better Than Me |
| Hammer | Space Between the Names |
| Smoke | The Air Is Mine |
| Tapper | Hit Me |
| Shark | No Safe Harbour |
| Fillet | Thumb on the Scale |

Five assignments were specified by the user. **Better Than Me → Anvil** uses the
remaining song and fighter.

## Playback and controls

Open **Sound** from Home or the pause menu. **Sound & music** offers a fighter-theme
toggle, a separate music volume slider, a match-theme selector and **Preview theme**.
Sound effects keep their own toggle, volume and impact preview.

By default, the theme follows **Player 1's fighter**. Choose Player 2's fighter or
any fixed fighter theme instead. The default music volume is 55%; settings save
locally in `user://preferences.cfg`, separately from move data. Each online player
can choose their own music without changing the match or its synchronization.

Music fades in during match loading and continues through intros, Scrums, training
resets, hitstop, super cut-ins and results. Pause menus and dialogs soften it to
half its current level. Changing the theme crossfades over 0.65 seconds. Returning
home or leaving a match fades it out. Previewing a theme also works from Home;
closing the dialog ends that preview.

Disabling music, setting its volume to zero or switching away from the game pauses
the song at its current position. Re-enabling or returning resumes it. Full songs
repeat from the beginning; custom musical loop points have not been authored.

## Assets and preparation

`art/audio/fighter-themes-v1/sources/` preserves all six uploaded `.m4a` files
byte-for-byte. The source manifest records SHA-256 hashes and assignments.
The uploads contain 48 kHz stereo Opus audio in an MP4 container. Godot playback
uses separate **48 kHz stereo Ogg Vorbis** resources, quality 6, under
`godot/assets/audio/themes/`. Video/subtitle streams are not part of the runtime
audio. Titles are preserved; no artist attribution is invented.

`python scripts/prepare-fighter-themes.py` rebuilds the runtime audio, requiring
FFmpeg with libvorbis and ffprobe. It measures each original, applies constant gain
toward −18 LUFS with peak headroom, then checks the encoded duration and levels.
No dynamics compression, song trimming or composition changes are applied. The preparation
report records the measured gain, loudness, true peaks and output hashes. These
files measure approximately −18.0 to −18.2 LUFS after encoding.

`godot/data/fighter_music.json` maps the native fighter IDs to the songs.
`FighterMusic` owns two audio voices on a separate Music bus for crossfades. It uses
render time rather than combat frames, snapshots or contact events, so rollback
and simulation freezes cannot replay or restart music. Imported Ogg assets and the
JSON catalog are included by the native export presets.

## Verification

Run `bash scripts/godot.sh --headless --script tests/fighter_music_test.gd -- --test`.
The suite checks all six assignments and imported durations, real decoded mixer
output, end-of-song looping, mute/focus resume, theme changes, interrupted
crossfades, menu audition, saved preferences and the native match/menu lifecycle.
It also verifies the settings controls fit the window. With a rendered display,
append `--output /absolute/path/music-menu.png` to capture the actual menu.

These changes do not update or publish the Move Workshop website.
