---
name: loop-usage-aware
description: Check how much Claude usage budget is left (the 5-hour window and the weekly limit) and when this session wakes next, before and during long or looping work. Use when the owner asks about usage, budget, limits or the next wakeup, at the start of a /loop or overnight task, before spawning subagents or a big batch of work, and at each loop wakeup. Complements the loop skill (loop decides when to wake; this says how much budget there is and shows the wake time).
---

# Usage-aware pacing

**Designed for external work coordination:** long-running, scheduled work that has to fit around commitments outside
the session, such as timed turns in a shared room with other agents, owner check-ins, and the usage resets
themselves. It answers three questions at any moment: how much of the 5-hour window is left, how much of the week, and
when this session wakes next.

## Read the budget

```sh
cat ~/.claude/usage.txt
```

It is written by `~/.claude/statusline.sh` (the status line command in `~/.claude/settings.json`) on every API response, so during active work it is seconds old. Fields:

| line | meaning |
|---|---|
| `remaining` | time until the 5-hour window resets |
| `used` | percent of the 5-hour window consumed |
| `week_left` | time until the weekly (7-day) limit resets |
| `week_used` | percent of the weekly limit consumed |
| `updated` | when the file was last written (`resets_at` = the 5-hour reset, Unix seconds) |

- `unknown` means unknown, never 0 %.
- If `updated` is more than a few minutes old, the numbers are stale (no response has refreshed them); say so rather than trusting them. The next response refreshes them, so re-read after one.
- If the file is missing, the status line isn't installed: the source is the repo `faisaltariq-dev/claude-skill-loop-usage-aware` (`statusline.sh`), and it needs `jq`.

## The next wakeup

The status line ends with `wake HH:MM` (this session's next ScheduleWakeup) or `wake none`. A PostToolUse hook on
ScheduleWakeup (`~/.claude/hooks/wakeup-mark.sh`) writes the time the runtime confirmed to
`~/.claude/state/wakeups/<session_id>`; `stop: true` removes it; a time in the past shows as `none`.

```sh
date -r "$(cat ~/.claude/state/wakeups/<session_id>)" '+%H:%M'
```

- **Missed wakeups** are logged in `~/.claude/state/wakeups/missed.log` (fired 10+ min late, or never fired); `wakeups.log` has every arm, fire and stop. If the Stop hook says "A loop is active but no wakeup is armed", re-arm for the next slot (or stop the loop) before ending the turn.
- A prompt starting with `/loop` is treated as a wakeup firing. The owner asks for loops in plain words; if they ever type `/loop` themselves, they'll say so.
- **Every turn of a /loop must end with a wakeup armed** (unless the loop is meant to stop). `wake none` in the
  status line while a loop should be running means a wakeup was missed: re-arm it.
- If a wakeup was armed before the hook was installed (or the settings weren't reloaded), the line shows `none` even
  though one is pending; the next ScheduleWakeup call fixes it.

## How to use it

- **Report** both windows in one short line when asked, e.g. "5h: 26 % used, resets in 4h 15m; week: 4 % used, resets in 4d 14h; next wake 16:15".
- **Pace against both windows.** The 5-hour window decides what fits before its reset; the weekly one decides whether to spend at all. Compare the share used with the share of the window elapsed: ahead of the clock means slow down, well behind it means there's room to go heavier (subagents, parallel runs, longer benchmarks).
- **Before expensive work** (subagents, multi-agent reviews, large batches), check first and mention the budget in the proposal.
- **In a /loop**, read it at each wakeup. If the 5-hour window is nearly spent (about 90 %+) with long left before reset, do only the scheduled duty (e.g. a room turn), defer the rest, and arm the next wakeup after the reset. If the weekly use is high (about 80 %+) with days left, tell the owner before carrying on with optional work.
- These are guides, not hard rules: the owner's instructions (e.g. "go crazy, I just reset") override them.
