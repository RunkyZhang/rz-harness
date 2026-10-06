# Harness Gate Registry

> Phase 1 initial registry for `harness-evolution-architecture`. This file records what the current gates protect, which evidence supports them, and which gates need future measurement before any soften / merge / retirement decision.

## Scope

- [LOCAL-FACT] Registry scope is `scripts/*-gate.sh`, excluding `*-gate-test.sh`.
- [LOCAL-FACT] Baseline date: 2026-07-03.
- [LOCAL-FACT] Current remote tree gate count in scope: 38.
- [LOCAL-FACT] Historical registry baseline previously recorded 39 gates; this is a stale documentation baseline that needs follow-up reconciliation, not a gate model contradiction.
- [USER-DECISION] `docs/harness-diagnosis-and-remediation.md` is a local reference for this audit, but is temporarily not included in version control.
- [AI-INFERENCE] Phase 1 does not approve removing or weakening any gate. It only creates a reviewable baseline and future measurement model.

## Source Tags

| Tag | Meaning in this registry |
| --- | --- |
| `[LOCAL-FACT]` | Current repo files, script names, line counts, `docs/README.md` sensor descriptions, or AGENTS.md workflow rules. |
| `[FEISHU-RESEARCH]` | Feishu ECC research document conclusions about ECC as reference / optional sidecar. |
| `[ECC-SOURCE]` | ECC source snapshot `/tmp/sfa-harness-ref-ecc-2bc924` at `2bc924f`, especially `scripts/harness-audit.js` and `scripts/skills-health.js`. |
| `[SP-SOURCE]` | superpowers source snapshot `/tmp/sfa-harness-ref-superpowers-896224` at `896224c`, especially plan, verification, and worktree skills. |
| `[AI-INFERENCE]` | Engineering classification based on the sources above. Requires confirmation before implementation. |

## Tier Model

| Tier | Meaning | Retirement Rule |
| --- | --- | --- |
| L3 hard safety | Prevents branch damage, data/env leakage, unconfirmed assumptions entering code, unsafe E2E, or false completion claims. | Not frequency-retired. Can only be changed by confirmed design + replacement protection. |
| L2 delivery quality | Protects solution completeness, test strategy, reviewer coverage, architecture boundaries, or UI quality. | Can be consolidated only after equivalent evidence exists for at least one complete trial period. |
| L1 process hygiene | Protects documentation hygiene, knowledge references, optional evidence structure, or workflow bookkeeping. | Candidate for soft evidence, dashboard, or sampled audit after catch / false-positive data exists. |
| L0 optional advisory | Improves analysis quality but should not block normal work when unavailable. | Default non-blocking unless a change explicitly opts in. |

## Registry

