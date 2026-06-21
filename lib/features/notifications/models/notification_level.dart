/// 消息提醒级别（4 级弱提醒）
///
/// 从弱到强：
/// - [level1] 极弱：右上角小图标呼吸闪烁
/// - [level2] 低侵入：顶部木牌向下弹出
/// - [level3] 中等侵入：底部对话框升起 + 打字机
/// - [level4] 强告警：底层灰度模糊 + 中央 PAUSE
enum NotificationLevel {
  level1,
  level2,
  level3,
  level4;

  /// Mock 演出文本默认值（中文）
  static const Map<NotificationLevel, String> defaultText = {
    level1: '提示',
    level2: '前方有新发现，请注意查看！',
    level3: '欢迎来到蘑菇王国！我是你的向导，有什么需要尽管告诉我。',
    level4: '紧急告警',
  };
}
