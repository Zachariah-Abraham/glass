# CLAUDE.md

All project guidance for agents lives in AGENTS.md, so other agent tools can share it.
Current work status lives in tasks.md.

@AGENTS.md
@tasks.md

Key rules (details in AGENTS.md):
- Always commit your work in small, working increments.
- Treat all work as hand-off-able. After any progress, update `tasks.md` (and `AGENTS.md` if a
  durable fact changed) so another agent or the human can continue from the docs alone.
  Context can be auto-compacted at any moment.
- Flutter runs through FVM with no pinned version. Use `~/fvm/versions/stable/bin/flutter`
  (see AGENTS.md §3).
