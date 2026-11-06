#!/system/bin/sh
# AntiFraudBlock - one-shot block installer (no daemon, no loop).
# What it does, and ONLY this:
#  1. Bind-mount the module hosts over /system/etc/hosts (skipped if
#     already active, checked by md5), so the listed anti-fraud hostnames
#     resolve to 0.0.0.0 / :: for anything using the system resolver.
#  2. Install a dedicated iptables chain ANTIFRAUD (filter table) jumped
#     from OUTPUT, with REJECT rules for the listed anti-fraud IPs.
#     REJECT (not DROP) so blocked attempts fail fast, no app hangs.
#     IPv6 chain ANTIFRAUD6 is created only if the v6 list is non-empty.
# What it NEVER does:
#  - No port-53 rule, no REDIRECT, no DNS proxy, no AGH, no daemon.
#  - No pm disable/enable, no app component changes, no file locking.
#  - No cloud fetch: the IP list is static in block-ips.txt.
# Idempotent: re-running flushes and re-adds the same rules.
# Fail-safe: any step failing only logs; normal networking is untouched.
MODDIR="$(dirname "$0")"
LOG="$MODDIR/antifraud.log"
IPLIST="$MODDIR/block-ips.txt"
HOSTS_SRC="$MODDIR/system/etc/hosts"
CHAIN="ANTIFRAUD"
CHAIN6="ANTIFRAUD6"

log() { echo "$(date '+%F %T') $*" >> "$LOG" 2>/dev/null; }

# --- bounded boot wait (Hot Install: boot already complete) ---
i=0
while [ $i -lt 12 ]; do
  [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && break
  sleep 5; i=$((i+1))
done

# --- 1. hosts bind-mount (idempotent by md5) ---
if [ -f "$HOSTS_SRC" ]; then
  src_md5=$(md5sum "$HOSTS_SRC" 2>/dev/null | awk '{print $1}')
  sys_md5=$(md5sum /system/etc/hosts 2>/dev/null | awk '{print $1}')
  if [ -n "$src_md5" ] && [ "$src_md5" = "$sys_md5" ]; then
    log "hosts: already active (md5 match)"
  else
    if mount --bind "$HOSTS_SRC" /system/etc/hosts 2>>"$LOG"; then
      log "hosts: bind mount OK"
    else
      log "hosts: bind mount FAILED (magic mount may still apply at next boot)"
    fi
  fi
else
  log "hosts: source file missing!"
fi

# --- 2. iptables REJECT rules (dedicated chain, filter table) ---
if ! command -v iptables >/dev/null 2>&1; then
  log "iptables: not found, IP block skipped (hosts layer still applies)"
  exit 0
fi
iptables -w 2 -N "$CHAIN" 2>/dev/null
iptables -w 2 -C OUTPUT -j "$CHAIN" 2>/dev/null || iptables -w 2 -I OUTPUT -j "$CHAIN" 2>>"$LOG"
iptables -w 2 -F "$CHAIN" 2>>"$LOG"
added=0; failed=0
if [ -f "$IPLIST" ]; then
  while read -r ip; do
    [ -z "$ip" ] && continue
    case "$ip" in \#*) continue;; esac
    case "$ip" in
      *:*)
        continue;;
      *)
        if iptables -w 2 -A "$CHAIN" -d "$ip" -j REJECT 2>>"$LOG"; then
          added=$((added+1))
        else
          failed=$((failed+1))
        fi;;
    esac
  done < "$IPLIST"
fi
log "iptables: chain $CHAIN ready, REJECT added=$added failed=$failed"

# --- 2b. ip6tables (only if the v6 list is non-empty) ---
if command -v ip6tables >/dev/null 2>&1 && [ -f "$IPLIST" ]; then
  has_v6=0
  while read -r ip; do
    [ -z "$ip" ] && continue
    case "$ip" in \#*) continue;; esac
    case "$ip" in *:*)
      has_v6=1; break;;
    esac
  done < "$IPLIST"
  if [ "$has_v6" = "1" ]; then
    ip6tables -w 2 -N "$CHAIN6" 2>/dev/null
    ip6tables -w 2 -C OUTPUT -j "$CHAIN6" 2>/dev/null || ip6tables -w 2 -I OUTPUT -j "$CHAIN6" 2>>"$LOG"
    ip6tables -w 2 -F "$CHAIN6" 2>>"$LOG"
    added6=0; failed6=0
    while read -r ip; do
      [ -z "$ip" ] && continue
      case "$ip" in \#*) continue;; esac
      case "$ip" in
        *:*)
          if ip6tables -w 2 -A "$CHAIN6" -d "$ip" -j REJECT 2>>"$LOG"; then
            added6=$((added6+1))
          else
            failed6=$((failed6+1))
          fi;;
      esac
    done < "$IPLIST"
    log "ip6tables: chain $CHAIN6 ready, REJECT added=$added6 failed=$failed6"
  else
    log "ip6tables: v6 list empty, v6 chain skipped"
  fi
else
  log "ip6tables: not found or no list, v6 block skipped"
fi
log "AntiFraudBlock: service done"
