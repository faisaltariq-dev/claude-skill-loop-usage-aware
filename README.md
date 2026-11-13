# claude-skill-loop-usage-aware

A Claude Code skill plus a status line for **external work coordination**: long-running, scheduled work
(`/loop`, overnight runs, timed turns in a shared room with other agents) that has to fit around things outside the
session. At any moment it tells you, and Claude, three things:

- how much of the **5-hour window** is used and when it resets;
- how much of the **weekly limit** is used and when it resets;
- when this session **wakes next** (its next `ScheduleWakeup`), or `none`.

The status line looks like this:

```
Opus 5.5 · ctx 22% · 5h 60% · reset 26m · wk 42% · wake 16:15
```

The `loop` skill decides *when* to wake; this one says *how much budget there is* and shows the wake time.

## What's here

| file | what it does |
|---|---|
| `statusline.sh` | the status line command; also mirrors the budget to `~/.claude/usage.txt` on every API response |
| `hooks/wakeup-mark.sh` | PostToolUse hook on `ScheduleWakeup`: writes the confirmed wake time to `~/.claude/state/wakeups/<session_id>`; a stop removes it |
| `skill/SKILL.md` | the skill: how Claude reads the budget and the wake time, and paces long work against them |

## Install

Needs `jq`. Written for macOS (BSD `date -r`) and bash 3.2.

```sh
cp statusline.sh ~/.claude/statusline.sh
mkdir -p ~/.claude/hooks ~/.claude/skills/loop-usage-aware
cp hooks/wakeup-mark.sh ~/.claude/hooks/
cp skill/SKILL.md ~/.claude/skills/loop-usage-aware/
chmod +x ~/.claude/statusline.sh ~/.claude/hooks/wakeup-mark.sh
```

Then in `~/.claude/settings.json` (merge with what's there):

```json
{
  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" },
  "hooks": {
    "PostToolUse": [
      { "matcher": "ScheduleWakeup", "hooks": [ { "type": "command", "command": "~/.claude/hooks/wakeup-mark.sh" } ] }
    ]
  }
}
```

Restart Claude Code so the hook loads.

## Notes

- `~/.claude/usage.txt`: `remaining`, `used`, `week_left`, `week_used`, `updated`. `unknown` means unknown, not 0 %.
- The wake time is per session (the status line's `session_id`), so each terminal shows its own.
- A wake time in the past shows as `none`, so a fired or missed wakeup never lingers.

---

**Origin session:** `392e3f9c-f4ac-402a-b8ea-3c1847fb979f` (2026-09-09 → 2026-09-11). Weekly fields added 9 Nov 2026,
the wake time and the packaged skill 13 Nov 2026.
