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
| `hooks/wakeup-mark.sh` | PostToolUse hook on `ScheduleWakeup`: writes the confirmed wake time to `~/.claude/state/wakeups/<session_id>`, marks the loop as running, logs the arm; a stop removes both |
| `hooks/wakeup-fired.sh` | UserPromptSubmit hook: a prompt starting with `/loop` is a wakeup firing; logs it with how late it was, and 10+ min late also to `missed.log` |
| `hooks/wakeup-check.sh` | Stop hook: while a loop is running, a turn can't end without a wakeup armed ahead; it reminds Claude once (re-arm, or stop the loop); a wakeup that never fired goes to `missed.log` |
| `skill/SKILL.md` | the skill: how Claude reads the budget and the wake time, and paces long work against them |

## Install

Needs `jq`. Written for macOS (BSD `date -r`) and bash 3.2.

```sh
cp statusline.sh ~/.claude/statusline.sh
mkdir -p ~/.claude/hooks ~/.claude/skills/loop-usage-aware
cp hooks/wakeup-*.sh ~/.claude/hooks/
cp skill/SKILL.md ~/.claude/skills/loop-usage-aware/
chmod +x ~/.claude/statusline.sh ~/.claude/hooks/wakeup-*.sh
```

Then in `~/.claude/settings.json` (merge with what's there):

```json
{
  "statusLine": { "type": "command", "command": "~/.claude/statusline.sh" },
  "hooks": {
    "PostToolUse": [
      { "matcher": "ScheduleWakeup", "hooks": [ { "type": "command", "command": "~/.claude/hooks/wakeup-mark.sh" } ] }
    ],
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": "~/.claude/hooks/wakeup-fired.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "~/.claude/hooks/wakeup-check.sh" } ] }
    ]
  }
}
```

Restart Claude Code so the hook loads.

## Caveat: ask for loops in plain words, not with `/loop`

When you want Claude to do something periodically, **ask it in plain words** ("every hour at :15, post my turn in the
room"), and let Claude set up the loop itself. Avoid typing `/loop ...` yourself: the hooks treat any prompt that starts
with `/loop` as a wakeup firing (that's what Claude's scheduled wake-ups send), so a hand-typed one is logged as a fire
and can't be told apart from the scheduler. If you do type it, say it's you ("this is me, not the wakeup") so Claude
can tell you apart from the scheduled run.

## Missed wakeups

Everything is in `~/.claude/state/wakeups/`:

- `wakeups.log`: one line per arm, fire (with how late), and stop.
- `missed.log`: only the slips, i.e. a wakeup that fired 10+ minutes late, or one that never fired. Empty means all is well.
- The end-of-turn check is what prevents most slips: a wakeup that came due during a busy turn used to be lost
  silently; now the turn can't end until a new one is armed (or the loop is stopped). It reminds once per turn, so it
  can never trap the session.

## Notes

- `~/.claude/usage.txt`: `remaining`, `used`, `week_left`, `week_used`, `updated`. `unknown` means unknown, not 0 %.
- The wake time is per session (the status line's `session_id`), so each terminal shows its own.
- A wake time in the past shows as `none`, so a fired or missed wakeup never lingers.

---

**Origin session:** `392e3f9c-f4ac-402a-b8ea-3c1847fb979f` (2026-09-09 → 2026-09-11). Weekly fields added 9 Nov 2026,
the wake time and the packaged skill 13 Nov 2026.
