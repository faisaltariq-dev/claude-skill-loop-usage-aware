#!/bin/bash
# PostToolUse hook for ScheduleWakeup: remember this session's next wakeup for the status line.
# Writes the wake time (epoch seconds) to ~/.claude/state/wakeups/<session_id>; a stop removes it.
# The status line (statusline.sh) shows "wake HH:MM", or "wake none" when the file is missing or past.
input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0
dir="${HOME}/.claude/state/wakeups"
mkdir -p "$dir" 2>/dev/null
sid=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)
[ -n "$sid" ] || exit 0
f="$dir/$sid"
stop=$(printf '%s' "$input" | jq -r '.tool_input.stop // false' 2>/dev/null)
if [ "$stop" = "true" ]; then rm -f "$f"; exit 0; fi
# Prefer what the runtime says it scheduled ("... (in 3526s)"), else the requested delay clamped to 60..3600
in=$(printf '%s' "$input" | jq -r '.tool_response | tostring' 2>/dev/null | grep -oE 'in [0-9]+s' | head -1 | grep -oE '[0-9]+')
if [ -z "$in" ]; then
  in=$(printf '%s' "$input" | jq -r '.tool_input.delaySeconds // empty | floor' 2>/dev/null)
  [ -n "$in" ] || exit 0
  [ "$in" -lt 60 ] && in=60
  [ "$in" -gt 3600 ] && in=3600
fi
echo $(( $(date +%s) + in )) > "$f"
exit 0