| Gate | Stage | Tier | Owner | Current Purpose | Current Evidence | Phase 1 Action |
| --- | --- | --- | --- | --- | --- | --- |
| `adapter-compliance-gate.sh` | control-plane setup | L1 process hygiene | Orchestrator | Checks adapter matrix rows have status, onramp, verification command, risk, owner, date, and source. | [LOCAL-FACT] `docs/README.md` sensor row; 68 lines. | KEEP_MEASURE; later decide whether adapter matrix should be registry-backed. |
| `agent-dispatch-plan-gate.sh` | before Agent dispatch / stage transition | L2 delivery quality | Orchestrator | Validates `agent-dispatch-plan.md` against `config/agent-registry.yml`, including candidate confirmation for implementation agents. | [LOCAL-FACT] `docs/architecture/agent-registry.md`; 39 lines. | KEEP_HARD for candidate implementation dispatch; measure friction after adoption. |
| `agent-output-contract-gate.sh` | after Agent output / before downstream gates | L2 delivery quality | Orchestrator | Checks registry-declared output artifacts exist and delegates Reviewer / Test Agent outputs to their gates. | [LOCAL-FACT] `docs/architecture/agent-registry.md`; 42 lines. | KEEP_HARD for registry-backed Agent workflow. |
| `agent-registry-gate.sh` | Agent registry or adapter change | L1 process hygiene | Orchestrator | Validates `config/agent-registry.yml`, source files, OpenCode markers, Codex contracts, and gate references. | [LOCAL-FACT] `docs/architecture/agent-registry.md`; 7 lines wrapper around registry validator. | KEEP_MEASURE; required while Agent registry is source of truth. |
| `ai-test-plan-gate.sh` | after solution confirmation | L2 delivery quality | Orchestrator / Test Agent | Blocks implementation until AI test plan is confirmed for required scopes. | [LOCAL-FACT] AGENTS.md requires Test Strategy Agent after solution; 117 lines. [SP-SOURCE] mirrors "plan before execution" discipline. | KEEP_HARD during Tier L evolution. |
| `ai-test-report-gate.sh` | before test / pre-release publishing | L2 delivery quality | Orchestrator / Test Agent | Blocks test / pre-release publishing until report is confirmed and recommends next stage. | [LOCAL-FACT] `docs/README.md` sensor row; 113 lines. [SP-SOURCE] supports evidence-before-claims. | KEEP_HARD; future metric should track false positives and missed defects. |
| `architecture-drift-gate.sh` | pre-PR / reviewer | L2 delivery quality | Orchestrator / Reviewer | Detects architecture boundary drift in business diffs. | [LOCAL-FACT] `docs/README.md` sensor row; 169 lines. | KEEP_MEASURE; require examples of true catches before expanding rules. |
| `assumption-leak-gate.sh` | implementation / pre-PR | L3 hard safety | Orchestrator | Prevents `[ASSUMP]` and high-signal assumption markers from entering implementation files. | [LOCAL-FACT] AGENTS.md confidence gate; 191 lines. | KEEP_HARD; aligns with confidence policy. |
| `business-code-start-gate.sh` | before first business-code edit | L3 hard safety | Orchestrator | Blocks business edits unless solution, verification map, contract allowed paths, and safe branch are ready. | [LOCAL-FACT] AGENTS.md code-start rule; 207 lines. | KEEP_HARD; central boundary gate. |
| `business-dirty-worktree-gate.sh` | before touching dirty business repo | L3 hard safety | Orchestrator | Requires ledger for existing dirty diffs to avoid overwriting user work. | [LOCAL-FACT] AGENTS.md dirty worktree policy; 101 lines. | KEEP_HARD; no retirement without equivalent VCS ownership evidence. |
| `harness-business-golden-candidate-gate.sh` | business golden candidate intake | L1 process hygiene | Orchestrator | Validates candidate source paths, redaction status, promotion state, and promoted case links before real historical changes enter business golden evals. | [LOCAL-FACT] `docs/architecture/harness-business-golden-eval.md`; candidate intake gate. | KEEP_MEASURE; required while business golden cases are curated manually from historical changes. |
| `canonical-command-gate.sh` | before recording test evidence | L1 process hygiene | Backend Agent | Blocks known invalid validation commands, especially Maven reactor false failures. | [LOCAL-FACT] `docs/README.md` sensor row; 101 lines. | KEEP_MEASURE; candidate for shared command registry after enough cases. |
| `change-artifacts-gate.sh` | new change scaffold / artifact audit | L1 process hygiene | Orchestrator | Enforces Tier S/M/L artifact profiles and allowed root artifact names for new changes. | [LOCAL-FACT] `docs/architecture/change-artifacts-spec.md`; 213 lines. | KEEP_MEASURE; may later generate allowed artifact names from the spec. |
| `change-stage-gate.sh` | stage transition | L2 delivery quality | Orchestrator | Checks active change stage rules and required artifacts. | [LOCAL-FACT] listed in self-audit required files; 193 lines. | KEEP_MEASURE; should eventually read from a smaller stage contract. |
| `codegraph-evidence-gate.sh` | CodeGraph evidence before review | L0 optional advisory | Orchestrator | Ensures CodeGraph evidence records projectPath, preflight, freshness, and downgrade state; prevents treating misses as no-impact proof. | [LOCAL-FACT] AGENTS.md says CodeGraph optional; 114 lines. | CANDIDATE_SOFTEN; keep non-blocking unless CodeGraph evidence is cited. |
| `confidence-gate.sh` | spec / plan update | L3 hard safety | Orchestrator | Blocks unresolved `[ASSUMP]` / `[QUESTION]` from moving into implementation. | [LOCAL-FACT] AGENTS.md Confidence Gate; 101 lines. | KEEP_HARD; core fact boundary. |
| `contract-delta-gate.sh` | contract or implementation delta | L2 delivery quality | Orchestrator | Requires contract delta record when contract and implementation change. | [LOCAL-FACT] `docs/README.md` sensor row; 85 lines. | KEEP_MEASURE; useful only when contract artifacts are active. |
| `decision-gate.sh` | implementation / merge | L1 process hygiene | Orchestrator | Blocks unresolved pending decisions in `changes/<id>/decisions.md`. | [LOCAL-FACT] `docs/README.md` sensor row; 127 lines. | CANDIDATE_SOFTEN; could become stage-card status if duplicate. |
| `diff-hygiene-gate.sh` | business diff closeout | L3 hard safety | Orchestrator | Blocks unrelated whitespace / formatting noise in business diffs. | [LOCAL-FACT] AGENTS.md pre-merge rule; 152 lines. | KEEP_HARD for business repos; measure false positives. |
| `environment-readiness-gate.sh` | before real E2E or env-dependent tests | L3 hard safety | Orchestrator | Requires env, account source, data, DB/write boundary, rollback, devices/tools, blockers, and no reusable credentials. | [LOCAL-FACT] AGENTS.md env-readiness rule; 294 lines. | KEEP_HARD; highest data / env safety value. |
| `knowledge-reference-gate.sh` | spec references knowledge refs | L1 process hygiene | Orchestrator | Validates referenced knowledge IDs and audits unreferenced knowledge. | [LOCAL-FACT] `docs/README.md` sensor row; 160 lines. | CANDIDATE_SOFTEN; align with future decay dashboard. |
| `local-routing-business-config-gate.sh` | before local PC smoke | L3 hard safety | Frontend Agent | Blocks business frontend proxy / `.env*` edits; requires harness proxy and local routing. | [LOCAL-FACT] AGENTS.md protected behavior; 59 lines. | KEEP_HARD for local routing work. |
| `local-routing-gate.sh` | local frontend to backend routing | L3 hard safety | Orchestrator | Blocks catch-all routes, non-local targets, and routes without contract source. | [LOCAL-FACT] `docs/README.md` sensor row; 32 lines. | KEEP_HARD despite small size; protects routing safety. |
| `local-service-lifecycle` | local integration | L3 hard safety | Orchestrator | Requires restart and web-stack verification evidence before a local backend is declared ready; port or process presence alone is insufficient. | [LOCAL-FACT] AGENTS.md and `docs/onboarding/local-dev-environment.md` lifecycle contract. | KEEP_HARD; prevents false-ready local integration claims. |
| `miniapp-local-env-gate.sh` | miniapp local smoke | L3 hard safety | Frontend Agent | Requires environment override, actual request host, re-entry, and cleanup command. | [LOCAL-FACT] `docs/README.md` sensor row; 103 lines. | KEEP_HARD when miniapp smoke is executed. |
| `parallel-worktree-gate.sh` | before implementation agent dispatch | L3 hard safety | Orchestrator | Ensures implementation agents use isolated worktrees. | [LOCAL-FACT] AGENTS.md subagent policy; 77 lines. [SP-SOURCE] superpowers worktree skill requires isolation detection. | KEEP_HARD for implementation agents. |
| `requirement-intake-gate.sh` | Tier M/L intake completion | L2 delivery quality | Orchestrator | Requires structured PRD intake, key question categories, and no open blocking questions before solution planning. | [LOCAL-FACT] `docs/README.md` sensor row; 108 lines. | KEEP_HARD for Tier M/L intake; measure whether it reduces missed PRD surfaces. |
| `reviewer-gate.sh` | after read-only reviewer | L2 delivery quality | Reviewer Agent | Requires reviewer coverage and high-risk count zero before human review / PR. | [LOCAL-FACT] AGENTS.md reviewer rule; 162 lines. | KEEP_HARD for Tier M/L; future metric should track reviewer findings. |
| `swagger-model-documentation-gate.sh` | pre-commit | L2 delivery quality | Backend Agent / Orchestrator | For active Swagger 2 repo profiles, blocks newly added public response `*VO.java` that omit `@ApiModel` or field-level `@ApiModelProperty`; non-retroactive and excludes export/infrastructure DTOs. | [LOCAL-FACT] `rules/backends/swagger2/manifest.yml`; terminal-wechat-bind-query regression. | KEEP_HARD for opted-in profile; expand only after each repo baseline confirms its Swagger model convention. |
| `retro-gate.sh` | closeout / pre-archive | L1 process hygiene | Orchestrator | Requires Tier M/L retro readiness, metrics, user corrections, and knowledge decisions. | [LOCAL-FACT] `docs/README.md` sensor row; 194 lines. | CANDIDATE_SOFTEN; useful after telemetry can prove learning loop coverage. |
| `skill-usage-gate.sh` | plan / pre-PR | L1 process hygiene | Orchestrator | Requires `skill-usage.md` or N/A to show skill routing happened. | [LOCAL-FACT] AGENTS.md skill routing rule; 46 lines. [FEISHU-RESEARCH] current diagnosis flags skill-usage ledger friction. | CANDIDATE_SOFTEN; likely replace with direct source / hook evidence after design. |
| `superseded-docs-gate.sh` | docs governance | L1 process hygiene | Orchestrator | Ensures legacy root docs have SUPERSEDED banners and point to the active SSOT. | [LOCAL-FACT] `docs/README.md` sensor row; 86 lines. | CANDIDATE_SOFTEN after legacy docs are fully archived. |
| `technical-solution-feishu-sync-gate.sh` | technical solution gate sub-check | L2 delivery quality | Orchestrator | Requires Feishu/Lark PRD technical solution child doc sync metadata to match the local solution. | [LOCAL-FACT] `docs/README.md` sensor row; 151 lines. | KEEP_HARD when PRD source is Feishu/Lark. |
| `technical-solution-gate.sh` | before business-code start | L2 delivery quality | Orchestrator | Requires confirmed full-stack technical solution and allowed next stage. | [LOCAL-FACT] AGENTS.md Tier M/L solution rule; 126 lines. | KEEP_HARD for Tier M/L. |
| `temporary-state-ledger-gate.sh` | after local integration / before report | L3 hard safety | Orchestrator | Ensures local services, storage, test data, QR codes, vConsole, and other temporary states are cleaned or assigned. | [LOCAL-FACT] `docs/README.md` sensor row; 76 lines. | KEEP_HARD when E2E / local integration runs. |
| `test-agent-verification-gate.sh` | after Test Agent verification | L2 delivery quality | Test Agent | Requires Test Agent verification against confirmed AI test plan. | [LOCAL-FACT] AGENTS.md Test Agent rule; 125 lines. [SP-SOURCE] evidence-before-completion supports independent verification. | KEEP_HARD for Tier M/L; future design may merge report metadata only if independent verification remains. |
| `ui-confirmation-gate.sh` | before complex UI pass claim | L2 delivery quality | Frontend Agent | Fails closed until complex UI has confirmation status, runnable prototype / screenshot / URL, and reviewer confirmation. | [LOCAL-FACT] AGENTS.md UI stop point; 85 lines. | KEEP_HARD for complex UI. |
| `ui-rule-gate.sh` | PRD UI / interaction coding | L2 delivery quality | Frontend Agent | Requires UI checklist, PRD UI source, matching rules, and confirmed handling of missing rules. | [LOCAL-FACT] AGENTS.md UI rule; 131 lines. | KEEP_HARD for PRD UI work. |
| `verification-map-gate.sh` | before business-code start | L2 delivery quality | Orchestrator | Maps key constraints to validation commands, confirmations, or N/A reasons. | [LOCAL-FACT] AGENTS.md verification requirement; 139 lines. | KEEP_MEASURE; may consolidate with AI test plan only if traceability survives. |
| `workstream-dispatch-gate.sh` | before multi-repo / full-stack implementation | L2 delivery quality | Orchestrator | Checks workstreams are split and have validation commands. | [LOCAL-FACT] `docs/README.md` sensor row; 110 lines. | KEEP_MEASURE; candidate for status-card schema once stable. |

