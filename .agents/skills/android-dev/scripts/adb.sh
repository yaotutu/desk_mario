#!/usr/bin/env bash
# android-dev 统一入口
#
# 提供 DeskMario / Flutter Android 开发的视觉验证高频操作。
# 设计目标：减少 agent 在每个 turn 里手写 adb 命令的重复劳动。
#
# 默认值（写死，方便直接调用；其他设备/包可用 --serial / --pkg 覆盖）：
#   DEVICE_SERIAL = HGR496PP      # TB300FU（横屏摆件调试机）
#   APP_PKG       = com.example.desk_mario
#   APP_ACTIVITY  = .MainActivity
#
# 用法：
#   adb.sh screenshot [out.png]              # 截图（默认 /tmp/adb_screen_<ts>.png）
#   adb.sh logcat [--tag TAG] [--follow]     # 看 logcat（默认 flutter:* -v color）
#   adb.sh restart                            # force-stop + start（完全重启）
#   adb.sh tap <x> <y>                       # 点击屏幕坐标
#   adb.sh swipe <x1> <y1> <x2> <y2> [ms]    # 滑动（默认 300ms）
#   adb.sh text <string>                     # 输入文字（空格用 %s）
#   adb.sh keyevent <code|name>              # 按键（HOME / BACK / KEYCODE_*）
#   adb.sh install <apk>                     # 安装/替换 APK（-r 重装，-t 允许 test）
#   adb.sh focus                              # 当前前台 Activity
#   adb.sh info                               # 设备 + 当前应用概览
#   adb.sh help                               # 显示帮助
#
# 全局参数（必须放在子命令前）：
#   --serial <serial>    覆盖设备 serial（默认 ${DEVICE_SERIAL}）
#   --pkg <package>      覆盖包名（默认 ${APP_PKG}）
#
# 退出码：
#   0 成功；1 用户错误（参数/未连接设备）；2 环境错误（adb 不可用）

set -euo pipefail

# === 默认配置（项目级硬编码） =====================================
DEFAULT_SERIAL="${DESK_MARIO_SERIAL:-HGR496PP}"
DEFAULT_PKG="${DESK_MARIO_PKG:-com.example.desk_mario}"
DEFAULT_ACTIVITY="${DESK_MARIO_ACTIVITY:-.MainActivity}"

# === 颜色（仅 stderr，方便区分日志与命令输出） ====================
RED=$'\033[0;31m'; GRN=$'\033[0;32m'; YLW=$'\033[0;33m'; NC=$'\033[0m'
log_err()  { echo "${RED}[adb.sh]${NC} $*" >&2; }
log_ok()   { echo "${GRN}[adb.sh]${NC} $*" >&2; }
log_warn() { echo "${YLW}[adb.sh]${NC} $*" >&2; }

# === 解析全局参数（必须在子命令前） ===============================
SERIAL="${DEFAULT_SERIAL}"
PKG="${DEFAULT_PKG}"
ACTIVITY="${DEFAULT_ACTIVITY}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --serial) SERIAL="$2"; shift 2;;
    --pkg)    PKG="$2"; shift 2;;
    -h|--help|help)
      # help 单独处理：让后面的逻辑直接退出
      SUBCMD="help"; shift; break;;
    *)
      # 第一个非全局参数 → 子命令
      SUBCMD="$1"; shift; break;;
  esac
done

# === 工具函数 ====================================================
die()      { log_err "$*"; exit 1; }
need_adb() { command -v adb >/dev/null || die "adb 命令不可用，请安装 Android Platform Tools"; }

check_device() {
  need_adb
  if ! adb -s "${SERIAL}" get-state >/dev/null 2>&1; then
    log_err "设备 ${SERIAL} 不在线或未授权"
    log_err "可用设备："
    adb devices -l | sed 's/^/    /' >&2
    exit 1
  fi
}

# 转义 adb shell 字符串参数（包裹单引号 + 转义内部单引号）
shell_quote() {
  local s="$1"
  s="${s//\'/\'\\\'\'}"   # ' → '\''
  echo "'${s}'"
}

# === 子命令实现 ==================================================
cmd_screenshot() {
  local out="${1:-}"
  if [[ -z "${out}" ]]; then
    out="/tmp/adb_screen_$(date +%Y%m%d_%H%M%S).png"
  fi

  check_device
  # exec-out 比 exec screencap 更稳（避免 \r\n 转换和 buffer 问题）
  adb -s "${SERIAL}" exec-out screencap -p > "${out}"
  local size
  size=$(stat -f%z "${out}" 2>/dev/null || stat -c%s "${out}")
  if [[ "${size}" -lt 1024 ]]; then
    log_err "截图异常（${size} bytes），可能设备锁屏或返回了错误帧"
    exit 1
  fi
  log_ok "截图已保存：${out} (${size} bytes)"
  echo "${out}"   # stdout 给后续读取/查看图片用
}

cmd_logcat() {
  local tag="flutter:*"
  local follow=true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tag)   tag="$2"; shift 2;;
      --once)  follow=false; shift;;
      *)       die "logcat 不支持参数：$1";;
    esac
  done

  check_device
  # 先清空 buffer，避免看到上次会话的旧日志
  adb -s "${SERIAL}" logcat -c

  if [[ "${follow}" == true ]]; then
    log_ok "开始跟踪 logcat（tag=${tag}），Ctrl+C 退出"
    adb -s "${SERIAL}" logcat -v color "${tag}"
  else
    # 单帧快照：跟 1s 抓一次直到有内容
    timeout 2 adb -s "${SERIAL}" logcat -d -v color "${tag}" || true
  fi
}

