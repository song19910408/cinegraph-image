#!/usr/bin/env python3
"""Environment check executed by the AutoDL image builder.

Prints the versions that matter and exits non-zero only when something that
cannot be repaired at boot is missing. Keep this dependency-free: it must run
before any model is downloaded.
"""

import os
import shutil
import subprocess
import sys

problems = []
notes = []


def line(label, value, ok=True):
    print(f"{label}: {value}")
    if not ok:
        problems.append(label)


def note(text):
    notes.append(text)
    print(f"note: {text}")


try:
    import torch

    line("python", sys.version.split()[0])
    line("torch", f"{torch.__version__} cuda {torch.version.cuda}")
    available = torch.cuda.is_available()
    line("cuda available", str(available), available)
    if available:
        name = torch.cuda.get_device_name(0)
        total = torch.cuda.get_device_properties(0).total_memory / 1024**3
        line("device", f"{name} ({total:.1f} GB)")
    else:
        note("CUDA not visible in this container (normal while the builder has no GPU)")
except Exception as error:  # noqa: BLE001 - report, never crash the builder
    line("torch", f"import failed: {error}", False)

ffmpeg = shutil.which("ffmpeg")
line("ffmpeg", ffmpeg or "missing", bool(ffmpeg))

# ComfyUI has lived in several places across images; accept any of them.
CANDIDATES = [
    os.environ.get("COMFY_DIR", ""),
    "/root/ComfyUI",
    "/root/comfyui",
    "/opt/ComfyUI",
    "/workspace/ComfyUI",
    "/root/autodl-tmp/ComfyUI",
]
comfy = next((path for path in CANDIDATES if path and os.path.isfile(os.path.join(path, "main.py"))), "")

if not comfy:
    here = os.path.dirname(os.path.abspath(__file__))
    setup = os.path.join(here, "setup.sh")
    if os.path.isfile(setup):
        print("comfyui missing, running setup.sh (first build only)")
        try:
            subprocess.run(["bash", setup], check=False, timeout=2400)
        except Exception as error:  # noqa: BLE001 - builder may lack bash
            print(f"setup.sh could not run: {error}")
    comfy = next((path for path in CANDIDATES if path and os.path.isfile(os.path.join(path, "main.py"))), "")

line("comfyui", comfy or "missing", bool(comfy))

if comfy:
    custom = os.path.join(comfy, "custom_nodes")
    for pack in ("ComfyUI-VideoHelperSuite", "ComfyUI-SeedVR2_VideoUpscaler"):
        path = os.path.join(custom, pack)
        if os.path.isdir(path):
            line(f"node pack {pack}", path)
        else:
            note(f"{pack} not installed yet (first-run.sh can add it)")
    probe = subprocess.run(
        [sys.executable, "-c", "import sys; sys.path.insert(0, %r); import comfy; print('comfy ok')" % comfy],
        capture_output=True,
        text=True,
    )
    ok = probe.returncode == 0 and "comfy ok" in probe.stdout
    line("comfy import", (probe.stdout or probe.stderr).strip()[:200], ok)

if problems:
    print("\nFAILED: " + ", ".join(problems))
    sys.exit(1)

print("\nOK")