## Initial Risk Summary

| Bucket | Gates | Phase 1 Meaning |
| --- | --- | --- |
| Keep hard by default | `assumption-leak-gate.sh`, `business-code-start-gate.sh`, `business-dirty-worktree-gate.sh`, `confidence-gate.sh`, `diff-hygiene-gate.sh`, `environment-readiness-gate.sh`, `local-routing-business-config-gate.sh`, `local-routing-gate.sh`, `miniapp-local-env-gate.sh`, `parallel-worktree-gate.sh`, `temporary-state-ledger-gate.sh` | These protect hard safety boundaries. Do not soften without confirmed replacement mechanism. |
| Keep hard for Tier M/L surfaces | `agent-dispatch-plan-gate.sh`, `agent-output-contract-gate.sh`, `ai-test-plan-gate.sh`, `ai-test-report-gate.sh`, `requirement-intake-gate.sh`, `reviewer-gate.sh`, `technical-solution-feishu-sync-gate.sh`, `technical-solution-gate.sh`, `test-agent-verification-gate.sh`, `ui-confirmation-gate.sh`, `ui-rule-gate.sh` | These protect quality and human confirmation stops. Future consolidation cannot remove the underlying stop point. |
| Measure before changing | `adapter-compliance-gate.sh`, `agent-registry-gate.sh`, `architecture-drift-gate.sh`, `canonical-command-gate.sh`, `change-artifacts-gate.sh`, `change-stage-gate.sh`, `contract-delta-gate.sh`, `harness-business-golden-candidate-gate.sh`, `verification-map-gate.sh`, `workstream-dispatch-gate.sh` | Need catch count, false-positive count, and duplicate-signal analysis. |
| Candidate for soft evidence / dashboard | `codegraph-evidence-gate.sh`, `decision-gate.sh`, `knowledge-reference-gate.sh`, `retro-gate.sh`, `skill-usage-gate.sh`, `superseded-docs-gate.sh` | These are useful but may be better represented as indexed evidence, status card fields, or periodic audit. |

