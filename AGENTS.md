# LLM Collaboration Guide

Instructions for AI agents working in this repository. This file is for LLM behavior and coordination only.

---

## Scope and Priorities

- Follow repo architecture and workflow documentation; do not duplicate it here.
- Keep changes minimal, explicit, and easy to hand off.
- Prefer safe, reversible edits.

---

## Safety and Permissions

- **Never run sudo commands.** Present the command, explain why, ask the user to run it, and continue with their output.
- **Do not handle secrets.** Never add, log, or request secret material (keys, tokens, passphrases).
- **Be explicit about assumptions.** If a step depends on host state, ask or record the assumption in handoff notes.

---

## Documentation Style (when editing docs)

- Terse, technical, imperative tone.
- Use `---` to separate major sections.
- Numbered steps for procedures; list expected results when helpful.
- Code blocks with language hints.
- Absolute paths where clarity matters.

---

## Git and Coordination

- Commit messages: imperative mood, focus on "why", include host prefix when relevant, never mention AI tools.
- If multiple agents touch the repo, leave a handoff at the end of `AGENTS-TODO.txt`.
- Record commands run and any tests needed.

---

## Handoff Template

```
## Handoff: [Agent Name] → [Next Agent]
**Date:** YYYY-MM-DD HH:MM
**Goal:** [One sentence: what were you trying to accomplish?]

### Scope
Files changed:
- path/to/file1 — brief description
- path/to/file2 — brief description

### Work Completed
- [x] Task 1 description
- [ ] Task 2 — NOT completed because [reason]

### Assumptions Made
- Assumption 1 about system state
- Assumption 2 about user preference

### Commands Run (if any)
```bash
command1  # output: [key result]
command2  # output: [key result]
```

### Tests Needed
- [ ] Test X to verify Y
- [ ] Test Z to verify W

### Risks/Unknowns
- Thing 1 that needs verification
- Thing 2 that might break
```

---
