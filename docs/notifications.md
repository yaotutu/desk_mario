# 消息通知系统（Layer 4）

按需查阅：调整 4 级消息行为 / 新增消息级别 / 修通知 bug 时看本文件。

---

## 4 级弱提醒 + 串行队列

**同时只显示一条**，演完才出队下一条。`NotificationOverlay` 监听 `notificationQueueProvider.current`，按 severity 派发对应 widget。

| Severity | 组件 | 行为 |
|----------|------|------|
| severity1 | `Severity1FadeIcon` | 右上角图标 5s 呼吸闪烁（首尾各 10% 淡入淡出）|
| severity2 | `Severity2SignBanner` | 顶部木牌 AnimatedContainer 弹出，停留 10s 后收回 |
| severity3 | `Severity3TypewriterDialog` | 底部对话框升起 + `TypewriterText` 50ms/字，打完停留 5s 淡出 |
| severity4 | `Severity4PauseAlert` | 全屏 PAUSE 闪烁 + 解除告警按钮，**触发 backgroundDimProvider 让 L0 变灰度+模糊** |

Mock 文本在 `NotificationSeverity.defaultText`（中文）。每个 widget 演完调 `ref.read(notificationQueueProvider.notifier).completeCurrent()`（widget 内部自己调，调用方不需要传 `onComplete` 回调）。

`NotificationOverlay` 的 `key` 用消息 `id`（fallback `severity.index`），确保每条消息切换时 widget 重新创建、动画重新播放。

> **命名约定**：用 `Severity` 而非 `Level`，避免和 6 层视差栈的层号（L0~L5 / L-1）混淆。`Severity 4` 渲染在 L4 层，但层号 L4 和严重度 Severity 4 是两码事。

---

## L4 灰度模糊的实现

`Severity4PauseAlert.initState` 在 postFrameCallback 里把 `backgroundDimProvider` 置 `true`。

**实现（Step 6 ✅）**：[`LayeredScaffold`](../../lib/shared/widgets/layered_scaffold.dart) 监听 `backgroundDimProvider`，true 时在 L-1 Atmosphere 之上、L4 Notification 之下叠加 `_DimOverlay`：
- `ColorFiltered` 用 ITU-R BT.709 luminance 矩阵（0.2126, 0.7152, 0.0722）做去色
- `BackdropFilter` 高斯模糊 sigma=4
- `DecoratedBox` 叠 40% 黑色（`Color(0x66000000)`）强化"凝固"感
- 嵌套顺序（外→内）：`IgnorePointer` → `ColorFiltered` → `BackdropFilter` → `DecoratedBox`
- L4 Notification 文字和 L5 DebugPanel 不被覆盖，保持清晰彩色
- `Severity4PauseAlert` 自带的 35% 半透明黑叠层保留，与 `_DimOverlay` 叠加形成"凝固"感

**关键约定**：`BackdropFilter` 模糊的是"它下方的画面"，所以 `_DimOverlay` 必须**叠加**在 L0~L3 + L-1 之上，而不是包裹它们（包裹的话是模糊子项，不生效）。

---

## 触发通知的方式

- **Debug 面板**（开发态）：右下角齿轮 → Test L1/L2/L3/L4 按钮
- **键盘快捷键**（Roadmap Step 4）：数字 1-4 触发对应级别
- **真实通知源**（Roadmap Step 5）：接入外部通知后调用 `notificationQueueProvider.enqueue(...)`

---

## 已知陷阱（通知相关）

- `Severity3TypewriterDialog._onTyped` 用 `Future.delayed` 模拟停留 5s，销毁时未取消——如果在动画中 dispose widget 会触发 mounted 检查；现有测试通过 mounted 守卫已规避。
- 不要新增未在 `pubspec.yaml` 声明的依赖，CI 会因版本不匹配失败（这是通用规则，但通知系统最容易引入新插件如 `flutter_local_notifications`，需特别注意）。