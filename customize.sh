#!/system/bin/sh
# AntiFraudBlock installer - minimal, no destructive steps.
# KSU Hot Install: run hotinstall.sh after replacing the module dir,
# so the block takes effect without a reboot (temp-root phones).
SKIPUNZIP=1
export MODULE_HOT_INSTALL_REQUEST=true
export MODULE_HOT_RUN_SCRIPT=hotinstall.sh
ui_print "- AntiFraudBlock: installing (anti-fraud reporting block only)"
ui_print "- No DNS proxy, no app changes, no reboot required (Hot Install)"
for file in module.prop service.sh action.sh uninstall.sh hotinstall.sh block-ips.txt; do
  unzip -o "$ZIPFILE" "$file" -d "$MODPATH" 2>/dev/null
done
unzip -o "$ZIPFILE" "system/*" -d "$MODPATH" 2>/dev/null
chmod +x "$MODPATH/service.sh" "$MODPATH/action.sh" "$MODPATH/uninstall.sh" "$MODPATH/hotinstall.sh" 2>/dev/null
ui_print "- Done. Hot Install auto-starts it; otherwise tap the module Action button."
ui_print "- Uninstall removes every rule it added, nothing else is touched."
