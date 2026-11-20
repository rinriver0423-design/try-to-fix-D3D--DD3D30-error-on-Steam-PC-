$ErrorActionPreference = 'Stop'

# ============================================================
#  GTA4 DD3D30 / D3D Error 修复包 —— 一键安装脚本
#  把本文件（或整个文件夹）解压后双击运行即可。
#  脚本会自动定位 Steam 版 GTA4 的安装目录，备份原文件，再写入修复文件。
# ============================================================

$src = $PSScriptRoot
if (-not $src) { $src = (Get-Location).Path }
# 确认修复文件确实在脚本旁边（防止从别处调用导致找不到源文件）
if (-not (Test-Path (Join-Path $src 'd3d9.dll'))) {
    $alt = Join-Path (Split-Path $src -Parent) ''
    if ((Test-Path (Join-Path $alt 'd3d9.dll'))) { $src = $alt }
}

function Say($msg, $color = 'Gray') {
    Write-Host $msg -ForegroundColor $color
}

function Find-GameDir {
    # 1) Steam 注册表
    $steamRoots = @()
    $regPaths = @(
        @{ Path = 'HKCU:\Software\Valve\Steam'; Name = 'SteamPath' },
        @{ Path = 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam'; Name = 'InstallPath' },
        @{ Path = 'HKLM:\SOFTWARE\Valve\Steam'; Name = 'InstallPath' }
    )
    foreach ($r in $regPaths) {
        try {
            $v = (Get-ItemProperty -Path $r.Path -Name $r.Name -ErrorAction Stop).($r.Name)
            if ($v) { $steamRoots += $v }
        } catch { }
    }
    # 2) 常见安装位置
    foreach ($p in @("$env:ProgramFiles(x86)\Steam", 'C:\Program Files (x86)\Steam', "$env:ProgramFiles\Steam", 'D:\Steam', 'E:\Steam', 'F:\Steam')) {
        if (-not $p) { continue }
        try { if (Test-Path (Join-Path $p 'steamapps')) { $steamRoots += $p } } catch { }
    }
    $steamRoots = $steamRoots | Select-Object -Unique

    $libRoots = @()
    foreach ($s in $steamRoots) {
        $libRoots += $s
        $vdf = Join-Path $s 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            $content = Get-Content $vdf -Raw -ErrorAction SilentlyContinue
            foreach ($m in [regex]::Matches($content, '"path"\s+"([^"]+)"')) {
                $libRoots += $m.Groups[1].Value
            }
        }
    }
    $libRoots = $libRoots | Select-Object -Unique

    $rel = 'steamapps\common\Grand Theft Auto IV\GTAIV'
    foreach ($l in $libRoots) {
        $cand = Join-Path $l $rel
        if (Test-Path (Join-Path $cand 'GTAIV.exe')) { return $cand }
    }
    # 3) 全盘常见盘符扫一遍（Steam 之外的非标准安装）
    foreach ($d in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
        if (-not $d.Root) { continue }
        foreach ($guess in @(
            "$($d.Root)SteamLibrary\steamapps\common\Grand Theft Auto IV\GTAIV",
            "$($d.Root)Games\Steam\steamapps\common\Grand Theft Auto IV\GTAIV",
            "$($d.Root)Grand Theft Auto IV\GTAIV"
        )) {
            if (Test-Path (Join-Path $guess 'GTAIV.exe')) { return $guess }
        }
    }
    return $null
}

Say ''
Say '===============================================' 'Cyan'
Say '  GTA4  D3D Error / DD3D30  修复安装程序' 'Cyan'
Say '===============================================' 'Cyan'
Say ''
Say "安装包目录: $src" 'DarkGray'
Say ''

# ---------- 1. 定位游戏目录 ----------
$game = Find-GameDir
if (-not $game) {
    Say '[X] 没能自动找到 GTA4 的安装目录。' 'Yellow'
    Say ''
    Say '请手动指定。把游戏根目录（就是 GTAIV.exe 所在的那层）拖进本窗口，' 'Yellow'
    Say '或者复制路径粘贴进来，然后按回车：' 'Yellow'
    Write-Host -NoNewline '> ' -ForegroundColor Cyan
    $manual = (Read-Host).Trim().Trim('"')
    if ($manual -and (Test-Path (Join-Path $manual 'GTAIV.exe'))) {
        $game = $manual
    } else {
        Say ''
        Say '[X] 路径无效，安装已取消。（没有改动任何文件）' 'Red'
        Read-Host '按回车退出'
        exit 1
    }
}
Say "[OK] 找到游戏目录: $game" 'Green'
Say ''

