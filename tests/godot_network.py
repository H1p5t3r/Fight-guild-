"""Exercise two separate Godot processes through their actual ENet sockets."""
from pathlib import Path
import socket
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
    probe.bind(("127.0.0.1", 0))
    port = probe.getsockname()[1]
command = ["bash", "scripts/godot.sh", "--headless", "--max-fps", "120", "--script", "tests/network_peer.gd", "--"]
processes = []
try:
    processes.append(subprocess.Popen(command + ["host", str(port)], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True))
    time.sleep(0.4)
    processes.append(subprocess.Popen(command + ["join", str(port)], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True))
    for process in processes:
        output, _ = process.communicate(timeout=30)
        print(output.strip())
        assert process.returncode == 0 and "PASS native ENet peer" in output and "SCRIPT ERROR" not in output, "Godot network validation failed"
finally:
    for process in processes:
        if process.poll() is None:
            process.terminate()
            process.wait(timeout=5)
