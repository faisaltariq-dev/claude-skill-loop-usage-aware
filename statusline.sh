#!/bin/bash
# Claude Code status line + 5h usage mirror.
# stdin: status line JSON.  Side effect: ~/.claude/usage.txt.  stdout: one short line.
# macOS/BSD `date -r`; bash 3.2 safe.

input=$(cat)

OUT="${HOME}/.claude/usage.txt"
TMP="${OUT}.tmp.$$"

command -v jq >/dev/null 2>&1 || { printf 'jq not found'; exit 0; }

COUNTDOWN='def countdown:
  (. - now) as $s
  | if $s <= 0 then "now"
    else ($s / 60 | floor) as $m
    | if $m >= 60 then "\($m / 60 | floor)h \($m % 60)m" else "\($m)m" end
    end;'

# ---- mirror (atomic: write tmp, then mv) --------------------------------
if printf '%s' "$input" | jq -e . >/dev/null 2>&1; then
  fields=$(printf '%s' "$input" | jq -r "$COUNTDOWN"'
    .rate_limits.five_hour
    | if type == "object"
      then "\(.resets_at | countdown)\t\(.used_percentage | round)%\t\(.resets_at)"
      else "unknown\tunknown\t-"
      end
  ' 2>/dev/null)

  if [ -n "$fields" ]; then
    IFS=$'\t' read -r remaining used res <<<"$fields"
    stamp=$(date '+%F %T')
    if {
         printf '%-10s %s\n' "remaining" "$remaining"
         printf '%-10s %s\n' "used"      "$used"
         if [ "$res" = "-" ]; then
           printf '%-10s %s\n' "updated" "$stamp"
         else
           printf '%-10s %s   (resets_at %s)\n' "updated" "$stamp" "$res"
         fi
       } >"$TMP" 2>/dev/null
    then
      mv -f "$TMP" "$OUT" 2>/dev/null || rm -f "$TMP"
    else
      rm -f "$TMP"
    fi
  fi
fi

# ---- status line --------------------------------------------------------
# $( ) strips trailing newlines and printf '%s' adds none, so stdout is exactly
# one line with no terminator. A trailing \n makes the renderer split the text
# into ["<line>", ""] and draw a blank second row.
line=$(printf '%s' "$input" | jq -r "$COUNTDOWN"'
  [ (.model.display_name // empty),
    (if (.context_window.used_percentage | type) == "number"
     then "ctx \(.context_window.used_percentage | round)%" else empty end),
    (if (.rate_limits.five_hour.used_percentage | type) == "number"
     then "5h \(.rate_limits.five_hour.used_percentage | round)%" else empty end),
    (if (.rate_limits.five_hour.resets_at | type) == "number"
     then "reset \(.rate_limits.five_hour.resets_at | countdown)" else empty end)
  ] | join(" · ")
' 2>/dev/null)

printf '%s' "$line"

# Never let a jq failure surface as a status line error.
exit 0
