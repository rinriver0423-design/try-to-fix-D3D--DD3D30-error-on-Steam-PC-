# GTA4 DD3D30 / D3D Error 修复包

修复 **Grand Theft Auto IV: The Complete Edition**（Steam，appid `12210`）启动时报
`D3D Error` / `GTA IV FATAL ERROR: DD3D30` 无法启动的问题。

把本仓库的文件复制到游戏根目录（`GTAIV.exe` 所在目录）即可，不改任何系统文件。

---

## ⬇️ 下载

**Releases → v1.1.0 → `GTA4_D3D9_Fix_v1.1.zip`**（19 MB，带一键安装脚本，推荐）

直接下载：
<https://github.com/rinriver0423-design/try-to-fix-D3D--DD3D30-error-on-Steam-PC-/releases/download/v1.1.0/GTA4_D3D9_Fix_v1.1.zip>

不想用 zip 的话，也可以直接从仓库下载单个文件（本页右侧 **Code → Download ZIP**）。

## 🚀 一键安装（v1.1.0 起）

解压后**双击 `一键安装.bat`** 即可，不需要手动找文件：

1. 下载 zip 并解压到任意位置
2. 双击 `一键安装.bat`（黑色命令行窗口是正常的，不是病毒）
3. 它会自动找到 GTA4 安装目录 → 备份原文件 → 写入修复文件
4. 完全退出 Steam（托盘图标也要退出），重新打开 Steam 开始游戏

找不到游戏目录时，脚本会让你手动粘贴路径
（Steam 里右键游戏 → 管理 → 浏览本地文件 可直接打开该目录）。

想还原就双击 `卸载修复.bat`。

## 📁 手动安装

把 `d3d9.dll`、`dinput8.dll`、`plugins` 文件夹、`commandline.txt`
复制到游戏根目录（`GTAIV.exe` 所在那层）即可。
---

## 症状

- 从 Steam 点「开始游戏」，弹出 `D3D Error` 或 `GTA IV FATAL ERROR: DD3D30`，进不去。
- 或者能启动，但画面异常：黑屏、只有主屏左上角一小块窗口、分辨率不对。

## 病因

**不是**游戏文件损坏，**不是**显卡坏了，**不是** mod 的锅。

问题出在 Windows 的 **32 位 Direct3D 9 通路**与显示驱动握手这一层：

| 现象 | 实测结果 |
|---|---|
| `Direct3DCreate9()` | 成功 |
| `AdapterCount` | 2（核显 + 独显都在） |
| `GetAdapterIdentifier()` | 全部返回 `D3DERR_INVALIDCALL (0x8876086C)` |
| `GetAdapterModeCount()` | 全部返回 **0 个模式** |
| `CreateDevice()` | `INVALIDCALL`，或在 `d3d9.dll` 内访问冲突崩溃 |

64 位 D3D9 完全正常，只有 32 位这一路坏了。系统自带的 `d3d9.dll` 文件本身是完整的
（1,550,976 B，10.0.26100.9818），用 WinSxS 里的旧版本覆盖也无效 —— 坏的是它跟驱动
的适配器握手，不是文件。

彻底根治需要管理员权限（关 HAGS / 回滚或重装显卡驱动），不适合做成分发包。
所以本包走 **转译层** 绕过：

- **DXVK** —— 把游戏的 D3D9 调用转译成 **Vulkan**，原生走显卡，效果最好；
- **dgVoodoo2** —— 转译成 **D3D11**，对驱动更保守，成功率不低，特效略逊。

---

## 安装

### 1. 关闭游戏

完全退出 Steam，并确认任务管理器里没有 `GTAIV.exe` / `PlayGTAIV.exe`。

### 2. 复制文件

把下面这些复制到 **游戏根目录**（`GTAIV.exe` 所在的那层）：

```
d3d9.dll
dinput8.dll
plugins\                 ← 整个文件夹一起复制
commandline.txt          ← 可选，见下
```

Steam 版默认路径一般是：

```
...\SteamLibrary\steamapps\common\Grand Theft Auto IV\GTAIV\
```

在 Steam 里右键游戏 → **管理** → **浏览本地文件** 可以直接打开这个目录。

### 3. 启动

Steam → GTA4 → 播放。

> 如果点了没反应、或者弹出 Rockstar 登录框自己关掉：
> 先用 Steam 客户端打开一次（让 RGL 完成登录），再从 Steam 点游戏；
> 或者直接运行游戏目录里的 `PlayGTAIV.exe`。

---

## 分辨率 / 全屏

**不要在 `commandline.txt` 里改 `-width` / `-height`** —— 实测在 GTA4 上不生效
（`-width=1280 -height=720` 和 `-width=1024 -height=768` 两种写法都仍然落到 800×600），
FusionFix 的 `Windowed = 1` 也会强制窗口化。

正确做法是**进游戏以后**在菜单里改：

```
Settings（设置） → Graphics（图形） → 选分辨率 / 勾选 Fullscreen
```

游戏退出时会把设置写进：

