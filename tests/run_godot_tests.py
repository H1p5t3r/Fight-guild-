"""Treat Godot script errors as failures even when its process exits with code zero."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
cases = [
    (["--headless", "--editor", "--import"], None),
    (["--headless", "--script", "tests/core_bridge.gd", "--", str(root / "build/native.trace")], "0 failures"),
    (["--headless", "--script", "tests/combo_physics_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/combo_snapshot_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/model_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/input_controls_test.gd", "--", "--test"], "Native input controls: 0 failures"),
    (["--headless", "--script", "tests/input_menu_test.gd", "--", "--test"], "Native controls and side-select menus: 0 failures"),
    (["--headless", "--script", "tests/ink_menu_review.gd", "--", "--test"], "Native ink menus: 0 failures"),
    (["--headless", "--script", "tests/pause_tableau_test.gd", "--", "--test"], "Frozen pause presentation: 0 failures"),
    (["--headless", "--script", "tests/super_freeze_test.gd", "--", "--test"], "Super freeze presentation: 0 failures"),
    (["--headless", "--script", "tests/hammer_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/hammer_mobility_test.gd", "--", "--test"], "Hammer mobility: 0 failures"),
    (["--headless", "--script", "tests/fillet_v1_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/movement_projectile_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/movement_presentation_test.gd", "--", "--test"], "Movement presentation: 0 failures"),
    (["--headless", "--script", "tests/locomotion_presentation_test.gd", "--", "--test"], "Locomotion presentation: 0 failures"),
    (["--headless", "--script", "tests/mechanics_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/tapper_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/slash_sweep_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/smoke_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/hurtbox_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/workshop_batch_test.gd", "--", "--test"], "0 failures"),
    (["--headless", "--script", "tests/hit_timeline_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/recovery_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/stage_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/camera_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/signature_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/training_lab_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/tuning_test.gd", "--", "--test"], "0 failures"),
    (["--headless", "--script", "tests/counter_test.gd", "--", "--test"], "0 failures"),
    (["--headless", "--script", "tests/feedback_test.gd", "--", "--test"], "menu: PASS"),
    (["--headless", "--script", "tests/reactions_test.gd", "--", "--test"], "Receiver reactions: 0 failures"),
    (["--headless", "--script", "tests/paired_throws_test.gd", "--", "--test"], "Paired throw presentation: 0 failures"),
    (["--headless", "--script", "tests/impacts_test.gd", "--", "--test"], "0 failures"),
    (["--headless", "--script", "tests/fillet_scale_test.gd", "--", "--test"], "Fillet reaction scale: 0 failures"),
    (["--headless", "--script", "tests/impacts_preview.gd", "--", "--test", "--verify"], "Native impact review: 0 failures"),
    (["--headless", "--script", "tests/art_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/collision_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/ui_smoke.gd", "--", "--test", "--review"], "0 failures"),
]
for args, expected in cases:
    result = subprocess.run(["bash", "scripts/godot.sh", *args], cwd=root, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
    failed = result.returncode != 0 or "ERROR:" in result.stdout or (expected and expected not in result.stdout)
    if failed or expected:
        print(result.stdout, end="")
    if failed:
        sys.exit(1)
print("PASS Godot imports and script suites")
