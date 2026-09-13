# Excalicord+

> 在线白板、幻灯片、整屏/窗口与画中画录制工具。

<p align="center">
  <a href="https://excalicord.learnbox.cc"><strong>立即在线使用</strong></a>
  &nbsp;·&nbsp;
  <a href="#怎么使用">使用说明</a>
  &nbsp;·&nbsp;
  <a href="#能力与边界">能力与边界</a>
</p>

<p align="center">
  <a href="https://excalicord.learnbox.cc">
    <img src="docs/excalicord-online.svg" alt="Excalicord+ 支持白板、幻灯片、整屏或窗口录制，以及摄像头画中画；录制内容保存到用户本地文件夹" width="900" />
  </a>
</p>

## 在线版已上线

访问 **[excalicord.learnbox.cc](https://excalicord.learnbox.cc)** 即可使用，无需安装 Node、Docker 或桌面客户端。站点由 Cloudflare Pages 从本仓库的 `main` 分支自动部署，并已启用 HTTPS。

录制采集、编码和保存都在浏览器及你选择的本地文件夹中完成；录制内容不会上传到网站服务器。

## 可以录什么

| 场景 | 录制范围 | 适用用途 |
| --- | --- | --- |
| 白板全景 | Excalidraw 画布 | 课程、知识讲解、方案梳理 |
| 当前幻灯片 | 当前 Frame | 单页 PPT / 方案逐页讲解 |
| 整个屏幕 | 系统共享选择器中的“整个屏幕” | 演示跨应用流程 |
| 指定窗口 | 系统共享选择器中的某个窗口 | 软件演示，避免录到其他内容 |

所有模式都可以开启摄像头画中画，并可选择位置、形状和镜像。白板、幻灯片与浏览器标签页录制会实时烘焙画中画；整屏或窗口录制会保留摄像头素材，并可在浏览器内合成为最终视频。

## 怎么使用

1. 用桌面版 Chrome 或 Edge 打开 [在线版](https://excalicord.learnbox.cc)。
2. 点击右侧的 **“打开 more-excalicord”**，首次使用时选择一个本地项目文件夹。
3. 在录制面板选择范围、麦克风和摄像头画中画，然后开始录制。
4. 停止后，原始录制会保存到你选择的文件夹；需要时点击“保存合成视频”导出最终成片。

文件目录由浏览器直接创建，例如：

```text
你选择的文件夹/
├── recordings/
│   └── <sessionId>/
│       ├── xxx.mp4 或 xxx.webm
│       └── webcam-xxx.mp4（开启独立摄像头素材时）
└── exports/
    └── final.mp4 或 final.webm
```

## 已实现

- 白板全景、当前幻灯片、整屏和指定窗口录制
- 摄像头画中画：四角位置、圆角/圆形、镜像与跨窗口预览
- 浏览器内合成整屏/窗口录制的画中画视频，无需安装 ffmpeg
- `showDirectoryPicker()` 本地文件夹保存，不需要把录制内容交给服务器
- 优先输出 MP4；浏览器不支持相应编码时自动降级为 WebM
- Cloudflare Pages 持续部署与自定义域名 HTTPS

## 能力与边界

| 项目 | 在线版状态 | 说明 |
| --- | --- | --- |
| 白板 / Frame 录制 | ✅ | 使用 `canvas.captureStream()` |
| 整屏 / 窗口录制 | ✅ | 使用 `getDisplayMedia()`，由系统选择器授权 |
| 摄像头画中画与导出 | ✅ | 在浏览器内合成；合成时请保持页面在前台 |
| 保存到本地文件夹 | ✅ | 依赖 File System Access API |
| 系统音频 | ⚠️ | 浏览器和系统共享设置决定是否能提供音轨 |
| 录后编辑工作台、自动字幕 | ❌ | 仍依赖本地 Node/Python 流程，未放到在线版 |
| 手机、Safari、Firefox | ⚠️ | 核心 API 支持不完整；推荐桌面 Chrome / Edge |

整屏或窗口录制时，浏览器会弹出系统共享选择器；请只选择你愿意录入视频的屏幕、标签页或窗口。若使用“悬浮小窗预览”录制整个屏幕，该小窗本身也可能被录进画面。

## 本地 Windows 版

本仓库保留 Windows 本地版的启动与部署脚本，适合需要本地后处理或调试的场景。在线版的静态入口在 [`build/`](build/)；它使用 HTTPS 托管，不依赖本地服务。

> 注意：便携 Node 和发行压缩包不提交到 GitHub。普通用户优先使用在线版；需要本地运行时，请准备可用的 Node.js 后执行 `start-excalicord.bat`。

## 部署说明

Cloudflare Pages 设置：

```text
生产分支：main
构建命令：exit 0
构建输出目录：build
自定义域名：https://excalicord.learnbox.cc
```

推送到 `main` 后，Cloudflare 会自动重新部署。安全上下文（HTTPS）是屏幕共享与本地目录选择功能的前提。

## 来源

此项目以 [more-excalicord](https://github.com/bingyunjiang/more-excalicord) 为蓝本，并使用 [Excalidraw](https://github.com/excalidraw/excalidraw) 作为白板能力。Windows 与在线版补充了浏览器原生的整屏/窗口采集、本地保存和浏览器端画中画合成。
