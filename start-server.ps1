# start-server.ps1
# 启动 more-excalicord 的 Windows 本地服务。
#
# 用法：
#   powershell -ExecutionPolicy Bypass -File start-server.ps1
#   powershell -ExecutionPolicy Bypass -File start-server.ps1 -Force          # 自动结束占用端口的旧进程
#   powershell -ExecutionPolicy Bypass -File start-server.ps1 -Port 5002      # 换端口
#
# Node 查找顺序（免安装优先）：
#   1) -NodeExe 显式指定
#   2) 本目录 node\node.exe            ← 包内自带的便携版
#   3) 本目录 node*\node.exe           ← 你手动解压的便携版（如 node-v24.21.0-win-x64\）
#   4) 系统 PATH 里的 node             ← 已正常安装 Node 的机器

[CmdletBinding()]
param(
  [int]$Port = 5001,
  [switch]$Force,
  [string]$NodeExe = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

if (-not (Test-Path "no-cache-server.js")) {
  Write-Host "未找到 no-cache-server.js，请确认压缩包已完整解压。" -ForegroundColor Red
  exit 1
}

# ---- 解析 Node ----
function Resolve-NodeExe {
  param([string]$Hint)

  if ($Hint -and (Test-Path -LiteralPath $Hint)) { return (Get-Item -LiteralPath $Hint).FullName }

  $candidates = @()
  $candidates += (Join-Path $here "node\node.exe")
  Get-ChildItem -LiteralPath $here -Directory -Filter "node*" -ErrorAction SilentlyContinue | ForEach-Object {
    $candidates += (Join-Path $_.FullName "node.exe")
  }
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { return (Get-Item -LiteralPath $c).FullName }
  }

  $cmd = Get-Command node -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  return ""
}

$node = Resolve-NodeExe -Hint $NodeExe

if (-not $node) {
  Write-Host ""
  Write-Host "  [错误] 没有找到 Node.js" -ForegroundColor Red
  Write-Host ""
  Write-Host "  本压缩包应当自带便携版：node\node.exe" -ForegroundColor Yellow
  Write-Host "  如果缺失，请到 https://nodejs.org 下载 win-x64 的 ZIP（免安装版），" -ForegroundColor Yellow
  Write-Host "  解压后把整个文件夹放进本目录（名字以 node 开头即可）再重试。" -ForegroundColor Yellow
  Write-Host ""
  exit 1
}

# ---- 端口占用检查 ----
$existing = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($existing) {
  $pids = @($existing | Select-Object -ExpandProperty OwningProcess -Unique)

  # 判断占用者是不是"本服务自己的旧实例"（进程可执行文件就是我们解析出来的那个 node）
  $ownPids = @()
  foreach ($p in $pids) {
    $proc = Get-Process -Id $p -ErrorAction SilentlyContinue
    if ($proc -and $proc.Path -and ($proc.Path -eq $node)) { $ownPids += $p }
  }

  if ($Force) {
    foreach ($p in $pids) { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue }
    Write-Host "已结束占用端口 ${Port} 的进程：$($pids -join ', ')（-Force）" -ForegroundColor Yellow
    Start-Sleep -Milliseconds 900
  }
  elseif ($ownPids.Count -eq $pids.Count) {
    # 全是自己的旧实例 —— 自动接管，省得用户手动去杀进程
    foreach ($p in $pids) { Stop-Process -Id $p -Force -ErrorAction SilentlyContinue }
    Write-Host "检测到上一次的服务实例仍在运行（PID $($pids -join ', ')），已自动接管。" -ForegroundColor Yellow
    Start-Sleep -Milliseconds 900
  }
  else {
    Write-Host "端口 ${Port} 被其它程序占用了，PID：$($pids -join ', ')" -ForegroundColor Red
    Write-Host "为安全起见没有自动结束它。请关闭那个程序，或改用：" -ForegroundColor Yellow
    Write-Host "  start-server.ps1 -Force" -ForegroundColor White
    exit 1
  }
}

Write-Host ""
Write-Host "正在启动本地服务…" -ForegroundColor Cyan
Write-Host "  Node   ：$node" -ForegroundColor DarkGray
Write-Host "  地址   ：http://127.0.0.1:$Port/" -ForegroundColor White
Write-Host "  用 Chrome 或 Edge 打开上面的地址（不要用 localhost，服务绑定在 127.0.0.1）" -ForegroundColor Yellow
Write-Host "  保持本窗口开启；按 Ctrl+C 停止服务" -ForegroundColor DarkGray
Write-Host ""

& $node no-cache-server.js

Write-Host ""
Write-Host "服务已退出。" -ForegroundColor DarkGray
if ($LASTEXITCODE -ne 0) { Write-Host "退出码：$LASTEXITCODE" -ForegroundColor Red }