cmd_restart() {
  check_device
  log_ok "force-stop ${PKG}"
  adb -s "${SERIAL}" shell am force-stop "${PKG}"
  sleep 0.3
  log_ok "start ${PKG}/${ACTIVITY}"
  adb -s "${SERIAL}" shell am start -n "${PKG}/${ACTIVITY}"

  # 轮询 dumpsys 看 starting window 是否还在显示
  # 不可靠：grep 找不到行就视为完成（可能启动窗已移除）
  local timeout=15 i=0
  while (( i < timeout )); do
    local shown
    shown=$(adb -s "${SERIAL}" shell dumpsys activity activities 2>/dev/null \
            | grep -c "mStartingWindowState=STARTING_WINDOW_SHOWN" || true)
    if [[ "${shown}" -eq 0 ]]; then
      break
    fi
    sleep 1
    (( i++ ))
  done
  # Flutter 渲染第一帧需要额外时间（冷启动 + 首帧 build），
  # 保险等 2 秒，避免调用方截图过早拿到空白帧
  sleep 2
  log_ok "已重启完成（用时 ${i}s）"
}

cmd_tap() {
  [[ $# -ge 2 ]] || die "用法：adb.sh tap <x> <y>"
  local x="$1" y="$2"
  check_device
  adb -s "${SERIAL}" shell input tap "${x}" "${y}"
  log_ok "tap (${x}, ${y})"
}

cmd_swipe() {
  [[ $# -ge 4 ]] || die "用法：adb.sh swipe <x1> <y1> <x2> <y2> [duration_ms]"
  local x1="$1" y1="$2" x2="$3" y2="$4" dur="${5:-300}"
  check_device
  adb -s "${SERIAL}" shell input swipe "${x1}" "${y1}" "${x2}" "${y2}" "${dur}"
  log_ok "swipe (${x1},${y1}) → (${x2},${y2}) ${dur}ms"
}

cmd_text() {
  [[ $# -ge 1 ]] || die "用法：adb.sh text <string>"
  local text="$*"
  # input text 不能直接含空格，需用 %s 替代
  text="${text// /%s}"
  check_device
  adb -s "${SERIAL}" shell input text "${text}"
  log_ok "已输入：${text}"
}

cmd_keyevent() {
  [[ $# -ge 1 ]] || die "用法：adb.sh keyevent <code|name>"
  check_device
  adb -s "${SERIAL}" shell input keyevent "$*"
  log_ok "keyevent: $*"
}

cmd_install() {
  [[ $# -ge 1 ]] || die "用法：adb.sh install <apk-path> [-r] [-t]"
  local apk="" replace="" test_allow=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -r) replace="-r"; shift;;
      -t) test_allow="-t"; shift;;
      *)   apk="$1"; shift;;
    esac
  done
  [[ -f "${apk}" ]] || die "找不到 APK：${apk}"
  check_device
  adb -s "${SERIAL}" install ${replace} ${test_allow} "${apk}"
  log_ok "已安装：${apk}"
}

cmd_focus() {
  check_device
  adb -s "${SERIAL}" shell dumpsys window | grep -E "mCurrentFocus|mFocusedApp" | head -3
}

cmd_info() {
  check_device
  echo "=== 设备 ==="
  echo "  serial : ${SERIAL}"
  adb -s "${SERIAL}" shell getprop ro.product.model | awk '{print "  model  : " $0}'
  adb -s "${SERIAL}" shell getprop ro.build.version.release | awk '{print "  android: " $0}'
  adb -s "${SERIAL}" shell wm size | awk '{print "  " $0}'
  adb -s "${SERIAL}" shell wm density | awk '{print "  " $0}'
  echo ""
  echo "=== 当前前台 ==="
  adb -s "${SERIAL}" shell dumpsys window | grep -E "mCurrentFocus" | head -1
  echo ""
  echo "=== 配置覆盖 ==="
  echo "  pkg     : ${PKG}"
  echo "  activity: ${ACTIVITY}"
  echo "  可用环境变量：DESK_MARIO_SERIAL / DESK_MARIO_PKG / DESK_MARIO_ACTIVITY"
}

cmd_help() {
  # 只输出开头注释块：跳过 shebang，遇到第一个非 # 非空行即停止
  awk '
    NR==1 { next }                        # 跳过 shebang
    /^#/  { sub(/^# ?/, ""); print; next }
    /^\s*$/ { print; next }               # 空行保留（让段落分隔可见）
    { exit }
  ' "${BASH_SOURCE[0]}"
}

# === 路由 ========================================================
case "${SUBCMD:-help}" in
  screenshot)  cmd_screenshot "$@";;
  logcat)      cmd_logcat "$@";;
  restart)     cmd_restart "$@";;
  tap)         cmd_tap "$@";;
  swipe)       cmd_swipe "$@";;
  text)        cmd_text "$@";;
  keyevent)    cmd_keyevent "$@";;
  install)     cmd_install "$@";;
  focus)       cmd_focus;;
  info)        cmd_info;;
  help|"")     cmd_help;;
  *)           log_err "未知子命令：${SUBCMD}"; cmd_help; exit 1;;
esac
