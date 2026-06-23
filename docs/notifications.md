# 消息通知系统（Layer 4）

按需查阅：调整 4 级消息行为 / 新增消息级别 / 修通知 bug 时看本文件。

---

## 4 级弱提醒 + 串行队列

**同时只显示一条**，演完才出队下一条。`NotificationOverlay` 监听 `notificationQueueProvider.current`，按 level 派发对应 widget。

| Level | 组件 | 行为 |
|-------|------|------|
| L1 | `Level1FadeIcon` | 右上角图标 5s 呼吸闪烁（首尾各 10% 淡入淡出）|
| L2 | `Level2SignBanner` | 顶部木牌 AnimatedContainer 弹出，停留 10s 后收回 |
| L3 | `Level3TypewriterDialog` | 底部对话框升起 + `TypewriterText` 50ms/字，打完停留 5s 淡出 |
| L4 | `Level4PauseAlert` | 全屏 PAUSE 闪烁 + 解除告警按钮，**触发 backgroundDimProvider 让 L0 变灰度+模糊** |

Mock 文本在 `NotificationLevel.defaultText`（中文）。每个 widget 演完调 `ref.read(notificationQueueProvider.notifier).completeCurrent()`。

`NotificationOverlay` 的 `key` 用消息 `id`（fallback `level.index`），确保每条消息切换时 widget 重新创建、动画重新播放。

---

## L4 灰度模糊的实现

`Level4PauseAlert.initState` 在 postFrameCallback 里把 `backgroundDimProvider` 置 `true`。

**Roadmap Step 6**：在 `LayeredScaffold` 监听该 provider，用 `ColorFiltered`（灰度）+ `BackdropFilter`（模糊）包裹 L0 子树。

**当前状态**：provider 已被使用但 `BackdropFilter` 还没接到 `LayeredScaffold`，L4 触发后视觉上无灰度模糊（当前只有半透明遮罩）。详见 [roadmap.md](roadmap.md)。

---

## 触发通知的方式

- **Debug 面板**（开发态）：右下角齿轮 → Test L1/L2/L3/L4 按钮
- **键盘快捷键**（Roadmap Step 4）：数字 1-4 触发对应级别
- **真实通知源**（Roadmap Step 5）：接入外部通知后调用 `notificationQueueProvider.enqueue(...)`

---

## 已知陷阱（通知相关）

- `Level3TypewriterDialog._onTyped` 用 `Future.delayed` 模拟停留 5s，销毁时未取消——如果在动画中 dispose widget 会触发 mounted 检查；现有测试通过 mounted 守卫已规避。
- 不要新增未在 `pubspec.yaml` 声明的依赖，CI 会因版本不匹配失败（这是通用规则，但通知系统最容易引入新插件如 `flutter_local_notifications`，需特别注意）。