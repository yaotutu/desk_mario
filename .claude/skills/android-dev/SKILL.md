---
name: android-dev
description: Android 设备视觉验证工具集（adb 封装 + 截图 + logcat + 交互 + 重启）。用于 Flutter / Android 应用开发中的高频视觉反馈回路：截屏 → 读图 → 分析 → 修复。当需要 adb 截图、看 Flutter logcat、点击/滑动设备、重启应用、安装 APK、或调试安卓设备的运行时状态时使用。
---

# Android Dev

DeskMario / Flutter Android 开发的视觉验证工具。把零散的 adb 命令封装成统一入口 `scripts/adb.sh`，覆盖开发期间最高频的 10 个操作。

## 快速开始

默认设备已经写死 YT3002（serial `1W11833968`），直接调用即可：

```bash
SCRIPT=.claude/skills/android-dev/scripts/adb.sh

# 截图（最常用）— 默认保存到 /tmp/adb_screen_<ts>.png，stdout 输出路径
$SCRIPT screenshot

# 截到指定路径 + Claude 用 Read 工具读取 + 分析
$SCRIPT screenshot /tmp/check.png
# 然后 Read /tmp/check.png

# 看 Flutter logcat
$SCRIPT logcat

# 重启 DeskMario（force-stop + start + 等首帧）
$SCRIPT restart

# 设备 / 前台应用概览
$SCRIPT info

# 点右下角（Debug 齿轮应在的位置，屏幕 1280x800）
$SCRIPT tap 1200 760
```

完整子命令列表见 `scripts/adb.sh help`。

## 典型工作流

**修复一个 UI bug：**
```
1. $SCRIPT screenshot /tmp/before.png    # 截当前
2. Read /tmp/before.png                  # 看
3. ...改 lib/ 代码...
4. $SCRIPT restart                       # 重启应用（hot restart 之外的完全重启）
5. sleep 3                               # 给 Flutter 时间渲染
6. $SCRIPT screenshot /tmp/after.png     # 截新
7. Read /tmp/after.png                   # 对比
```

**遇到崩溃：**
```
1. $SCRIPT restart &                     # 后台重启
2. $SCRIPT logcat                        # 跟 Flutter 错误日志
3. # Ctrl+C 退出后看完整 stack trace
```

**多点验证（Debug Panel 4 级通知）：**
```
$SCRIPT tap 1200 760                     # 展开 Debug Panel
$SCRIPT screenshot /tmp/expanded.png     # 看面板是否展开
$SCRIPT tap <x> <y>                      # 点 "Test L3"（坐标看截图）
sleep 2                                  # 等打字机动画
$SCRIPT screenshot /tmp/l3.png           # 看对话框
```

## 子命令清单

| 子命令 | 用途 |
|--------|------|
| `screenshot [out.png]` | 截图，默认 `/tmp/adb_screen_<ts>.png`（带大小校验，<1KB 视为失败） |
| `logcat [--tag TAG] [--once]` | 看 logcat，默认 `flutter:* -v color`，自动清空 buffer |
| `restart` | force-stop + start + 等启动窗消失 + Flutter 保险 sleep 2s |
| `tap x y` | 点击屏幕坐标 |
| `swipe x1 y1 x2 y2 [ms]` | 滑动，默认 300ms |
| `text "..."` | 输入文字（空格自动转 %s） |
| `keyevent <code\|name>` | 按键（HOME / BACK / KEYCODE_*） |
| `install <apk> [-r] [-t]` | 安装/替换 APK |
| `focus` | 当前前台 Activity（dumpsys window） |
| `info` | 设备 + 当前应用 + 配置覆盖概览 |
| `help` | 显示帮助 |

全局参数（必须放在子命令前）：`--serial <serial>`、`--pkg <package>` 覆盖默认值。

## 重要细节（避免踩坑）

1. **`restart` 后的 2s 保险 sleep**：am start 是异步的，Activity `RESUMED` ≠ Flutter 已渲染第一帧。所以脚本在检测到 starting window 消失后多 sleep 2 秒，确保 `screenshot` 拿到的是有效帧。

2. **截图大小校验**：`screenshot` 输出若 < 1024 bytes 视为失败（设备锁屏/异常帧），返回非零退出码。

3. **logcat 自动清 buffer**：每次 `logcat` 启动时 `-c` 清空，避免看到上次会话的旧日志。

4. **设备坐标**：YT3002 物理 800x1280（竖屏），DeskMario 强制横屏后 Flutter 内部旋转 90°，所以"屏幕右上角"对应物理坐标 ≈ (1200, 760)，不是 (700, 100)。

5. **shell 转义**：`text` 子命令中空格已自动转 `%s`，但其他含特殊字符的参数建议先 echo 验证后再传给 `adb shell input`。

6. **panel 1 滚动可见性陷阱**：DeskMario 的 Layer 1 山脉 panel 1 是循环滚动（60s/周期），单张截图可能落在 panel 1 完全滚出屏幕的瞬间（背景只有 skyBottom 纯色）— 不要据此误判 panel 1 缺失。多截几次确认。

## 自定义配置

环境变量覆盖默认值（适用于切换调试设备/包名）：

```bash
DESK_MARIO_SERIAL=192.168.1.100:5555 \
DESK_MARIO_PKG=com.example.other_app \
$SCRIPT info
```

或单次调用：

```bash
$SCRIPT --serial 192.168.1.100:5555 --pkg com.other.app screenshot
```

## Resources

### scripts/adb.sh

统一入口脚本，~240 行 Bash。覆盖 10 个高频子命令 + 全局参数覆盖 + 大小校验 + 自动 buffer 管理。无外部依赖（仅需 `adb`）。