# 镜像要装哪些权重

这个清单来自软件的自动包检测规则：**文件名必须能被这些规则匹配到**，否则节点会显示“缺模型”。

放对目录很重要——ComfyUI 的目录名就是检测来源。

## diffusion_models/ （主模型）

| 家族 | 文件名需包含 | 说明 |
|---|---|---|
| MiniMax H3 参考图 | `minimax_h3_ref2va_pruned_int8` | 参考图生视频，人物一致性 |
| MiniMax H3 图生视频 | `minimax_h3_fl2va_pruned_int8` | 首尾帧 → 视频 |
| MiniMax H3 蒸馏版（可选） | `minimax_h3_fl2va` + `8step` | 8 步出片，快 3 倍 |
| Z-Image | `z_image_turbo_bf16` | 文生图，2–3 秒出图 |
| Qwen Image 2.1 | `qwen_image_2.1` | 文生图 / 编辑 |
| Wan 2.2 | `wan2.2` | 图生视频 |
| MiniMax Music3 | `music3_dit` | 文生音乐 |
| SeedVR2 | `seedvr2_ema_3b` 或 `seedvr2_ema_7b` | 视频超分 |

## text_encoders/ （文本编码器）

| 家族 | 文件名需包含 |
|---|---|
| H3 | `qwen3vl_32b_minimax_h3_bf16` |
| Qwen Image | `qwen_image_2.1`（或 `qwen_2.5_vl`） |
| Z-Image | `qwen_3_4b` |
| Wan | `umt5_xxl_fp16`（不要用 nsfw 版本，tokenizer 会报错） |
| Music3 | `music3_text_encoder` |

## vae/

| 用途 | 文件名需包含 |
|---|---|
| H3 视频 | `minimax_h3_video_vae` |
| H3 音频 | `minimax_h3_audio_vae` |
| Z-Image | `z_image_vae` 或 `ae.safetensors` |
| Qwen 编辑 | `qwen_image_vae`（16 通道；**不要**误用 2.1 的 64 通道 VAE） |
| SeedVR2 | `seedvr2` + `vae` |

## checkpoints/

任意 SD1.5 / SDXL 一个即可，用于 `auto.sd.t2i` 兜底出图。

## audio_encoders/

Music3 的音频编码器（如果模型卡要求）。

## 公共模型（AutoDL）

平台公共存储里的模型可以直接软链，**用户零下载**。实例内路径固定为 `/.autodl/...`。

| 用途 | 公共路径 | 大小 |
|---|---|---|
| H3 文本编码器（int8） | `/.autodl/Comfy-Org/MiniMax-H3/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors` | 25.3 GB |
| H3 文本编码器（bf16） | `/.autodl/Comfy-Org/MiniMax-H3/text_encoders/qwen3vl_32b_minimax_h3_bf16.safetensors` | 48.0 GB |
| H3 视频 VAE | `/.autodl/Comfy-Org/MiniMax-H3/vae/minimax_h3_video_vae_fp16.safetensors` | 4.85 GB |
| H3 音频 VAE | `/.autodl/Comfy-Org/MiniMax-H3/vae/minimax_h3_audio_vae_fp32.safetensors` | 0.58 GB |
| H3 参考图主干（社区） | 搜 `minimax_h3_ref2va`，约 15–20 GB | 15–20 GB |
| H3 首尾帧主干（社区） | 搜 `minimax_h3_fl2va`，或 8 步蒸馏版 3.6 GB | 3.6–20 GB |

**软链写法**：

```bash
ln -sfn /.autodl/Comfy-Org/MiniMax-H3/text_encoders/qwen3vl_32b_minimax_h3_int8_convrot.safetensors \
        /root/ComfyUI/models/text_encoders/
```

**风险**：公共模型由上传者维护，可能被删除。所以脚本必须"软链失败就下载"，不能只依赖软链。

## 命名踩坑记录

这些都是真机验证时踩过的，装镜像时直接避开：

| 现象 | 原因 |
|---|---|
| `size of tensor a (64) must match (16)` | Qwen 编辑用了 2.1 的文生图 VAE |
| `invalid tokenizer` | Wan 用了 `nsfw_wan_umt5-xxl_bf16` |
| `Cannot copy out of meta tensor` | Wan 用了 `umt5-xxl-enc-*` 纯编码器权重 |
| `value_not_in_list` | 工作流引用的权重建包后被删了 |
| 出图糊、和参考图无关 | 完整模型只给了 8 步（应为 28 步） |
