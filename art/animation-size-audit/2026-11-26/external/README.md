# External animation size review

Reviewed all 168 drawings in the reaction, grab and additional movement catalogs at their actual runtime scale. Every row includes the approved idle. No further blanket correction was needed.

Reproduce with `python scripts/capture-animation-scale-review.py --external --output build/external-animation-scale-review`. Select one fighter with `--character 0` through `5`.

The contact sheets show real pivots and a fixed world zoom; poses are never fitted to their silhouette bounds. Head, torso, limb and equipment proportions are compared, rather than treating a crouch or airborne tuck as shrinkage. This is a visual review, not an anatomical measurement. Source sprite pixels and gameplay are unchanged.
