# Anvil / approved Bull production art

The user approved the corrected High Clamp reference on 25 November 2026. This pass carries its body, five-digit right hand, closed-jaw grin, narrower stance and inward-facing neutral shield into the native game. The left forearm owns the shield throughout. There is no hammer.

`exposure-plan.json` was written from the current native move data before generation. It preserves gameplay timing and puts the largest strike change between the last startup and first active frame. Successful grabs use the shared capture clock; missed grabs do not show a slam.

All PNGs under `godot/assets/fighters/anvil-bull-v2/` are unchanged image-generator output. `sources.json` records prompts, references, original paths and hashes. Registration changes only metadata, anatomical boxes, pivots, exposure keys and render-only shield masks. No programmatic pixel painting, resampling or warping.

Foundation sheets use three columns and two rows. Attack/reaction sheets use two columns and three rows: each column is load/contact/withdraw or contact/recoil/hold. Recovery sheets read across rows. Actual transparent gutters take precedence over nominal cell boundaries.

Source review exclusions: `slashes` top-right swaps shield ownership and is not used; f.S shares the correct compact c.S load. `kicks` top-left clips the head and is not used; its same-size withdrawn knee becomes the load. The first face-down request was rejected by the image service; the successful source uses `down_prone-floor-study.txt`, a neutral rising exercise. The rejected prompt is retained for the audit trail.

This is native game artwork. The Move Workshop website remains frozen.
