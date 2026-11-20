$ErrorActionPreference = 'Stop'

# ============================================================
#  GTA4 修复包 —— 卸载脚本（还原到安装前状态）
#  双击"卸载修复.bat"运行。
# ============================================================

$src = $PSScriptRoot
if (-not $src) { $src = (Get-Location).Path }

function Say($msg, $color = 'Gray') { Write-Host $msg -ForegroundColor $color }

function Find-GameDir {
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
            foreach ($m in [regex]::Matches($content, '"path"\s+"([^"]+)"')) { $libRoots += $m.Groups[1].Value }
        }
    }
    $libRoots = $libRoots | Select-Object -Unique
    $rel = 'steamapps\common\Grand Theft Auto IV\GTAIV'
    foreach ($l in $libRoots) {
        $cand = Join-Path $l $rel
        if (Test-Path (Join-Path $cand 'GTAIV.exe')) { return $cand }
    }
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
Say '  GTA4 修复包 —— 卸载 / 还原' 'Cyan'
Say '===============================================' 'Cyan'
Say ''

$game = Find-GameDir
if (-not $game) {
    Say '[X] 没能自动找到 GTA4 安装目录。' 'Yellow'
    Write-Host -NoNewline '> 请粘贴游戏根目录路径: ' -ForegroundColor Cyan
    $manual = (Read-Host).Trim().Trim('"')
    if ($manual -and (Test-Path (Join-Path $manual 'GTAIV.exe'))) { $game = $manual }
}
if (-not $game) {
    Say '[X] 路径无效，已取消。' 'Red'
    Read-Host '按回车退出'; exit 1
}
Say "[OK] 游戏目录: $game" 'Green'
Say ''

$baks = Get-ChildItem -Path $game -Directory -Filter '_backup_before_fix_*' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending
if (-not $baks) {
    Say '[--] 没有找到本修复包创建的备份目录。' 'DarkGray'
    Say '     可以手动删除游戏根目录下的: d3d9.dll、dinput8.dll、plugins 文件夹、commandline.txt' 'Yellow'
    Read-Host '按回车退出'; exit 0
}

$bak = $baks[0]
Say "找到备份: $($bak.Name)" 'Green'
Say ''
$ans = Read-Host "确认要还原到该备份状态吗? 现有的修复文件会被覆盖 (输入 Y 确认)"
if ($ans -notmatch '^[Yy]') {
    Say '已取消，未改动任何文件。' 'Yellow'
    Read-Host '按回车退出'; exit 0
}

$ok = 0
foreach ($it in @('d3d9.dll', 'dinput8.dll', 'commandline.txt', 'plugins', 'dxgi.dll', 'd3d9.cfg')) {
    $b = Join-Path $bak.FullName $it
    if (Test-Path $b) {
        try {
            Copy-Item $b (Join-Path $game $it) -Recurse -Force -ErrorAction Stop
            Say "[OK] 已还原: $it" 'Green'
            $ok++
        } catch { Say "[X] 还原失败: $it" 'Red' }
    }
}
Say ''
Say "还原完成，共 $ok 个文件。备份目录保留在: $($bak.FullName)" 'Green'
Say '（确认游戏正常后，可以自行删除该备份目录）' 'DarkGray'
Say ''
Read-Host '按回车退出'
