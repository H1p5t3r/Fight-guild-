# Saved combat references

The `queen-dizzy-2026-11-18` and `leo-whitefang-2026-11-18` directories contain
normal tables and original hitbox PNG bytes extracted from the user's saved
Dustloop Frame Data pages. `source.json` records archive hashes, timestamps,
source URLs, image hashes, and missing images. Re-extract with
`scripts/extract-dustloop-frame-archive.py <archive.mht> <character>`.

Queen Dizzy: 20 normal rows and 22 diagrams, including multiple stages of 2H,
6H, and the protected anticipation of 6P. Leo: 22 normal rows and 17 diagrams.
Leo's f.S, both 5H diagrams, 6P, 2D, j.D, and held-guard diagrams were **not**
embedded. Their links remain in the manifest; no unsaved image is represented
as inspected.

These are reference diagrams, not numeric collision dumps. Their original
dimensions vary with the screenshot crop. A traced attack rectangle can be
normalized to Fight Guild's scale, but exact source game coordinates, origin
and per-frame transitions cannot be recovered from these pictures alone.
Record calibration and any estimated active-frame boundaries separately.
The cyan regions illustrate source vulnerability; Fight Guild still uses its
own body-only hurtboxes, with at most four per pose and no weapon/effect hurts.

The Queen Dizzy j.D saved table contains one extra `-7 (IAS)` cell. Its raw
cells are retained and the interpreted air-special advantage is labeled in
`source.json`; no attack level is invented as a source fact.

Source artwork belongs to its respective rights holders and is retained here
as supplied development reference. Gameplay sprites are separately generated
for Fight Guild's characters; these diagrams are not rendered as game art.

Ky Kiske's `ky-kiske-2026-11-18` reference contains 16 non-D normal rows for the
[Shark exploration](../../docs/shark-normals.md). Four D rows and all specials
are excluded. There are 14 embedded diagrams covering 13 moves; 5P, 5H and both
2H diagrams are missing **from the archive**. The user subsequently supplied
those four diagrams inline; `supplemental.json` records their chat provenance.
This reference/proposal has not been applied to the
playable move data. Use `ky-kiske --exclude-dust` when extracting this pass.
