#!/usr/bin/env bash
# CineGraph workstation bootstrap for AutoDL.
#
#   bash first-run.sh install   # one-off: make sure ComfyUI + nodes exist
#   bash first-run.sh           # every boot: link public weights, start server
#
# Models are never baked into the image: they are symlinked from AutoDL's public
# storage (/.autodl/...), so an image stays small and weights can be swapped.
set -uo pipefail

MODE="${1:-start}"
COMFY=""
for candidate in "${COMFY_DIR:-}" /root/ComfyUI /root/comfyui /opt/ComfyUI /workspace/ComfyUI /root/autodl-tmp/ComfyUI; do
  if [ -n "$candidate" ] && [ -f "$candidate/main.py" ]; then COMFY="$candidate"; break; fi
done

log() { printf '== %s\n' "$*"; }

install_comfy() {
  if [ -n "$COMFY" ]; then
    log "ComfyUI already at $COMFY"
  else
    log "installing ComfyUI into /root/ComfyUI"
    if [ "$(id -u)" = "0" ]; then
      apt-get update -qq || true
      apt-get install -y -qq ffmpeg git curl fonts-noto-cjk || true
    else
      sudo apt-get update -qq || true
      sudo apt-get install -y -qq ffmpeg git curl fonts-noto-cjk || true
    fi
    git clone --depth 1 https://github.com/comfyanonymous/ComfyUI.git /root/ComfyUI || return 1
    python3 -m pip install -q -r /root/ComfyUI/requirements.txt || return 1
    COMFY=/root/ComfyUI
  fi

  local nodes="$COMFY/custom_nodes"
  mkdir -p "$nodes"
  install_node() {
    local name="$1" repo="$2"
    if [ -d "$nodes/$name" ]; then
      log "node exists: $name"
      return
    fi
    log "installing node: $name"
    git clone --depth 1 "$repo" "$nodes/$name" || { log "clone failed: $name"; return; }
    [ -f "$nodes/$name/requirements.txt" ] && python3 -m pip install -q -r "$nodes/$name/requirements.txt" || true
  }

  install_node ComfyUI-VideoHelperSuite https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git
  install_node ComfyUI-SeedVR2_VideoUpscaler https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler.git
  install_node ComfyUI-Manager https://github.com/ltdrdata/ComfyUI-Manager.git
}

link_public_models() {
  [ -z "$COMFY" ] && return
  local data="${MODELS_ROOT:-/root/autodl-tmp/models}"
  mkdir -p "$data"/{diffusion_models,text_encoders,vae,upscale_models} "$COMFY/models"

  log "linking public weights from /.autodl (zero copy)"
  local count=0
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    local base target
    base="$(basename "$file")"
    case "$base" in
      *minimax_h3*|*qwen3vl_32b_minimax*|*minimax_h3_latent_upscaler*) ;;
      *) continue ;;
    esac
    case "$base" in
      *video_vae*) target="$COMFY/models/vae" ;;
      *audio_vae*|*audio_encoder*) target="$COMFY/models/vae" ;;
      *text_encoder*|*qwen3vl*) target="$COMFY/models/text_encoders" ;;
      *upscaler*) target="$COMFY/models/upscale_models" ;;
      *) target="$COMFY/models/diffusion_models" ;;
    esac
    mkdir -p "$target"
    ln -sfn "$file" "$target/$base"
    count=$((count + 1))
  done < <(find /.autodl -maxdepth 7 -type f \( \
      -name '*minimax_h3*.safetensors' -o \
      -name 'qwen3vl_32b_minimax_h3*.safetensors' -o \
      -name '*minimax_h3_latent_upscaler*.safetensors' \) 2>/dev/null)

  if [ "$count" -eq 0 ]; then
    log "no public weights found; the app can still generate with what is local"
  else
    log "linked $count weight files"
  fi

  # legacy location some images used
  for folder in diffusion_models text_encoders vae; do
    if [ -d "$data/$folder" ] && [ -n "$(ls -A "$data/$folder" 2>/dev/null)" ]; then
      mkdir -p "$COMFY/models/$folder"
      cp -rsf "$data/$folder"/. "$COMFY/models/$folder"/ 2>/dev/null || true
    fi
  done
}

case "$MODE" in
  install) install_comfy ;;
  start)
    if [ -z "$COMFY" ]; then
      log "ComfyUI not found, running install first"
      install_comfy
    fi
    link_public_models
    log "starting ComfyUI on 0.0.0.0:8188"
    cd "$COMFY" || exit 1
    exec python3 main.py --listen 0.0.0.0 --port 8188
    ;;
  *) echo "usage: bash $0 [install|start]" ;;
esac
