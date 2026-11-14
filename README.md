# CineGraph 工作站镜像源仓库

仓库地址：https://github.com/song19910408/cinegraph-image

这是 AutoDL / AutoDL.Art **社区镜像**的配套仓库，只放运行环境和说明，**不含模型权重，也不含客户端源码**。

- 镜像提供算力端：ComfyUI + 视频节点 + ffmpeg
- 权重放数据盘，开机时从公共存储软链，镜像保持小巧
- 客户端（CineGraph 桌面版）另行分发

## 一、镜像里有什么

| 内容 | 说明 |
|---|---|
| Python + PyTorch（用 AutoDL 基础镜像自带） | 跟随基础镜像的 CUDA 版本 |
| ComfyUI | 固定目录探测：`/root/ComfyUI`、`/opt/ComfyUI` 等 |
| ComfyUI-VideoHelperSuite | 视频合成、帧序列 |
| ComfyUI-SeedVR2_VideoUpscaler | 视频超分 |
| ComfyUI-Manager | 缺节点时一键补装 |
| ffmpeg / 中文字体 | 编解码、字幕 |

**不含**：模型权重（约 100 GB）、客户端、账号信息。

## 二、安装（做镜像时执行一次）

```bash
source /etc/network_turbo      # AutoDL 学术加速，GitHub 才通
bash first-run.sh install
python3 check.py               # 最后一行必须是 OK
```

## 三、用户怎么用

开机器时选这个社区镜像 → 数据盘 ≥ 100 GB → 终端执行：

```bash
bash /root/cinegraph-image/first-run.sh
```

脚本会：

1. 扫描 `/.autodl` 公共存储，把 H3 权重软链进 ComfyUI（零拷贝）
2. 在 `8188` 端口启动 ComfyUI
3. 打印访问地址

然后在 CineGraph 客户端：**设置 → 算力 → 粘贴地址 → 重新检测依赖**。

## 四、示例工作流

`workflows/*.api.json` 是从客户端导出的 **ComfyUI API 格式**执行图，覆盖：

```
t2v / i2v / ref2v        基础三件套
i2v.std / sef.std        标准 20 步（含二采放大）
t2v.std / ref2v.std      同上，文生 / 多参考
i2v.turbo / ref2v.turbo  8 步 Turbo LoRA
```

用途：

- 学习工作流结构（节点、连线、必填参数都在里面）
- 在 CineGraph 里导入后直接跑（导入支持 API 格式）
- **不是** ComfyUI 网页端「Load」按钮能读的 UI 格式，别拖进 ComfyUI

## 五、发布到 AutoDL.Art

1. 在 AutoDL 上把装好的实例**保存镜像**（关机 → 更多 → 保存镜像）
2. 打开 AutoDL.Art → `+` → 镜像
3. 基本信息填本仓库地址，导入镜像选刚保存的那个
4. README 直接贴本文件

审核标准：`/root` 下有本仓库，且能执行简单命令（这里就是 `python3 check.py`）。

## 六、常见问题

**Q：`check.py` 报 `comfy import` 失败？**
A：`main.py` 所在目录的依赖没装全，执行 `pip install -r requirements.txt` 后重跑。

**Q：公共存储里没有 H3 权重？**
A：先确认实例挂了公共模型存储；没有的话把权重放到 `/root/autodl-tmp/models/`，脚本会自动复制进 ComfyUI。

**Q：端口打不开？**
A：AutoDL 需要从「自定义服务」进入；启动参数已带 `--listen 0.0.0.0`。
