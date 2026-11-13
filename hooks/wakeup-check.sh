#!/bin/bash
# Stop hook: while a loop is active (wakeup-mark.sh's <session>.loop), a turn may not end without a wakeup armed in
# the future. If none is, the stop is blocked once with a reminder to re-arm (or stop the loop with stop: true).
# Never blocks twice in a row (stop_hook_active), so it can't trap the session. A wake 10+ min overdue that never
# fired is logged to missed.log once.
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
dir="${HOME}/.claude/state/wakeups"
f="$dir/$sid"
[ -f "$f.loop" ] || exit 0                      # no loop running: nothing to check
now=$(date +%s)
at=$(cat "$f" 2>/dev/null)
case "$at" in ''|*[!0-9]*) at=0 ;; esac
[ "$at" -gt "$now" ] && exit 0                  # a wakeup is armed ahead: fine
short=${sid:0:8}
# overdue and never fired: a miss (logged once per arm)
if [ "$at" -gt 0 ] && [ $(( now - at )) -ge 600 ] && [ ! -f "$f.fired" ] && [ ! -f "$f.missed" ]; then
  echo "$(date '+%F %T') $short wakeup armed for $(date -r "$at" '+%H:%M') never fired ($(( (now - at) / 60 )) min overdue)" >> "$dir/missed.log"
  touch "$f.missed"
fi
active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)
[ "$active" = "true" ] && exit 0                # already reminded this turn
last=$([ "$at" -gt 0 ] && date -r "$at" '+%H:%M' || echo "never")
jq -n --arg r "A loop is active but no wakeup is armed (last one was for $last). Before ending the turn: re-arm it with ScheduleWakeup for the next slot, or stop the loop (ScheduleWakeup stop: true) if it should end." '{decision: "block", reason: $r}'
exit 0
