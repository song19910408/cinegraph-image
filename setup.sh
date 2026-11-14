#!/usr/bin/env bash
# Installs ComfyUI + the node packs this deployment needs.
# Idempotent: safe to run during image build and again at first boot.
set -euo pipefail

COMFY="${COMFY_DIR:-/root/ComfyUI}"
COMFY_REPO="${COMFY_REPO:-https://github.com/comfyanonymous/ComfyUI.git}"
COMFY_REF="${COMFY_REF:-master}"

if [ ! -f "$COMFY/main.py" ]; then
  echo "== cloning ComfyUI =="
  git clone "$COMFY_REPO" "$COMFY"
  git -C "$COMFY" checkout "$COMFY_REF"
fi

echo "== python deps =="
python3 -m pip install --upgrade pip
python3 -m pip install -r "$COMFY/requirements.txt"

install_node() {
  local name="$1" repo="$2"
  local dir="$COMFY/custom_nodes/$name"
  if [ ! -d "$dir" ]; then
    echo "== node pack $name =="
    git clone --depth 1 "$repo" "$dir"
  fi
  if [ -f "$dir/requirements.txt" ]; then
    python3 -m pip install -r "$dir/requirements.txt"
  fi
}

install_node "ComfyUI-VideoHelperSuite" "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git"
install_node "ComfyUI-SeedVR2_VideoUpscaler" "https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler.git"

mkdir -p "$COMFY/models"/{checkpoints,diffusion_models,text_encoders,vae,audio_encoders,upscale_models}
echo "environment ready: $COMFY"
