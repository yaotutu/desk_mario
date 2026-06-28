# Sprite 资源清单

按需查阅：替换 sprite / 调整图片规格 / 排查 sprite 显示问题时看本文件。

---

## 来源

所有 sprite 来自 sprite-resource SMB1 NES Overworld，全部走 `assets/`。

---

## 资源清单

| 路径 | 用途 | 原始尺寸 | 显示尺寸 | 备注 |
|------|------|---------|---------|------|
| `assets/backgrounds/smb_background_overworld.png` | Layer 0 远景 panel 1（处理过的）| NES 原版 panel | 屏宽适配（panelWidth = panelHeight × 4.364） | 经 `tools/process_panel1.py` 处理：顶部 32px 紫横条替换为棋盘格天空 |
| `assets/sprites/ground_tile.png` | Layer 0 地面砖块 | 32×32 NES 原版 | tileWidth = panelWidth / 32（整数比）| 从 World 1-1 sheet y=208..240/x=0..32 切出 |
| `assets/sprites/mario_big_run_f{0,1,2}.png` | Mario 跑步 3 帧 | 16×32 NES 原版 | 64×128（scale=4）| frame interval 120ms |
| `assets/sprites/mario_big_stand.png` | Mario 站立 | 16×32 NES 原版 | 64×128（scale=4）| 静态摆件用 |
| `assets/sprites/cloud_small.png` | 后续天气/场景云朵素材 | 42×18 | 按需等比放大 | 从 `smb_world_minus1.png` source rect `(56,43,42,18)` 裁出，sheet 天空色转透明 |
| `assets/sprites/flagpole.png` | 后续进度/专注标记 | 24×178 | 按需等比放大 | 从 `smb_world_minus1.png` source rect `(2427,30,24,178)` 裁出，sheet 天空色转透明 |
| `assets/sprites/castle.png` | 后续长期状态/终点物件 | 86×178 | 按需等比放大 | 从 `smb_world_minus1.png` source rect `(2520,30,86,178)` 裁出，sheet 天空色转透明 |
| `assets/fonts/PressStart2P-Regular.ttf` | 像素字体（family: `PixelFont`）| — | — | HUD 时间、PAUSE 等英文/数字 |

---

## 替换指引

### 替换 Mario 变身状态

只需改 `MarioWidget._runFrames` / `_standFrame` 数组指向新 PNG：

```dart
// 例如换成小 Mario（small mario）
static const _runFrames = [
  'assets/sprites/mario_small_run_f0.png',
  'assets/sprites/mario_small_run_f1.png',
  'assets/sprites/mario_small_run_f2.png',
];

static const _standFrame = 'assets/sprites/mario_small_stand.png';
```

### 处理 panel 1（替换紫横条为棋盘格天空）

```bash
python3 tools/process_panel1.py <in.png> <out.png>
# 默认处理 assets/backgrounds/smb_background_overworld.png
```

### 从 stage sheet 裁出真实物件素材

```bash
python3 tools/extract_stage_sprites.py
```

当前裁出的 `cloud_small.png` / `flagpole.png` / `castle.png` 均来自
`assets/backgrounds/smb_world_minus1.png`。脚本只做矩形裁剪 + exact sheet
天空色 alpha 透明化，不重绘 sprite 像素。

---

## 重要约束

**所有 `Image.asset` 必须设 `filterQuality: FilterQuality.none`**（避免像素被抗锯齿模糊掉），平移动画设 `gaplessPlayback: true`（防止背景切换时短暂黑屏）。

代码搜索关键字：`Image.asset` —— 任何新增 sprite 使用点都要符合上述约束。
