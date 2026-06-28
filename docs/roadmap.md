# 后续 Roadmap

按需查阅：规划下一步工作 / 评估工作量时看本文件。

AGENTS.md 主文件只列了简版速查，这里是详细描述 + 状态。

---

## 当前状态

v2 重构完成：6 层视差栈（Atmosphere / Background / Weather / Character / HUD / Notification / System）全部接入 `LayeredScaffold`。
- HUD、Notification、Debug 已可见可用
- Atmosphere 色温覆盖 + 暗角已生效
- Weather 占位（未接真实天气）

---

## Step 3：完整 HUD

**目标**：除顶部时间 HH:MM 外，加更多世界内信息。

**候选**：电量百分比 / Wi-Fi 信号 / 未读通知数 / 番茄钟倒计时 / 当前天气图标。

**层级**：L3 HUD（注意与 L4 Notification 区分——HUD 是常驻信息，Notification 是临时提醒）。

---

## Step 4：键盘快捷键

**目标**：数字 1-4 触发对应级别通知，T 切换主题。

**优先级**：低（Debug 面板已能触发所有级别通知）。

---

## Step 5：接入真实通知源

**目标**：从外部系统（飞书 / 系统通知 / API）拉取真实通知，调 `notificationQueueProvider.enqueue(...)`。

**可能依赖**：`flutter_local_notifications`（系统级通知）—— 需在 `pubspec.yaml` 提前声明。

---

## Step 6：L4 强告警的 `BackdropFilter` 灰度模糊 ✅

**状态**：已完成。`LayeredScaffold` 改 `ConsumerWidget`，监听 `backgroundDimProvider`：
- true 时在 L-1 Atmosphere 之上、L4 Notification 之下叠加 `_DimOverlay`
- `_DimOverlay` 用 `ColorFiltered`（ITU-R BT.709 luminance 灰度矩阵）+
  `BackdropFilter`（高斯模糊 sigma=4） + 40% 黑色叠层
- 嵌套顺序：外→内 `IgnorePointer` → `ColorFiltered` → `BackdropFilter` → `DecoratedBox`
- L4 Notification 文字和 L5 DebugPanel 不被覆盖，保持清晰彩色
- `Severity4PauseAlert` 的 35% 半透明黑叠层保留，与 _DimOverlay 叠加形成"凝固"感

**验证**：
- widget_test + interaction_test 11/11 通过
- 真机截图（hardcode provider=true）确认天空/Mario/地面/云全部灰度+模糊+暗化

**实现要点**：
- L0 子树是 `ScrollingWorld`，需要在 `LayeredScaffold` 中判断 `backgroundDimProvider` 并条件性包一层 `BackdropFilter`
- 注意 L-1 `AtmosphericLayer` 的色温覆盖也应该被灰度模糊（避免灰度时反而色彩鲜艳）

---

## Step 7：L1 WeatherLayer 接入 weatherProvider ✅（sprite cue 阶段）

**目标**：在 `WeatherLayer` 监听新 `weatherProvider`（雨/雪/雾/闪电/沙尘等状态），按状态派发对应 weather widget。

**架构预留**：6 层架构中的 L1 Weather 就是为这步预留的。

**当前状态**：已接入 `weatherProvider`，并用现有真实 SMB raster sprite 做
clear/rain/snow/fog/storm 的天气提示物件：
- clear：starman + coin，表达晴天亮感
- rain：云朵组，配合 Atmosphere 雨天色温
- snow：云朵 + starman 小颗粒，表达冷亮雪感
- fog：多层低透明云朵，表达雾气遮挡
- storm：云朵 + question block + coin，表达带电风暴

**素材规则**：雨滴、雪花、雾层、闪电等粒子/片层必须来自真实 raster 素材，禁止用 `CustomPainter`、几何图形或 SVG 临时绘制。缺素材时只允许通过 `worldStateLoopProvider` 驱动 Atmosphere 色温/暗角、现有真实 sprite 道具和 HUD 文案形成闭环。

**单 widget 内可分子层**：真实素材入库后，RainWidget 内部可同时有"远景雨"（在 L0 之上、L2 之下）和"近景雨滴"（在 L2 之上、L3 之下），通过 widget 内部 `Stack` + 透明度实现。

**可能依赖**：无。先复用现有 Flutter 动画能力移动真实 raster 素材，不新增依赖。

---

## 优先级建议

按"投入产出比"排序：

1. **Step 7 Weather**（用户问过，提前规划层级就是为这步）—— 投入中等，产出高，让摆件活起来。
2. **Step 6 BackdropFilter**（修已知 bug）—— ✅ 已完成。
3. **Step 3 HUD 完整化** —— 投入低，产出中，加点常驻信息。
4. **Step 4 快捷键** —— 投入低，产出低，Debug 面板已能用。
5. **Step 5 真实通知** —— 投入高，产出未知，取决于真实通知源接入复杂度。
