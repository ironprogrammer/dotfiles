---
name: uh-no
description: Log an agent misstep, and the operator's correction, to the follow-up list at ~/.claude/uh-no.md. Use ONLY when the operator explicitly invokes it ("/uh-no", "uh-no, log that") — never proactively, never as part of another task.
---

# uh-no

Captures a moment where an agent went wrong and what the operator actually wanted,
so it can be triaged later into a CLAUDE.md rule, its own skill, or the bin.

**Only run when explicitly invoked.** Never volunteer this skill, never append an
entry the operator did not ask for, and never run it "while I'm here" during other work.

## The list

`~/.claude/uh-no.md` — append-only. Create it with the header below if missing.
Never edit or remove existing entries; pruning belongs to the triage step.

## Steps

1. **Find the misstep.** Re-read the recent conversation — usually the last few
   exchanges. If the operator passed an argument, that names the misstep; use it to
   focus rather than guessing. If more than one candidate exists and it's genuinely
   ambiguous, ask which one before writing anything.

2. **Draft the entry.** Three parts, all sourced from what actually happened in this
   conversation — no inference, no editorializing, no blame softening:
   - **Went wrong:** what the agent did, factually.
   - **Wanted:** what the operator was actually after.
   - **Correction:** the method, approach, or clarification the operator gave. This is
     the valuable part — it's what a future rule or skill would encode. If the operator
     never stated one, write `(none given)` rather than inventing one.

3. **Dedupe.** Read the whole list and compare *behaviors*, not wording. A near-match
   counts: "reran the same failing browser tool" and "kept retrying a broken MCP call"
   are the same problem. If one matches, stop, show the operator the existing entry, and
   ask whether to skip, add anyway as a repeat, or amend the correction on the existing
   entry. Default to skipping. If they choose repeat, append normally — recurrence is
   itself signal for triage.

4. **Append and confirm.** Add the entry at the end of the file. Report back with the
   slug and the current item count. Keep it to a line or two.

## Entry format

```markdown
## 2026-08-26 — retry-loop-on-dead-browser-tool
- **Where:** ~/Sites/wordpress-develop
- **Went wrong:** Reran the same failing agent-browser command five times, each with a
  small tweak, instead of stopping.
- **Wanted:** Stop after two failures and hand the problem back.
- **Correction:** "If a browser tool fails twice, stop and tell me. They won't recover
  on their own."
```

The slug is a short kebab-case handle for the behavior — it's the dedupe key and how
the triage step refers to the item, so make it describe the problem, not the incident.

File header, if creating the list:

```markdown
# uh-no

Agent missteps worth following up on. Append-only — entries leave only via triage.
```
