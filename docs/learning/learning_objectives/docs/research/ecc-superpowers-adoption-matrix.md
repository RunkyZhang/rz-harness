# ECC / superpowers Adoption Matrix For SFA Harness

> Phase 2 adoption matrix for `harness-evolution-architecture`. Every item is a proposal input only. Implementation still requires a confirmed technical solution, test plan, and normal harness gates.

## Adoption Scale

| Decision | Meaning |
| --- | --- |
| ADOPT PRINCIPLE | Preserve the behavior or rule as a core design principle. Implementation shape is still SFA-specific. |
| ADAPT | Rebuild the idea inside SFA's control plane using local docs, scripts, and business constraints. |
| PILOT | Try in a narrow, reversible slice with metrics before broader use. |
| DO_NOT_COPY | Explicitly reject direct adoption because it conflicts with SFA constraints or creates avoidable risk. |

## Matrix

| ID | Proposal Input | Source | Problem Addressed | SFA Fit | Decision | Required Before Implementation |
| --- | --- | --- | --- | --- | --- | --- |
| A1 | Build a repeatable harness audit scorer from `gate-registry.md`. | [ECC-SOURCE] ECC-1, ECC-2; [LOCAL-FACT] SFA-1 | Current registry is static and does not produce trendable health scores. | High. SFA already has gate metadata and self-audit scripts. | ADAPT | Define SFA audit categories, scoring weights, JSON output, and no-fail initial mode. |
| A2 | Add gate / skill execution telemetry records. | [ECC-SOURCE] ECC-3, ECC-4; [LOCAL-FACT] SFA-6 | `skill-usage.md` is a form, not effectiveness data; gate retirement lacks input data. | High, if sanitized. | ADAPT | Data schema, secret redaction policy, JSONL location, retention policy, and migration from manual skill-usage. |
| A3 | Replace `skill-usage.md` as a hard table with event-based evidence and trend audit. | [ECC-SOURCE] ECC-3, ECC-4; [LOCAL-FACT] SFA-6; [FEISHU-RESEARCH] local diagnosis flags skill-usage friction | Current `skill-usage-gate.sh` forces paperwork even when skill usage is obvious from runtime context. | Medium-high. Needs careful transition because AGENTS and gates depend on it. | PILOT | Keep current gate during pilot; create event records in parallel; after measurement, design whether to fold into `evidence.md` or status card. |
| A4 | Create behavior compliance evals for skills, AGENTS rules, and critical gates. | [ECC-SOURCE] ECC-5; [SP-SOURCE] SP-9, SP-10 | SFA cannot currently prove that rules are followed under pressure or after wording changes. | High for harness rule changes; too expensive for every business change. | ADAPT | Define 3-5 SFA behavior scenarios first: confidence leak, skill routing, reviewer read-only, technical-solution stop, no main-branch edit. |
| A5 | Separate script tests from behavior evals. | [SP-SOURCE] SP-10; [ECC-SOURCE] ECC-5 | Current shell gates prove scripts run, not that agents obey workflow rules. | High. | ADOPT PRINCIPLE | Add taxonomy to technical solution: script unit tests, integration smoke, behavior evals, manual review evidence. |
| A6 | Add hook lifecycle contract and profile model. | [ECC-SOURCE] ECC-7, ECC-8; [SP-SOURCE] SP-8 | SFA has adapters and sensor runner, but lifecycle/SessionStart behavior is not represented as a stable contract. | Medium. Hook changes are sensitive and adapter-specific. | PILOT | First document `SessionStart`, `PreToolUse`, `PostToolUse`, `Stop`, `PreCompact` support for Codex/Cursor/OpenCode; no runtime hook changes before confirmed design. |
| A7 | Use SessionStart only for concise routing / stop-point reminders. | [SP-SOURCE] SP-8; [LOCAL-FACT] local diagnosis B1 says SessionStart not wired yet | Could reduce `skill-usage` friction by reminding route rules automatically. | Medium. Useful, but long context injection risks context bloat. | PILOT | Adapter capability matrix, max chars, opt-out, and proof that first-turn context is actually injected. |
| A8 | Standardize agent handoff around task brief, report, review package, and ledger files. | [SP-SOURCE] SP-5, SP-6; [ECC-SOURCE] ECC-9; [LOCAL-FACT] SFA-3, SFA-4, SFA-5 | SFA has scripts but not a fully enforced handoff contract. | High. It strengthens existing local design. | ADAPT | Define required filenames, status fields, review-loop contract, and how `reviewer-gate.sh` consumes them. |
| A9 | Keep reviewers read-only and skeptical of implementer reports. | [SP-SOURCE] SP-6, SP-7; [LOCAL-FACT] AGENTS reviewer rule | Prevents self-grading and branch mutation by reviewer. | Very high. Already aligned with SFA. | ADOPT PRINCIPLE | No implementation needed except making review package / status fields more explicit in technical solution. |
| A10 | Add durable progress ledger as a recovery source after compaction. | [SP-SOURCE] SP-5; [LOCAL-FACT] SFA-3 | Long tasks lose context after compaction and risk duplicated work. | High. Existing `.harness/agent-work/<change-id>/progress-ledger.md` can serve this. | ADAPT | Define ledger update rules and status parser; decide whether ledger remains ignored scratch or summarized into tracked evidence. |
| A11 | Use exact, task-sized implementation plans with no placeholders. | [SP-SOURCE] SP-2 | SFA technical solutions can still be too broad to execute safely. | High. | ADOPT PRINCIPLE | Technical solution template update later; must preserve SFA full-stack surfaces and source attribution. |
| A12 | Keep TDD default for behavior changes, with explicit N/A for docs/config/prototypes. | [SP-SOURCE] SP-3; [LOCAL-FACT] AGENTS Java backend test-plan rule | Prevents code-first behavior changes, but SFA has docs/control-plane and legacy cases. | Medium-high. | ADAPT | Define where TDD is mandatory, where backend test plan supersedes, and what counts as valid N/A evidence. |
| A13 | Strengthen "evidence before completion" language in status/report gates. | [SP-SOURCE] SP-4; [LOCAL-FACT] SFA harness-status / Test Agent rules | Prevents false completion claims from partial checks or agent reports. | Very high. | ADOPT PRINCIPLE | Later technical solution should add exact evidence fields to `harness-status.md`, `ai-test-report.md`, and `review.md`. |
| A14 | Do not make tmux the default SFA orchestration runtime. | [ECC-SOURCE] ECC-9; [LOCAL-FACT] SFA current Codex/Cursor workflow | tmux is useful for ECC workers but may not match Codex Desktop and SFA business workflow. | Low as default; medium as optional helper. | DO_NOT_COPY | If ever needed, design optional sidecar only; no gate should require tmux. |
| A15 | Do not replace SFA harness with ECC plugin / superpowers plugin wholesale. | [FEISHU-RESEARCH]; [LOCAL-FACT] SFA business constraints | Generic harnesses lack SFA repo registry, Feishu PRD, env readiness, DB boundary, and business repo rules. | Not acceptable. | DO_NOT_COPY | Keep OSS as reference snapshots and optional sidecars only. |
| A16 | Add "skill/rule changes require behavior evidence" governance. | [SP-SOURCE] SP-9, SP-10; [ECC-SOURCE] ECC-5 | Skill and AGENTS wording changes shape agent behavior but are currently reviewable as prose only. | High. | ADAPT | Define scope: AGENTS, skills, hooks, gate prompts, reviewer templates. Define minimal accepted evidence. |
| A17 | Build closeout metrics / instinct candidates from sanitized observations. | [ECC-SOURCE] ECC-6; [LOCAL-FACT] local diagnosis P1-2 / B4 | Gate retirement needs examples of repeated mistakes, corrections, and workarounds. | Medium. Sensitive data risk. | PILOT | Only store sanitized summaries: change_id, issue category, correction type, confidence, source artifact. No raw transcript or credentials. |
| A18 | Add hook profiles mapped to risk tiers. | [ECC-SOURCE] ECC-7; [LOCAL-FACT] SFA gate-registry L0-L3 tiers | Current hard-gate default increases friction. | Medium. | PILOT | Start as docs-only profile plan; no runtime switch until hard safety gates are protected. |

