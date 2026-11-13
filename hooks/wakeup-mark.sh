#!/bin/bash
# PostToolUse hook for ScheduleWakeup: remember this session's next wakeup (status line, reminders, logs).
# Files under ~/.claude/state/wakeups/:
#   <session_id>        the armed wake time (epoch seconds); read by statusline.sh ("wake HH:MM")
#   <session_id>.loop   present while a loop is active (an arm creates it, stop: true removes it)
#   wakeups.log         one line per arm / stop / fire (wakeup-fired.sh) / miss
#   missed.log          only the slips: a wakeup that fired 10+ min late, or a loop left with nothing armed
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
dir="${HOME}/.claude/state/wakeups"
mkdir -p "$dir" 2>/dev/null
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
f="$dir/$sid"
now=$(date +%s)
short=${sid:0:8}
stop=$(printf '%s' "$input" | jq -r '.tool_input.stop // false' 2>/dev/null)
if [ "$stop" = "true" ]; then
  rm -f "$f" "$f.loop"
  echo "$(date '+%F %T') stopped  $short" >> "$dir/wakeups.log"
  exit 0
fi
# Prefer what the runtime says it scheduled ("... (in 3526s)"), else the requested delay clamped to 60..3600
in=$(printf '%s' "$input" | jq -r '.tool_response | tostring' 2>/dev/null | grep -oE 'in [0-9]+s' | head -1 | grep -oE '[0-9]+')
if [ -z "$in" ]; then
  in=$(printf '%s' "$input" | jq -r '.tool_input.delaySeconds // empty | floor' 2>/dev/null)
  [ -n "$in" ] || exit 0
  [ "$in" -lt 60 ] && in=60
  [ "$in" -gt 3600 ] && in=3600
fi
at=$(( now + in ))
echo "$at" > "$f"
touch "$f.loop"
rm -f "$f.missed" "$f.fired"   # a fresh arm: earlier fires and misses are already logged
echo "$(date '+%F %T') armed    $short for $(date -r "$at" '+%H:%M:%S')" >> "$dir/wakeups.log"
exit 0