```
文档\Rockstar Games\GTA IV\Settings\SETTINGS.CFG
```

这样就是持久的。注意：**游戏运行期间 `SETTINGS.CFG` 是不存在的**，只有退出后才写出来，
这是正常现象，不是出错。

---

## 文件说明

| 文件 | 说明 |
|---|---|
| `d3d9.dll` | **DXVK 3.1.1 (32 位)** —— 核心，把 D3D9 转译成 Vulkan |
| `dinput8.dll` | **ASI Loader** —— FusionFix 的加载器，必须与 `plugins` 配套 |
| `plugins/GTAIV.EFLC.FusionFix.asi` | **FusionFix v5.1.2**，游戏修复 mod（帧率、阴影、雾等） |
| `plugins/GTAIV.EFLC.FusionFix.ini` | FusionFix 详细设置，可调各项开关 |
| `plugins/GTAIV.EFLC.FusionFix.cfg` | FusionFix 运行状态（游戏退出时会自行改写，属正常） |
| `commandline.txt` | 启动参数，可选。只保留 `-norestructions -nomemrestrict` |
| `备用_dgVoodoo方案/` | 备选转译层，见下 |

`commandline.txt` 是可选的，删掉游戏照常能启动。它只是去掉了 GTA4 的一些人为限制
（不能切窗口、内存上限等），对老机器有好处。**不要**往里加 `-windowed`，否则会盖掉
你在游戏里选的全屏。

---

## DXVK 起不来？换 dgVoodoo2

有人装新版显卡驱动后 DXVK 反而起不来，或者 DXVK 下有别的怪问题。那就换备用方案：

1. 把 `备用_dgVoodoo方案\d3d9.dll` 复制到游戏根目录，覆盖同名文件
   （根目录的 `d3d9.dll` 换成 dgVoodoo2 那个，DXVK 的先备份走）；
2. `dgVoodoo.conf` 和 `dgVoodooCpl.exe` 也复制到游戏根目录；
3. `dinput8.dll` 和 `plugins\` 保持不变（FusionFix 照常加载）。

> FusionFix 自带的 d3d9.dll wrapper 在本包里被移开了（DXVK 占用了 `d3d9.dll` 这个文件名）。
> 如果你原来就在用 FusionFix 的原版 d3d9.dll，请先自行备份。

---

## 三个容易踩的坑

**1. FusionFix 的 `.asi` 绝不能停用。**
停用后会出现 `GTAIV.exe` 进程起来了但 0 内存、无窗口、卡在后台的情况，看起来像游戏卡死。
`.asi` 通过 `dinput8.dll`（ASI Loader）加载，与 DXVK 的 `d3d9.dll` 可以共存。

**2. 根目录只能有一个 `d3d9.dll`。**
同时存在多个同名 dll 会互相打架。装别的 mod 前先确认冲突。

**3. 双显卡机器注意游戏可能跑到核显上。**
在注册表 `HKCU\Software\Microsoft\DirectX\UserGpuPreferences` 里给 `GTAIV.exe` 加
`GpuPreference=2;` 强制用独显。

---

## 怎么确认修好了

任意一条即可：

- 能进主菜单，画面正常；
- 存档文件时间戳更新：
  `文档\Rockstar Games\GTA IV\Profiles\<数字ID>\501C4FD0.dat` / `cloudsavedata.dat`；
- 想看转译日志：给游戏加环境变量 `DXVK_LOG_PATH=<一个空文件夹>`，跑一次后会出现
  `GTAIV_d3d9.log`，里面能确认实际用的是哪张显卡。

---

## 卸载

删掉 `d3d9.dll`、`dinput8.dll`、`plugins` 文件夹、`commandline.txt` 即可，
删干净就回到原样。**全程没有修改任何系统文件。**

---

## 第三方组件与许可

本仓库包含以下第三方组件的**原始发行文件**，未修改任何二进制内容：

| 组件 | 版本 | 许可证 | 主页 |
|---|---|---|---|
| DXVK | 3.1.1 | zlib | https://github.com/doitsujin/dxvk |
| dgVoodoo2 | 2.87.5 | GPL | https://github.com/dege-diosg/dgVoodoo2 |
| FusionFix | 5.1.2 | freeware | https://github.com/SteamGifts/FusionFix |
| ASI Loader | — | zlib | https://github.com/ThirteenAG/ASI-Loader |

dgVoodoo2 为 GPL 授权，其源码可在上表主页获取。各组件版权归原作者所有。
本仓库自身新增的内容为 `README.md`、`安装说明.txt` 等说明文档。

> 提醒：分发这些 mod 前请自行确认各项目的再分发条款，尤其是 FusionFix 与 ASI Loader。
> 本仓库作者仅将官方发行文件原样打包用于解决兼容性问题。

---

## 致谢

感谢 DXVK、dgVoodoo2、FusionFix、ASI Loader 的作者们。没有这些开源项目，
32 位 D3D9 坏掉的老游戏基本没法在现代系统上跑。

祝你玩得开心。如果这个包帮到了别人，也欢迎转发。
