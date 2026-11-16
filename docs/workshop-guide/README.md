# Move Workshop control guide

[Download the PDF](../../exports/FightGuild-Move-Workshop-Guide.pdf).

`content.json` is the maintained source. Gameplay field labels and ranges are
read from the current editor specifications and generated workshop data rather
than copied into the layout code. Behavioral explanations were checked against
the schema-14 C++ core and browser UI, including combat playback and hitbox keys. This guide documents the
browser workshop; it does not claim to cover every global control in Godot.

The PDF has 27 deliberately paginated A4 pages, embedded fonts, searchable text,
bookmarks, linked contents and a linked alphabetical gameplay-field index.
Screenshots show a fresh default draft in a temporary browser context. Enabling
the sample hurtbox profile does not modify repository move data or a user draft.

## Rebuild

Start from the repository root with the normal Node dependencies installed and
an up-to-date workshop build (`npm run build:workshop`). Python needs ReportLab
(built with 4.4.9) and Pillow; Open Sans TTFs are read from the standard Linux
`/usr/share/fonts/truetype/open-sans` directory. The display font is the existing
bundled DejaVu Sans Condensed Bold Oblique.

```bash
# Only when the editor visuals have changed:
node scripts/capture-workshop-guide.mjs

python scripts/build-workshop-guide.py
```

The builder checks that every effective gameplay field and every art text field
is documented once, checks the schema, and rejects page overflow before writing
the PDF. It writes a coverage/page-height report to
`build/workshop-guide-coverage.json`. Update the edition and verified source
revision when reviewing the guide against a later gameplay build.

After changes, render all PDF pages for visual review and check that the page
count, bookmarks, index links, searchable labels and diagram text are intact.
The current edition was checked with PyMuPDF and reviewed as a full contact
sheet plus full-size samples of the densest pages.

## Current labels that need careful explanation

- Browser Attack level and Counter tier changes do not run the Godot preset-copy
  action. The `-1` labels suggest automatic selection but the current core does
  not derive a counter tier from them. The guide explicitly documents this.
- Starter damage applies to later combo hits, not the opening hit.
- Follow-up requires contact requires an unblocked hit, not just any contact.
- Reset move restores bundled defaults, not the latest imported data.
- Hurtbox profiles cover whole phases; they are not per-frame animation keys.
- Godot imports gameplay but does not retain workshop art notes or photos in
  its own subsequent exports. Keep the workshop JSON as the art master.

Active-frame hitbox keys are distinct from whole-phase body hurtboxes. Multiple
boxes default to one hit; separate hit numbers require Allow multiple hits.
The guide also documents the prominent Attack enabled switch and real combat
preview settings. Timelines survive native import/save; art metadata still does not.

The shared workspace edition removes the preview-mode selector and separate
pose transport. One combat timeline supports playback and box dragging in either
facing; edits preserve the selected move frame as contact timing changes.
