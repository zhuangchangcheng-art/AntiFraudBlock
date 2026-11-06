#!/system/bin/sh
# AntiFraudBlock Action: re-apply rules, then print status.
# (KSU manager shows this output when the Action button is tapped.)
MODDIR="$(dirname "$0")"
sh "$MODDIR/service.sh" >/dev/null 2>&1
echo "--- AntiFraudBlock status ---"
if [ -f "$MODDIR/disable" ]; then
  echo "module: DISABLED (disable marker present)"
elif [ -f "$MODDIR/remove" ]; then
  echo "module: MARKED FOR REMOVAL"
else
  echo "module: enabled"
fi
if [ -f "$MODDIR/system/etc/hosts" ]; then
  src_md5=$(md5sum "$MODDIR/system/etc/hosts" 2>/dev/null | awk '{print $1}')
  sys_md5=$(md5sum /system/etc/hosts 2>/dev/null | awk '{print $1}')
  if [ -n "$src_md5" ] && [ "$src_md5" = "$sys_md5" ]; then
    echo "hosts: ACTIVE (module hosts in place)"
  else
    echo "hosts: NOT ACTIVE (will apply at next boot via magic mount)"
  fi
else
  echo "hosts: source file missing!"
fi
if command -v iptables >/dev/null 2>&1; then
  n=$(iptables -w 2 -L ANTIFRAUD -n 2>/dev/null | grep -c 'REJECT')
  echo "iptables: ANTIFRAUD chain REJECT rules: $n"
else
  echo "iptables: not found"
fi
if command -v ip6tables >/dev/null 2>&1; then
  n6=$(ip6tables -w 2 -L ANTIFRAUD6 -n 2>/dev/null | grep -c 'REJECT')
  echo "ip6tables: ANTIFRAUD6 chain REJECT rules: $n6"
fi
echo "Done. Full log: $MODDIR/antifraud.log"
