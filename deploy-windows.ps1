# deploy-windows.ps1
# 把 more-excalicord 部署成本机（Windows）可运行的版本。
# 幂等，可重复执行；只做复制与校验，不修改 any 源码。
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File deploy-windows.ps1
#   powershell -ExecutionPolicy Bypass -File deploy-windows.ps1 -RepoRoot "D:\path\to\more-excalicord-main"

[CmdletBinding()]
param(
  [string]$RepoRoot      = "..\more-excalicord-main",
  [string]$Target        = ".",
  [string]$ExcalidrawPkg = "_tmp\pkg\package"
)

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

function Resolve-Dir([string]$p) {
  if (-not (Test-Path $p)) { throw "目录不存在：$p" }
  return (Resolve-Path $p).Path
}

$repo = Resolve-Dir $RepoRoot
$root = Resolve-Dir $Target

Write-Host ""
Write-Host "== more-excalicord -> Windows 部署 ==" -ForegroundColor Cyan
Write-Host "  源码仓库 : $repo"
Write-Host "  部署目标 : $root"
Write-Host ""

# ---- 1. 前端录制器 ----
$recorderDir = Join-Path $root "build\recorder"
$vendorDir   = Join-Path $recorderDir "vendor"
$existingRecorder = Join-Path $recorderDir "studio-recorder.js"

# 当前 Windows 发行版在该文件中包含浏览器录屏、项目文件夹和浏览器内画中画合成。
# 上游仓库尚未包含这些改动，直接复制会静默覆盖它们。
if ((Test-Path $existingRecorder) -and ([System.IO.File]::ReadAllText($existingRecorder, [System.Text.Encoding]::UTF8).Contains("[windows-browser-compose]"))) {
  throw "已停止部署：上游源码不含 Windows 浏览器录制补丁，继续会覆盖 build\recorder\studio-recorder.js。当前发行版可直接使用；更新时请先将补丁维护到上游源码。"
}

New-Item -ItemType Directory -Force -Path $recorderDir, $vendorDir | Out-Null

$srcFiles = Get-ChildItem (Join-Path $repo "src") -File | Where-Object { $_.Extension -in ".js", ".css" }
foreach ($f in $srcFiles) { Copy-Item $f.FullName $recorderDir -Force }
Copy-Item (Join-Path $repo "src\vendor\*") $vendorDir -Recurse -Force

Write-Host ("  [1/4] 前端录制器   -> build\recorder  ({0} 个文件 + vendor)" -f $srcFiles.Count) -ForegroundColor Green

# ---- 2. 本地服务 ----
$serverFiles = Get-ChildItem (Join-Path $repo "server") -File | Where-Object { $_.Extension -in ".js", ".py" }
foreach ($f in $serverFiles) { Copy-Item $f.FullName $root -Force }

Write-Host ("  [2/4] 本地服务     -> 根目录        ({0} 个文件)" -f $serverFiles.Count) -ForegroundColor Green

# ---- 2b. Windows 补丁：显式绑定 IPv4 回环 ----
# 原代码是 server.listen(PORT, 'localhost')。在 Windows 上 'localhost' 会被解析为
# IPv6 ::1，服务只监听 ::1，于是 http://127.0.0.1:5001 被主动拒绝（只有 localhost 能用）。
# 把补丁做成部署流程的一部分，保证幂等：重复部署多少次，产物都是已打补丁的版本。
# （上一轮就是因为这步没进部署脚本，重跑部署把手工补丁覆盖回原样了。）
$srv = Join-Path $root "no-cache-server.js"
if (Test-Path $srv) {
  $srvText = [System.IO.File]::ReadAllText($srv, [System.Text.Encoding]::UTF8)
  $srvNew  = $srvText -replace "server\.listen\(PORT,\s*'localhost'", "server.listen(PORT, '127.0.0.1'"
  $srvNew  = $srvNew  -replace "running on http://localhost:", "running on http://127.0.0.1:"
  if ($srvNew -ne $srvText) {
    [System.IO.File]::WriteAllText($srv, $srvNew, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "  [2b/4] Windows 补丁  已应用：listen('localhost') -> listen('127.0.0.1')" -ForegroundColor Green
  } else {
    Write-Host "  [2b/4] Windows 补丁  已存在，跳过（幂等）" -ForegroundColor DarkGray
  }
} elseif (-not (Test-Path $srv)) {
  Write-Host "  [2b/4] Windows 补丁  跳过：no-cache-server.js 未就位" -ForegroundColor Yellow
}

# ---- 3. Excalidraw 运行时 ----
$libDir = Join-Path $root "build\excalidraw-lib"
New-Item -ItemType Directory -Force -Path $libDir | Out-Null

$pkgRoot   = Join-Path $here $ExcalidrawPkg
$pkgCss    = Join-Path $pkgRoot "dist\prod\index.css"
$pkgFonts  = Join-Path $pkgRoot "dist\prod\fonts"

if ((Test-Path $pkgCss) -and (Test-Path $pkgFonts)) {
  Copy-Item $pkgCss $libDir -Force
  Copy-Item $pkgFonts (Join-Path $libDir "fonts") -Recurse -Force
  Write-Host "  [3/4] Excalidraw   -> build\excalidraw-lib (index.css + fonts)" -ForegroundColor Green
} else {
  Write-Host "  [3/4] Excalidraw   跳过：未找到 npm 包解压目录" -ForegroundColor Yellow
  Write-Host "        期望位置：$pkgRoot" -ForegroundColor DarkGray
  Write-Host "        获取方式：下载 https://registry.npmjs.org/@excalidraw/excalidraw/-/excalidraw-0.18.1.tgz" -ForegroundColor DarkGray
  Write-Host "                  然后 tar -xzf excalidraw-0.18.1.tgz -C _tmp\pkg" -ForegroundColor DarkGray
}

# ---- 4. 校验 ----
$required = @(
  "build\index.html",
  "build\recorder\studio-recorder.js",
  "build\recorder\native-bridge.js",
  "build\recorder\recorder.css",
  "build\excalidraw-lib\index.css",
  "no-cache-server.js",
  "render-core.js"
)

$missing = @()
foreach ($rel in $required) {
  $full = Join-Path $root $rel
  if (-not (Test-Path $full)) { $missing += $rel }
}

if ($missing.Count -eq 0) {
  Write-Host "  [4/4] 校验通过     全部关键文件就位" -ForegroundColor Green
} else {
  Write-Host "  [4/4] 校验失败     缺少以下文件：" -ForegroundColor Red
  $missing | ForEach-Object { Write-Host "        - $_" -ForegroundColor Red }
}

Write-Host ""
if ($missing.Count -eq 0) {
  Write-Host "部署完成。启动方式：" -ForegroundColor Cyan
  Write-Host "  powershell -ExecutionPolicy Bypass -File start-server.ps1" -ForegroundColor White
  Write-Host ""
  Write-Host "注意：服务绑定 127.0.0.1。请在浏览器打开 http://127.0.0.1:5001/" -ForegroundColor Yellow
} else {
  Write-Host "部署未完成，请先解决上面列出的缺失项。" -ForegroundColor Red
  exit 1
}
