# 设计原则 / 约定 / 完整陷阱清单

按需查阅：写新 widget / 审查 PR / 排查诡异 bug 时看本文件。

---

## 设计原则 / 约定

1. **详细中文注释**：每个 widget 顶部 dartdoc 写清楚"为什么这样做"（不仅是"做什么"），便于后续维护。

2. **InheritedWidget 而非 Provider 传滚动指标**：因为 `progress` 每帧变化，频繁触发 widget rebuild，InheritedWidget 比 Provider 监听开销小。参考 `ScrollingMetrics`。

3. **`Stack + Positioned` 而非 `Row`** 铺水平 tile：背景 panel 拼接后总宽 ≈ 2×panelWidth，地面 34×tileWidth 都远超 totalWidth，Row 会触发 RenderFlex overflow assertion；Stack 子项超出后被外层 `ClipRect` 裁掉，不报错。

4. **整数比绑死 `tileWidth = panelWidth / tilesPerPanel`**：避免 float 除法 + `floor()` 导致的像素不对齐抖动。
   - 三个绑死的常量：`GroundLayer.tilesPerPanel = 32`、`GroundRatio = 0.12`、`ParallaxBackground.imageAspect = 768/176`
   - 通过 `((1 - 0.12) × 4.364) / 0.12 = 32` 精确整数比绑定
   - **改其中任何一个必须同步改另外两个**

5. **测试不能用 `pumpAndSettle`**：视差 + Mario 浮动都是无限动画，`pumpAndSettle` 永远不返回。统一用 `pump(Duration)` 推进固定帧数。

6. **Widget 复用**：`TypewriterText` 是通用打字机，未来 Severity 3 之外也可以直接复用。

7. **层级单一职责**：6 层架构中每层只看名字就知道放什么，可扩展点遵循"按视觉深度 + 按职责语义"分层：
   - 角色血条 → L3 HUD
   - Boss 战敌人 → L2 Character
   - 屏幕飘雪 → L1 Weather（widget 内分远景/近景）
   - 设置弹窗 → L5 System

---

## 完整陷阱清单（详细版）

> AGENTS.md 的"已知陷阱"是简版速查，这里是带原因和解决方向的完整版。

### 1. `AtmosphericLayer` Z-order 反直觉

**陷阱**：把它放在 `LayeredScaffold` 的 `Stack.children[0]`（最底）会被 L0~L4 不透明 sprite 完全遮住，冷蓝色覆盖失效。

**原因**：Flutter `Stack` 渲染顺序是 children[0] → children[N-1]，底层被上层覆盖。

**解决**：`LayeredScaffold` 实际 children 顺序是 `L0 → L1 → L2 → L3 → L4 → [L-1 Atmosphere] → L5 DebugPanel`。Atmosphere 语义层号是 L-1（最底），但渲染 Z-order 在 L4 之后；通过 `IgnorePointer` 不影响 L5 DebugPanel 点击。

**修改建议**：任何调整层级顺序前，先看 [architecture.md 中 6 层视差栈章节](../AGENTS.md#架构核心6-层视差栈v2--方案-a) 的反直觉说明。

### 2. ✅ 已修复：L4 强告警的 `BackdropFilter` 必须接到 `LayeredScaffold`（Step 6）

**历史**：旧版 `Severity4PauseAlert` 触发后只叠了半透明黑遮罩，没有灰度+模糊，看起来"告警感"不够。Step 6 已把 `BackdropFilter` + `ColorFiltered` 接到 `LayeredScaffold`（commit `f5adc99`），L4 触发时 L0~L3 + L-1 全灰度+模糊+暗化。

**实现位置**：[`lib/shared/widgets/layered_scaffold.dart`](../../lib/shared/widgets/layered_scaffold.dart) 的 `_DimOverlay`（嵌套顺序：`IgnorePointer` → `ColorFiltered` → `BackdropFilter` → `DecoratedBox`），仅在 `backgroundDimProvider` 为 true 时挂载。

**反向提醒（别回退）**：
- `_DimOverlay` 位置必须在 L-1 Atmosphere 之上、L4 Notification 之下——挪到 Notification 之上会让 PAUSE 文字也被模糊掉。
- 模糊的是"它下方的画面"，所以必须**叠加**而不是**包裹**L0~L3 子树。
- L-1 Atmosphere 的色温必须一起被灰度模糊（避免灰度时反而色彩鲜艳）。

### 3. `Severity3TypewriterDialog._onTyped` 用 `Future.delayed`

**陷阱**：模拟停留 5s 时用 `Future.delayed`，销毁时未取消。

**后果**：如果动画中被 dispose 会触发 mounted 检查报错。

**现状**：现有测试通过 mounted 守卫已规避。

### 4. 测试不能用 `pumpAndSettle`

**陷阱**：视差 + Mario 浮动都是无限动画，`pumpAndSettle` 永远不返回。

**正确做法**：用 `pump(Duration(milliseconds: N))` 推进固定帧数。

### 5. 调试面板 Switch 坐标

**陷阱**：Debug 面板右下角，Switch 位置不直观。

**正确位置**：横屏 1280×800 逻辑坐标下，齿轮中心约 (1236, 756)，Switch 中心约 (1234, 760)，`$SCRIPT tap` 用这些坐标。

### 6. 依赖限制

**陷阱**：不要新增未在 `pubspec.yaml` 声明的依赖。

**后果**：CI 会因版本不匹配失败。