## Proposed Evolution Themes

### Theme 1: From Gate List To Control Health

- [AI-INFERENCE] Keep L3 hard safety gates.
- [AI-INFERENCE] Convert L0/L1 process gates into measured evidence where possible.
- [ECC-SOURCE] Use audit categories and skill/gate health trends as the evaluation model.
- [LOCAL-FACT] `gate-registry.md` is the first metadata layer but not yet executable.

### Theme 2: From Manual Tables To Event Evidence

- [LOCAL-FACT] `skill-usage-gate.sh` verifies a manually maintained file.
- [ECC-SOURCE] `skill-evolution/tracker.js` records normalized runtime events.
- [AI-INFERENCE] SFA should pilot event evidence before removing any existing skill-usage requirement.

### Theme 3: From Conversation Memory To File Handoff

- [SP-SOURCE] superpowers requires task briefs, report files, review packages, and durable progress ledgers.
- [LOCAL-FACT] SFA already has `agent-workspace.sh`, `agent-task-brief.sh`, and `agent-review-package.sh`.
- [AI-INFERENCE] The technical solution should make these first-class evidence surfaces for long-running Tier L work.

### Theme 4: From Prose Rules To Behavior Evals

- [SP-SOURCE] superpowers says skill changes require eval evidence.
- [ECC-SOURCE] `skill-comply` provides a concrete compliance measurement model.
- [AI-INFERENCE] SFA should define a small behavior eval suite before changing AGENTS, skills, or hook routing.

### Theme 5: From Generic OSS To SFA-Specific Control Plane

- [FEISHU-RESEARCH] ECC is a reference / optional sidecar, not a replacement control plane.
- [LOCAL-FACT] SFA has business-specific constraints around Feishu PRD, multi-repo registry, SIT/UAT, DB/write boundaries, protected paths, and Chinese review docs.
- [AI-INFERENCE] All adoption must be rebuilt as SFA-native docs/scripts, not copied wholesale.

## Inputs For The Next Technical Solution

The next technical solution should decide:

1. Which Phase 3 pilot comes first: audit scorer, telemetry records, or behavior evals.
2. Which gates remain L3 hard and are explicitly exempt from frequency-based retirement.
3. Whether `skill-usage.md` becomes parallel event evidence first, before any gate change.
4. Whether `harness-state.yml` should become the machine-readable state source for Phase 0/1/2/3, so `harness-status.sh` can display non-business architecture stages accurately.
5. How to sync Feishu child docs and local tracked docs without making Feishu the only source of truth.

## Stop Point

[FACT] This matrix is not an implementation plan. It is evidence input for the later technical solution. No gate, hook, script, template, skill, AGENTS rule, or business repo change is allowed until that technical solution is written and confirmed.
