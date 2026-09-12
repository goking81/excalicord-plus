# more-excalicord · Windows 本地版

在 Windows 上跑 [more-excalicord](https://github.com/bingyunjiang/more-excalicord)（原项目仅支持 macOS）。
保留原版全部录制能力，用浏览器原生能力替代 macOS 原生的 Capture Agent，**不需要装 .NET、Swift，也不需要管理员权限**。

---

## 〇、在新电脑上使用（免安装版）

1. 把包解压到**任意目录**（路径含中文、空格都没问题）
2. **双击 `start-excalicord.bat`**，保持那个黑窗口开着
3. 用 **Chrome 或 Edge** 打开 `http://127.0.0.1:5001/`

**不需要装任何东西。** 包里已经自带便携版 Node.js（`node\node.exe`，v24.21.0，实测可用）。

不需要管理员权限，不需要装 .NET、Python、ffmpeg；**不写注册表、不改系统环境变量、不碰系统里已装的 Node**。包内这个 Node 只在运行本服务时被调用。

### 它按什么顺序找 Node

双击 `start-excalicord.bat` 后，这个脚本会依次尝试，任一命中即可：



| 顺序 | 位置 | 说明 |
|---|---|---|
| 1 | `node\node.exe` | 包内自带（默认走这条） |
| 2 | `node*\node.exe` | 你自己解压的便携版，比如 `node-v24.21.0-win-x64\`，**文件夹名以 `node` 开头**就会被认出来 |
| 3 | 系统 PATH 里的 `node` | 机器上已经正常装过 Node 的情况 |

三条都没命中才会报错，并提示你去 [nodejs.org](https://nodejs.org) 下载 **win-x64 的 ZIP（免安装版）**——注意别下 `.msi`，那个要管理员权限。

### 为什么不走 PowerShell

`.bat` 是**直接运行 `node.exe`**，全程不碰 PowerShell。原因：不少机器（尤其公司电脑）把 PowerShell 执行策略设成 `Restricted`，此时任何 `.ps1` 都跑不起来——这是**机器级限制，靠命令行参数绕不过去**。而 `.exe` 完全不受执行策略管辖。所以 `start-excalicord.bat` 是唯一不依赖 PowerShell 的入口，也是默认推荐的入口。

> 唯一的外部依赖：首次加载页面时会从 `esm.sh` 取 React 和 Excalidraw，所以那台电脑要能联网。
> 之后浏览器会缓存，重复使用很快。

---

## 一、启动

**推荐：直接双击 `start-excalicord.bat`。** 它等价于在包目录里执行这条命令：

```bat
node\node.exe no-cache-server.js
```

然后在 **Chrome 或 Edge** 打开：

```
http://127.0.0.1:5001/
```

> 服务绑定在 `127.0.0.1`。`http://127.0.0.1:5001/` 和 `http://localhost:5001/` **两个都能用**。
> （早期版本绑的是 `localhost`，在 Windows 上被解析成 IPv6 `::1` 后只监听 `::1`，
> 导致 `127.0.0.1` 被拒绝连接 —— 已修复，并写进 `deploy-windows.ps1` 保证重复部署不会回退。）

### 进阶：PowerShell 启动器（可选）

`start-server.ps1` 会打印中文提示，并能**自动接管被上一次实例占用的端口**。用它需要那台机器允许运行脚本：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\start-server.ps1
```

> ⚠️ **必须带 `-ExecutionPolicy Bypass`。** 否则在默认策略（`Restricted`）的机器上会直接报
> 「无法加载文件 … 因为在此系统上禁止运行脚本」。
> 如果那台机器由**组策略**强制限制（`Get-ExecutionPolicy -List` 里 `MachinePolicy` / `UserPolicy` 不是 `Undefined`），
> 那么 `Bypass` 参数也会被忽略 —— 这种情况只能走「双击 `.bat`」那条路。

端口被占用时（手动用法）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\start-server.ps1 -Force
```

---

## 二、怎么录

打开页面后，**右侧会出现紫色工具栏**（四个按钮）——那就是 more-excalicord。

点录制按钮，面板里可以选录制范围：

| 你要录的 | 面板里选 |
|---|---|
| 白板全景 | 白板 / 画布范围 |
| 当前幻灯片 | Frame / 当前幻灯片 |
| 整个屏幕 | 屏幕范围 → 系统弹窗里选「整个屏幕」 |
| 指定窗口 | 屏幕范围 → 系统弹窗里选某个窗口 |

**第一次录之前，先选一个项目文件夹**（面板里的项目区）。
这是 File System Access API，浏览器会弹一个原生目录选择框，授权后录制的原始文件会自动存进去：

```
你选的文件夹/
└── recordings/
    └── <sessionId>/
        ├── xxx.mp4
        └── webcam-xxx.mp4    （如果开了独立摄像头素材）
```

录完点停止，会自动保存，并弹出「原始录制已就绪」。

### 画中画（摄像头）怎么出片

这里有个**原版的设计坑**，先说清楚它的逻辑：

- **录制白板 / 幻灯片，或共享「浏览器标签页」** —— 画中画是在录制时**实时合成**进画面的（canvas 合成）。
  停止录制后，`recordings/<sessionId>/xxx.mp4` **本身已经带画中画**，不需要任何后续合成。
- **共享「整个屏幕」或「某个窗口」** —— 为了让你切走或最小化浏览器后还能继续录，原版故意**不做实时合成**，
  而是把摄像头单独存成 `webcam-xxx.mp4`，留到录后由「成片服务」把两层合起来。

原版的成片服务是 **macOS 专属的 Swift 进程（127.0.0.1:5002）+ ffmpeg**。Windows 上没有它，
所以原版只会提示「连接本地成片服务后可生成合成视频」——**功能等于废掉**。

本 Windows 版把这个角色**搬进了浏览器**：

| 场景 | 点「保存合成视频」后发生什么 |
|---|---|
| 画面已含画中画（白板 / 幻灯片 / 标签页录制） | 直接另存为成片，**秒出**、无损 |
| 整屏 / 窗口录制 + 摄像头 | 在浏览器里把两层画到 canvas 再编码，**按视频时长实时生成** |
| 整屏 / 窗口录制，但没开摄像头 | 直接输出原始画面 |

成片落到项目文件夹的 `exports/final.mp4`（浏览器不支持 MP4 录制时降级为 `final.webm`）。
**不需要 ffmpeg，不需要额外安装任何东西。**

> ⚠️ 实时合成期间请**让这个页面保持在前台**。编码由 `requestAnimationFrame` 驱动，
> 标签页被切到后台会被浏览器降频，合成会卡帧甚至变慢。
> 时长 1 分钟的素材，合成大约也要 1 分钟。
>
> 另外，画中画的**位置 / 形状 / 镜像**沿用录制时的设置；但如果你开了美颜或虚拟背景，
> 独立摄像头素材存的是**原始画面**，后置合成不会带上美颜效果（实时烘焙的场景不受影响）。

### 录「其他窗口」时怎么看到自己

这是原版的一个体验缺口。摄像头气泡（那个圆形浮窗）是**网页内的浮层**，
只在浏览器窗口可见、且没被别的窗口盖住时才看得见，所以：

- 录**整个屏幕** → 浏览器一直在你眼前，气泡看得见 ✅
- 录**其他应用的窗口** → 那个窗口盖住了浏览器，气泡看不见 ❌
- 录**浏览器标签页**、又切到别的标签去做别的事 → 标签不在前台，气泡看不见 ❌

本版加了一个开关：**「摄像头与麦克风」→「预览」→ 勾选「悬浮小窗预览（跨窗口可见）」**。

它用系统级画中画（Picture-in-Picture API）开出一个**操作系统层面的独立小窗**，
**浮在所有应用窗口之上** —— 你切到哪个窗口它都在。可以随意拖动、缩放，点小窗的 × 关闭。
关闭后面板里的勾选会自动同步取消。

| 录制范围 | 悬浮小窗会不会被录进视频 |
|---|---|
| 某个窗口 / 浏览器标签页 | ✅ **不会** —— 它不在采集范围内 |
| 整个屏幕 | ⚠️ **会** —— 它就在屏幕里。要干净画面请先关掉它（此时气泡本来也看得见） |

> 这个开关**不影响画中画的合成结果**。合成用的仍是录制时那套位置 / 形状 / 镜像设置，
> 悬浮小窗纯粹是给你自己看的监看窗。
> 使用顺序：**先打开「摄像头画中画」，再勾选「悬浮小窗预览」**（勾早了它会提示你先开摄像头，并自动取消勾选）。

---

## 三、已知限制

相对 macOS 版少掉的能力，以及原因：

| 能力 | 状态 | 原因 |
|---|---|---|
| 白板全景 / 当前幻灯片录制 | ✅ 可用 | 用 `canvas.captureStream()`，不需要屏幕授权 |
| 整个屏幕 / 指定窗口录制 | ✅ 可用 | 用 `getDisplayMedia()`，走浏览器系统选择器 |
| 摄像头画中画 | ✅ 可用 | canvas 合成，四角位置 / 形状 / 镜像 |
| 摄像头悬浮小窗预览（跨窗口可见） | ✅ 可用（本版新增） | 系统画中画 API，浮在所有应用窗口之上；原版没有这个能力 |
| MP4 输出 | ✅ 优先 MP4 | 走 MediaRecorder 的 H.264；浏览器不支持时降级 WebM |
| 存盘到本地文件夹 | ✅ 可用 | File System Access API |
| **合成导出 final.mp4** | ✅ 可用（已修） | 已改为**浏览器内合成**（canvas + MediaRecorder）替代 macOS 成片服务，零依赖；需先选项目文件夹 |
| **录后编辑工作台** | ❌ 仍被门控 | `studio-recorder.js:8278` 强制要求 native 模式。与出片无关的独立功能，本版未动 |
| 带缩略图的原生来源列表 | ⚠️ 降级 | 浏览器不允许枚举屏幕源（隐私硬限制），改用系统选择器 |
| 系统音频 | ⚠️ 不保证 | 已请求 `systemAudio: "include"`，Windows Chrome 上不保证返回音轨；**麦克风一定可用** |
| 隐藏桌面图标 / 屏幕补光 | ❌ 无 | macOS 原生特性，本版本未实现 |

> **为什么"放开前端门控"救不了它**（这条曾经判断错，记下来避免再踩）：
> 合成导出调用的 `/api/render` 确实跑在 **Node（5001 端口）**上，但服务端内部
> `selectedProjectRoot()` 会去 **macOS agent 的 5002 端口**要项目文件夹的**绝对路径**。
> 浏览器通过 File System Access 拿到的 handle 是**取不到真实路径**的（浏览器安全设计），
> 所以服务端在 Windows 上永远拿不到目录 —— 堵点是**前端门控 + 服务端拿不到路径**两个，
> 不是物理限制，但也不是改几行前端就通。
> 本版的做法是**干脆绕开服务端**，直接在浏览器里完成合成。

---

## 四、依赖与离线

| 依赖 | 是否必需 | 说明 |
|---|---|---|
| Node.js | ✅ **已自带** | 包内 `node\node.exe`（v24.21.0 便携版）。免安装、免管理员权限 |
| `esm.sh` CDN | ✅ 必需（首次） | 页面从它加载 React 与 Excalidraw。**断网/被墙时页面会白屏** |
| ffmpeg | ⚠️ 可选 | 只有录后编辑、字幕、合成导出才需要；放 PATH 即可 |
| Python 3 | ⚠️ 可选 | 只有自动字幕（faster-whisper）才需要 |

**如果 esm.sh 不可达**：浏览器需要能走代理。本地 `build/excalidraw-lib/` 里已经放好了 Excalidraw 的 CSS 与字体，
但 JS 仍走 CDN；要彻底离线需要把 React 等依赖也本地化（改 `build/index.html` 的 importmap）。

---

## 五、目录结构

```
excalicord-win/
├── start-excalicord.bat      ★ 双击这个启动（纯 ASCII，直接跑 node.exe，不依赖 PowerShell）
├── start-server.ps1          可选进阶启动器（中文提示 + 端口自动接管，需 -ExecutionPolicy Bypass）
├── node/node.exe             包内自带的便携版 Node.js（免安装）
├── deploy-windows.ps1        从源码重新部署（幂等，含 Windows 绑定补丁）
├── no-cache-server.js        本地服务（已适配 Windows 监听地址）
├── render-core.js            成片渲染核心
├── render_caption_overlays.py / transcribe_audio.py
└── build/                    静态根目录
    ├── index.html            宿主页（自建，加载 Excalidraw + recorder）
    ├── excalidraw-lib/       Excalidraw 的 CSS 与字体
    └── recorder/             more-excalicord 的前端录制器
```

---

## 六、更新源码后重新部署

```powershell
powershell -ExecutionPolicy Bypass -File deploy-windows.ps1
```

它会从 `..\more-excalicord-main` 重新拷贝前端录制器与服务文件，并校验关键文件是否就位。

自定义路径：

```powershell
powershell -ExecutionPolicy Bypass -File deploy-windows.ps1 -RepoRoot "D:\code\more-excalicord-main"
```

---

## 七、相对原版改了什么

改动集中在「部署脚本」和「前端两处功能补齐」，逐条列清楚：

1. **新增 `build/index.html`** —— 自建宿主页，用 importmap 加载 Excalidraw，再按序加载 recorder 脚本。
   原项目靠 `deploy-local.sh` 往自托管 Excalidraw 的 `index.html` 里注入 script 标签，这里改为独立宿主页，绕开源码 `yarn build`。
2. **`no-cache-server.js` 监听地址** —— `localhost` → `127.0.0.1`（修 Windows 上只监听 IPv6 `::1` 的问题）。
   这一步同时写进了 `deploy-windows.ps1`，重复部署不会把这个补丁覆盖回去。
3. **新增 `start-excalicord.bat` + `start-server.ps1`** 替代原项目的 bash + perl 部署/启动流程，并内置便携版 Node 的查找逻辑。
4. **`no-cache-server.js` 增加端口占用提示** —— 监听到 `EADDRINUSE` 时打印一句人话（而不是甩一段堆栈），提示"上一个 Excalicord 窗口可能还开着"。
5. **`build/recorder/studio-recorder.js` 新增「浏览器端成片」** —— 本版两处**功能级**改动之一（另一处见第 6 条）。
   全部用 `[windows-browser-compose]` 注释标出（共 8 个标记点），新增 11 个函数：
   `browserComposeAvailable` / `browserCompositionExt` / `browserCompositionExists` / `readBrowserProjectFile`
   / `blobToVideoElement` / `releaseVideoElement` / `drawPiPFrame` / `reportComposeProgress`
   / `writeBrowserCompositionBlob` / `composeInBrowser` / `openBrowserComposition`，
   并改动了 6 处既有函数：`updateOutputActions`、`refreshExistingCompositionStatus`、
   `chooseBrowserSaveFolder`、`ensureRecordingSavedForComposition`、`saveCompositionVideo`、`openCompositionVideo`。
   同时放宽 `:5933`、`:8141` 两处 `mode !== "native"` 硬门控。
   核心思路：**录制流程一行未改**（`_startRecordingInner` / `composeDrawLoop` 原样保留），
   只在"录完之后"补上原本由 macOS 服务承担的那一步合成。
   `drawPiPFrame` 是照抄 `composeDrawLoop` 里的画中画绘制逻辑，保证"录时所见"与"合成所得"位置一致。
6. **`build/recorder/studio-recorder.js` 新增「摄像头悬浮小窗预览」** —— 全部用 `[camera-pip-preview]` 标记。
   面板加了一个开关（`#ec-pip-preview`），新增 `pipPreviewSupported` / `isPipPreviewActive` /
   `syncPipPreviewCheckbox` / `enterPipPreview` / `exitPipPreview` 五个函数，
   并在 `startCamera`（补挂 `leavepictureinpicture` 监听）、`stopCamera`（顺手关小窗）、
   整屏录制分支（提醒小窗会被录进去）三处接了进去。
   动机：气泡是网页内浮层，录别的窗口时被盖住，看不到自己的状态。

> ⚠️ **改 `start-excalicord.bat` 时的三条硬约束。** 这个文件已经踩过两次坑，改之前先读完：
>
> **（1）必须保持纯 ASCII** —— 连注释都别放中文。
> 踩过的坑：早期版本里写了 `chcp 65001` + 中文提示，结果在 cmd.exe 里爆炸，满屏
> 「XXX 不是内部或外部命令」外加乱码。原因是 cmd.exe 在切码页后会**读错批处理文件的字节偏移**，
> 把后面的文字碎片当命令执行——多字节字符越多，错得越离谱。
>
> **（2）绝对不要在这个文件里调用 PowerShell。**
> 踩过的坑：曾经写成 `powershell -ExecutionPolicy Bypass -File start-server.ps1`，
> 结果在把执行策略锁成 `Restricted` 的机器上整条链断掉。
> 现在是**直接运行 `node.exe`** —— `.exe` 不受执行策略管辖，这是唯一稳的路径。
>
> **（3）不要有 BOM**（cmd 会把 BOM 当命令）。反过来，`.ps1` **必须**有 BOM。
> 校验手段：读出字节数组，统计 `> 127` 的数量，应为 0。

除上面第 5、6 条之外，`build/` 下的前端录制器代码未做其他改动；`:8278` 那处「录后编辑」门控也保持原样。

> ⚠️ **已知未做**：源码 `no-cache-server.js` 第 11–12 行的 ffmpeg/ffprobe 探测仍是 macOS 写法
> （`/opt/homebrew/bin` 优先，找不到则回退 PATH）。在 Windows 上只要你把 ffmpeg 加进 PATH 就能工作，
> 所以没改；但"自动扫描 Windows 常见安装路径"这一层**尚未实现**。
> 同理 Python 解释器仍按 `python3` / `.venv-asr/bin/python` 查找，Windows 下的 `python.exe` 分支**尚未加入**。
> 这两项只影响录后编辑与自动字幕（而那两处前端门控本来就是关的），不影响录制与存盘。

---

## 八、部署到自己的域名

**可行，而且比预想的简单**——因为录制全程在浏览器里完成，数据根本不经过服务器。

### 为什么可以是纯静态

四种录制模式走的都是浏览器原生 API：

- `canvas.captureStream()` / `getDisplayMedia()` 拿媒体流
- `MediaRecorder` 负责编码
- **File System Access API 直接写你的本地磁盘**

服务器只负责**发代码**。录制数据一个字节都不上传。这正是它不需要 Node 后端的原因。

### Cloudflare Pages 部署

这个仓库用 Cloudflare Pages 连接 GitHub 的 `main` 分支部署即可：

1. 在 Cloudflare Pages 创建 Git 集成项目，选择本仓库与 `main` 分支。
2. 构建命令填 `exit 0`，构建输出目录填 `build`。
3. 在 Pages 的自定义域名中添加 `excalicord.learnbox.cc`；Pages 会签发 HTTPS 证书。

每次推送 `main`，Cloudflare 会自动重新部署。**必须 HTTPS** —— `getDisplayMedia` 和 `showDirectoryPicker` 都要求安全上下文，纯 HTTP 下这两个能力直接不可用。

然后访问 `https://excalicord.learnbox.cc/` 就能用。不需要服务器端运行环境。

### 域名版会少掉什么

| 功能 | 域名版 |
|---|---|
| 白板全景 / 当前幻灯片录制 | ✅ 可用 |
| 整屏 / 指定窗口录制 | ✅ 可用 |
| 摄像头画中画 | ✅ 可用 |
| MP4 输出 | ✅ 可用 |
| 存到本地文件夹 | ✅ 可用（File System Access API） |
| 浏览器内合成导出 | ✅ 可用（整屏 / 窗口录制可在浏览器内合成画中画） |
| 录后编辑工作台 | ❌ 无（依赖本地 Node 的 `/api/render`） |
| 自动字幕 | ❌ 无（依赖本地 Python） |

### 取舍

**好处**：桌面版 Chrome / Edge 在任何系统打开就能用，不用装 Node。这才是"跨系统"的真正解法。
**代价**：本地录后编辑与自动字幕不可用；但白板、幻灯片、整屏 / 窗口录制、画中画合成和存文件均不受影响。

> 域名版和本地版**可以并存**。本地版功能全（能渲染成片），域名版便携（到处能开）。
