---
name: uh-no-audit
description: Walk the operator through the uh-no list one item at a time, deciding for each whether to discard it, turn it into a CLAUDE.md rule, or scaffold a skill — removing items as they're resolved. Use ONLY when the operator explicitly invokes it ("/uh-no-audit").
---

# uh-no-audit

Triage for the list `uh-no` builds. Every item leaves the list in one of three ways —
discarded, encoded as a rule, or scaffolded into a skill — or is explicitly deferred.

**Only run when explicitly invoked.** This edits `~/.claude/CLAUDE.md` and creates
skill directories, so it never runs as a side effect of other work.

Optional argument filters the run: a slug audits just that item, `--repeats` audits only
behaviors logged more than once.

## Steps

1. **Load.** Read `~/.claude/uh-no.md`. If it's empty or missing, say so and stop.
   Otherwise report the count and work oldest-first.

2. **Look for collapses first.** Before walking items one by one, scan the whole list for
   entries sharing a root cause — three flavors of "kept retrying a dead tool" are one
   rule, not three. Propose the merge up front and, if the operator agrees, handle them as
   a single item and remove all of them together when it resolves.

3. **Present each item.** Slug, what went wrong, the correction, and whether it recurs.
   Keep it to a few lines — the operator wrote these and doesn't need them re-narrated.

4. **Recommend, then ask.** Use AskUserQuestion with a one-line rationale for your pick,
   which goes first in the options list:
   - **Discard** — one-off, already fixed upstream, or the agent was arguably right.
   - **CLAUDE.md rule** — expressible in one or two imperative lines. Draft the exact
     wording and name the section it belongs under.
   - **Own skill** — needs procedure, not a rule: multiple steps, conditional branches, or
     reference material it should read.
   - **Defer** — leave on the list, move on.

5. **Check for conflicts before writing a rule.** Read the target section of
   `~/.claude/CLAUDE.md` and confirm the new rule doesn't contradict or duplicate what's
   already there. If it contradicts something, stop and surface both versions — that's the
   case where the operator may have changed their mind and the file is stale. Let them
   decide which survives; don't quietly reconcile it.

6. **Apply, then remove.** Do the thing — surgical `Edit` into CLAUDE.md, scaffold
   `~/.claude/skills/<name>/SKILL.md`, or nothing — and only then delete the item from
   `~/.claude/uh-no.md`. One item resolved, one write to each file. An interrupted session
   must never lose work already applied or drop an item whose disposition didn't land.

7. **Coherence pass.** After the last item, re-read the CLAUDE.md sections touched this
   run and check the new lines read as a set: no near-duplicates, no rule that
   over-generalizes from a single incident. Propose tightening if needed.

8. **Summarize.** N discarded, N ruled, N scaffolded, N deferred, and the paths touched.

## Writing rules

A good rule generalizes the *correction*, not the incident. "Don't retry a failing
agent-browser command" is too narrow; "if a browser tool fails twice, stop and tell me" is
the rule. Match the file's existing voice — imperative, second person, no hedging — and
put it under an existing heading rather than inventing a new one for a single line.

## Scaffolding skills

Produce a stub, not a finished skill: frontmatter with `name` and a description stating
when it applies, plus the steps implied by the correction. Tell the operator it's a stub
and let them decide whether to flesh it out now. Never leave the item on the list on the
grounds that the skill isn't finished — the stub existing is the resolution.
