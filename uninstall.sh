#!/system/bin/sh
# AntiFraudBlock uninstall: remove ONLY what this module added.
# Never flushes OUTPUT and never touches other modules' rules.
iptables -w 2 -D OUTPUT -j ANTIFRAUD 2>/dev/null
iptables -w 2 -F ANTIFRAUD 2>/dev/null
iptables -w 2 -X ANTIFRAUD 2>/dev/null
ip6tables -w 2 -D OUTPUT -j ANTIFRAUD6 2>/dev/null
ip6tables -w 2 -F ANTIFRAUD6 2>/dev/null
ip6tables -w 2 -X ANTIFRAUD6 2>/dev/null
# Unmount our hosts bind-mount only if the active hosts is ours
# (marker check survives even if the module dir is already gone).
if grep -q "AntiFraudBlock" /system/etc/hosts 2>/dev/null; then
  umount /system/etc/hosts 2>/dev/null
fi
echo "- AntiFraudBlock removed, nothing else touched."
