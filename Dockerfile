# Environment image for the CineGraph deployment on AutoDL.
# Build: docker build -t cinegraph/comfy:h3 .
# The image carries NO model weights; first-run.sh downloads them to the data disk.
FROM pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFY_DIR=/root/ComfyUI \
    HF_ENDPOINT=https://hf-mirror.com

RUN apt-get update && apt-get install -y --no-install-recommends \
      git ffmpeg libgl1 libglib2.0-0 curl ca-certificates rsync \
    && rm -rf /var/lib/apt/lists/*

# ComfyUI at a pinned commit: bump deliberately, never track master blindly.
ARG COMFY_REPO=https://github.com/comfyanonymous/ComfyUI.git
ARG COMFY_REF=master
RUN git clone "$COMFY_REPO" "$COMFY_DIR" \
    && git -C "$COMFY_DIR" checkout "$COMFY_REF"

RUN python3 -m pip install --upgrade pip \
    && python3 -m pip install -r "$COMFY_DIR/requirements.txt"

# Custom nodes the shipped workflows need.
RUN cd "$COMFY_DIR/custom_nodes" \
    && git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
    && git clone --depth 1 https://github.com/numz/ComfyUI-SeedVR2_VideoUpscaler.git \
    && python3 -m pip install -r ComfyUI-VideoHelperSuite/requirements.txt \
    && python3 -m pip install -r ComfyUI-SeedVR2_VideoUpscaler/requirements.txt

COPY first-run.sh /root/first-run.sh
COPY check.py /root/check.py
COPY models.md /root/models.md
RUN chmod +x /root/first-run.sh

WORKDIR /root
EXPOSE 6006 8188

# Default: prepare weights (idempotent) and start the server.
CMD ["bash", "/root/first-run.sh"]