# ---------- 2. 备份原文件 ----------
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$bak = Join-Path $game "_backup_before_fix_$stamp"
$items = @('d3d9.dll', 'dinput8.dll', 'commandline.txt', 'plugins', 'dxgi.dll', 'd3d9.cfg')
$bakCount = 0
foreach ($it in $items) {
    $p = Join-Path $game $it
    if (Test-Path $p) {
        New-Item -ItemType Directory -Path $bak -Force | Out-Null
        try {
            Copy-Item $p $bak -Recurse -Force -ErrorAction Stop
            $bakCount++
        } catch { }
    }
}
if ($bakCount -gt 0) {
    Say "[OK] 已备份原文件 ($bakCount 个) 到: $bak" 'Green'
} else {
    Say '[--] 没有需要备份的原文件（可能是全新安装）' 'DarkGray'
}
Say ''

# ---------- 3. 写入修复文件 ----------
$srcItems = @('d3d9.dll', 'dinput8.dll', 'plugins', 'commandline.txt')
$okCount = 0
$missing = @()
$failed = @()
foreach ($it in $srcItems) {
    $s = Join-Path $src $it
    if (-not (Test-Path $s)) { $missing += $it; continue }
    $d = Join-Path $game $it
    try {
        if ((Test-Path $d) -and (Get-Item $d).PSIsContainer) {
            Copy-Item $s $d -Recurse -Force -ErrorAction Stop
        } else {
            Copy-Item $s $d -Force -ErrorAction Stop
        }
        Say "[OK] 已安装: $it" 'Green'
        $okCount++
    } catch {
        Say "[X] 写入失败: $it  -> $($_.Exception.Message)" 'Red'
        $failed += $it
    }
}
Say ''

if ($missing.Count -gt 0) {
    Say "[!] 修复包里缺少这些文件，无法安装: $($missing -join ', ')" 'Yellow'
    Say "    安装包目录: $src" 'DarkGray'
    Say '    请确认解压时把整个文件夹完整解压出来了（不要只解压部分文件）。' 'Yellow'
    Say ''
}
if ($failed.Count -gt 0) {
    Say "[!] 以下文件写入失败（通常是权限不足）: $($failed -join ', ')" 'Yellow'
    Say '    请关闭本程序，右键本文件选择"以管理员身份运行"再试一次。' 'Yellow'
    Say ''
}

if ($okCount -eq 0) {
    Say '[X] 没有任何文件被写入，安装未完成。' 'Red'
    if ($missing.Count -gt 0 -and $failed.Count -eq 0) {
        Say '    原因是修复包不完整，请重新完整解压一次。' 'Yellow'
    } else {
        Say '    请关闭本程序，右键"以管理员身份运行"再试。' 'Yellow'
    }
    Read-Host '按回车退出'
    exit 1
}

# ---------- 4. 收尾提示 ----------
Say '===============================================' 'Cyan'
Say '  安装完成' 'Green'
Say '===============================================' 'Cyan'
Say ''
Say '接下来：' 'White'
Say '  1. 完全关闭 Steam（托盘图标也要退出）' 'White'
Say '  2. 重新打开 Steam，从库里点 GTA4 开始游戏' 'White'
Say ''
Say '分辨率 / 全屏请在游戏内调整：' 'White'
Say '  Settings(设置) -> Graphics(图形) -> 选分辨率 / 勾选 Fullscreen' 'White'
Say '  (不要改 commandline.txt 里的 -width/-height，实测不生效)' 'DarkGray'
Say ''
Say '如果还是进不去，或想换用备用方案：' 'White'
Say '  把本包"备用_dgVoodoo方案"文件夹里的 d3d9.dll 复制到游戏根目录覆盖' 'White'
Say '  (dgVoodoo.conf 和 dgVoodooCpl.exe 也一起复制过去)' 'DarkGray'
Say ''
Say '完整说明请看本包里的"安装说明.txt"和 README.md。' 'DarkGray'
Say ''
Read-Host '按回车退出'