## Measurement Model For Phase 3+

[AI-INFERENCE] A gate can only be proposed for soften / merge / retirement after a measurement window records:

- `runs`: how often it is invoked.
- `blocks`: how often it stops execution.
- `true_catches`: confirmed cases where the block prevented a real defect, unsafe change, or wasted validation.
- `false_positives`: confirmed cases where the block slowed correct work.
- `manual_overrides`: cases where the user explicitly accepted risk.
- `duplicate_signal`: whether another artifact or gate already detected the same issue.
- `replacement_protection`: what remains after soften / merge / retirement.

[ECC-SOURCE] ECC `harness-audit.js` uses multiple audit categories such as quality gates, security guardrails, eval coverage, memory persistence, and context efficiency. This registry adapts that idea as explicit gate metadata instead of using a single pass/fail checklist.

[SP-SOURCE] superpowers `verification-before-completion` requires fresh evidence before completion claims, and `writing-plans` requires exact tasks and tests before execution. This registry keeps SFA's stricter gates for Tier M/L work, but marks process-only gates for future simplification when evidence exists.

## Open Items

- [QUESTION] Which gates should record runtime telemetry first: all gates, or only L1 / L2 process gates?
- [QUESTION] Should `docs/README.md` remain the human index while this file becomes the governance registry, or should both be generated from one source?
- [QUESTION] Should Phase 2 create a source-evidence matrix row for every gate, or only for gates proposed for redesign?
