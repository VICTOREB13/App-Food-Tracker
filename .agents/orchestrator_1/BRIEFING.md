# BRIEFING — 2026-09-07T16:07:00Z

## Mission
Orchestrate Phase 2 implementation of Victor Engineer - Food Tracker (NutriTracker Local-First): Dynamic Gemini model selector, USDA FoodData Central integration, User Profile & Onboarding with Master Prompt / TDEE, SQLite weight_logs, and Bento Metrics dashboard, ensuring all acceptance criteria, <300 LoC, and test standards are strictly met.

## 🔒 My Identity
- Archetype: orchestrator
- Roles: orchestrator, user_liaison, human_reporter, successor
- Working directory: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\orchestrator_1
- Original parent: sentinel
- Original parent conversation ID: 7a62fb7e-6579-4524-9fb5-79b3322f4c8e

## 🔒 My Workflow
- **Pattern**: Project Pattern (Dual Track: Implementation + E2E Testing)
- **Scope document**: C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\PROJECT.md
1. **Decompose**: Survey codebase with 3 explorers/spec-miners, synthesize Feature Inventory in PROJECT.md, decompose into module-bounded milestones (R1-R5) and E2E Testing Track.
2. **Dispatch & Execute**: Direct or sub-orchestrator delegation per milestone following Explorer -> Worker -> Reviewer -> Challenger -> Auditor gate loop.
3. **On failure**:
   - Retry: nudge stuck agent or re-send task
   - Replace: spawn fresh agent with partial progress
   - Skip: proceed without (only if non-critical, never skip auditor)
   - Redistribute: split stuck agent's remaining work
   - Redesign: re-partition decomposition
   - Escalate: last resort (project orchestrator redesigns)
4. **Succession**: At 16 spawns, write soft handoff.md, spawn successor with archetype orchestrator, and exit.
- **Work items**:
  1. Survey & Codebase Exploration [in-progress]
  2. PROJECT.md & Decomposition [pending]
  3. Milestone Execution & E2E Testing Track [pending]
  4. Final Milestone & Hardening [pending]
- **Current phase**: 1 (Survey & Assessment)
- **Current focus**: Survey phase with 3 parallel explorers/spec miners

## 🔒 Key Constraints
- Never write, modify, or create source code files directly.
- Never run build/test commands directly.
- Never investigate code directly — dispatch Explorers.
- All file edits by orchestrator limited to .agents/ metadata files (.md).
- Binary veto on forensic audit failure.
- Never reuse subagents after handoff.
- Pass ORIGINAL_REQUEST.md path verbatim to all subagents.
- Screen files < 300 LoC, _sentinel pattern on models, flutter analyze 0 errors/warnings.

## Current Parent
- Conversation ID: 7a62fb7e-6579-4524-9fb5-79b3322f4c8e
- Updated: 2026-09-07T16:06:00Z

## Key Decisions Made
- Initiated Top-Level Project Orchestrator workflow for Phase 2.
- Running Survey phase with 3 parallel subagents (Explorers / Spec Miners) to examine existing Phase 1 codebase, database schema, services, and screens.

## Team Roster
| Agent | Type | Work Item | Status | Conv ID |
|-------|------|-----------|--------|---------|
| explorer_survey_1 | teamwork_preview_explorer | Codebase & SQLite Survey | in-progress | c98fcf98-747e-46e5-88de-f3aab554af19 |
| spec_miner_survey_2 | teamwork_preview_spec_miner | External APIs & Credentials Survey | in-progress | bf6d5fe3-754e-4ec8-aade-3f983b24e9cb |
| explorer_survey_3 | teamwork_preview_explorer | UI Architecture & Metrics Survey | in-progress | 51bd3538-ead9-4939-9264-b9c6fc54fec3 |

## Succession Status
- Succession required: no
- Spawn count: 3 / 16
- Pending subagents: c98fcf98-747e-46e5-88de-f3aab554af19, bf6d5fe3-754e-4ec8-aade-3f983b24e9cb, 51bd3538-ead9-4939-9264-b9c6fc54fec3
- Predecessor: none
- Successor: not yet spawned

## Active Timers
- Heartbeat cron: task-20 (recurring every 10 min)
- Safety timer: covered by heartbeat cron
- On succession: kill all timers before spawning successor
- On context truncation: run `manage_task(Action="list")` — re-create if missing

## Artifact Index
- C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\ORIGINAL_REQUEST.md — Authoritative User Request
- C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\orchestrator_1\DISPATCH.md — Dispatch log
- C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\orchestrator_1\progress.md — Liveness & progress tracker
- C:\Users\vmesp\Documents\Cositas\App-Food-Tracker\.agents\orchestrator_1\BRIEFING.md — Persistent working memory
