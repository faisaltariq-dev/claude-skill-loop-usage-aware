# claude-skill-loop-usage-aware

Raw skill/idea dump. Not packaged yet.

## Usage budget

`cat ~/.claude/usage.txt` when asked to check the budget on a long task — it holds
`remaining` (time until the 5-hour window resets) and `used` (percent of it consumed).
`unknown` means unknown, not 0%. The `updated` line says when those were last written;
they refresh on every API response, so during active work they're seconds old.

## Idea: `/loop-usage-aware` skill (not scheduled)

Possible future packaging of the above as a global skill, complementary to the `loop`
skill: `loop` decides *when* to wake, this reports *how much 5-hour budget is left*.
`~/.claude/statusline.sh` is self-contained and `HOME`-relative with no project
dependencies, so packaging is a copy plus a `SKILL.md`. Candidate for public release.

---

**Origin session:** `392e3f9c-f4ac-402a-b8ea-3c1847fb979f` (2026-09-09 → 2026-09-11)

```sh
claude --resume 392e3f9c-f4ac-402a-b8ea-3c1847fb979f
```
