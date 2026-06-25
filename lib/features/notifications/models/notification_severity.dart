/// 消息提醒严重度（4 级弱提醒）
///
/// 从弱到强：
/// - [severity1] 极弱：右上角小图标呼吸闪烁
/// - [severity2] 低侵入：顶部木牌向下弹出
/// - [severity3] 中等侵入：底部对话框升起 + 打字机
/// - [severity4] 强告警：底层灰度模糊 + 中央 PAUSE
///
/// 命名约定：用 "severity" 而非 "level"，避免和 6 层视差栈的层号
/// （L0~L5 / L-1）混淆。详见 [docs/design-principles.md](https://github.com)。
enum NotificationSeverity {
  severity1,
  severity2,
  severity3,
  severity4;

  /// Mock 演出文本默认值（中文）
  static const Map<NotificationSeverity, String> defaultText = {
    severity1: '提示',
    severity2: '前方有新发现，请注意查看！',
    severity3: '欢迎来到蘑菇王国！我是你的向导，有什么需要尽管告诉我。',
    severity4: '紧急告警',
  };
}
