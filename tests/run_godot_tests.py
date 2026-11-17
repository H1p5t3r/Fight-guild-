"""Treat Godot script errors as failures even when its process exits with code zero."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
cases = [
    (["--headless", "--editor", "--import"], None),
    (["--headless", "--script", "tests/core_bridge.gd", "--", str(root / "build/native.trace")], "0 failures"),
    (["--headless", "--script", "tests/model_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/movement_projectile_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/hurtbox_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/hit_timeline_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/recovery_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/stage_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/camera_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/signature_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/training_lab_test.gd"], "0 failures"),
    (["--headless", "--script", "tests/tuning_test.gd", "--", "--test"], "0 failures"),
    (["--headless", "--script", "tests/counter_test.gd", "--", "--test"], "0 failures"),
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
