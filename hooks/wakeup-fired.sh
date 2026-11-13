#!/bin/bash
# UserPromptSubmit hook: a prompt starting with "/loop" is a wakeup firing (the owner never types /loop himself; he
# asks for loops in plain words). Logs when it fired and how late; 10+ min late goes to missed.log too.
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
case "$prompt" in /loop*) ;; *) exit 0 ;; esac
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
dir="${HOME}/.claude/state/wakeups"
mkdir -p "$dir" 2>/dev/null
f="$dir/$sid"
now=$(date +%s)
short=${sid:0:8}
at=$(cat "$f" 2>/dev/null)
case "$at" in ''|*[!0-9]*) echo "$(date '+%F %T') fired    $short (no armed time on record)" >> "$dir/wakeups.log"; exit 0 ;; esac
late=$(( now - at ))
echo "$(date '+%F %T') fired    $short for $(date -r "$at" '+%H:%M:%S'), ${late}s late" >> "$dir/wakeups.log"
if [ "$late" -ge 600 ]; then
  echo "$(date '+%F %T') $short wakeup armed for $(date -r "$at" '+%H:%M') fired $(( late / 60 )) min late" >> "$dir/missed.log"
fi
touch "$f.fired"
exit 0
