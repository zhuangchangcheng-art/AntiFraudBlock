#!/system/bin/sh
# KSU Hot Install entry: run service.sh once, in background, so the
# block takes effect without a reboot. service.sh is one-shot (no daemon).
MODDIR="$(dirname "$0")"
LOG="$MODDIR/antifraud.log"
SERVICE=""
if [ -f "$MODDIR/service.sh" ]; then SERVICE="$MODDIR/service.sh"; fi
echo "$(date '+%F %T') HotInstall: starting, service=$SERVICE" >> "$LOG" 2>/dev/null
if [ -z "$SERVICE" ]; then
  echo "$(date '+%F %T') HotInstall: service.sh not found" >> "$LOG" 2>/dev/null
  exit 0
fi
if command -v setsid >/dev/null 2>&1; then
  setsid sh "$SERVICE" >> "$LOG" 2>&1 &
else
  nohup sh "$SERVICE" >> "$LOG" 2>&1 &
fi
echo "$(date '+%F %T') HotInstall: service launched in background" >> "$LOG" 2>/dev/null
exit 0
