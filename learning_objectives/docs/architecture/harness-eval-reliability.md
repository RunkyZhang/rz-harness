# Harness Eval Reliability

> Phase 5C contract for scoring repeated harness behavior eval runs. This file defines the metric semantics only; it does not claim live-agent reliability.

```yaml
contract_status: DOCS_AND_LOCAL_RUNNER
live_agent_trace_supported: false
default_runs: 3
default_mode: safety
owner: Orchestrator
last_verified: 2026-06-26
```

## 1. Purpose

SFA harness needs different reliability standards for different kinds of evals:

- safety and boundary behavior must be stable across repeated runs;
- exploratory or candidate-generation behavior may be useful when at least one attempt succeeds, but it must not be treated as safety evidence.

Phase 5C adds a local runner around the existing deterministic behavior eval. It is a scoring contract and shell harness, not a live model runner.

## 2. Metrics

| Metric | Meaning | Use |
| --- | --- | --- |
| `pass@k` | At least one of k runs passed. | Exploratory tasks, candidate discovery, non-blocking guidance checks. |
| `pass^k` | All k runs passed. | Safety behavior, hard boundary behavior, reviewer read-only behavior, main-branch and protected-path behavior. |

`pass@k=1` and `pass^k=0` means the eval can succeed, but it is not stable. That result must not be used as evidence for high-risk harness rules.

## 3. Modes

| Mode | Exit 0 when | Failure meaning |
| --- | --- | --- |
| `safety` | `pass^k=1` | At least one run failed, so the behavior is not stable enough for safety evidence. |
| `exploratory` | `pass@k=1` | No run passed. Partial success is allowed, but must report `PASS_POWER_K=0`. |

Default mode is `safety` and default k is 3.

## 4. Current Scope

`scripts/harness-behavior-reliability.sh` repeats a shell eval command and reports:

- `HARNESS_BEHAVIOR_RELIABILITY_RUNS`
- `HARNESS_BEHAVIOR_RELIABILITY_SUCCESSES`
- `HARNESS_BEHAVIOR_RELIABILITY_FAILURES`
- `PASS_AT_K`
- `PASS_POWER_K`
- `DECISION`

The default command is `scripts/harness-behavior-eval.sh`.

## 5. Non Goals

- No live agent trace capture.
- No model routing decision.
- No token or cost attribution.
- No hook runtime integration.
- No raw prompt, transcript, Feishu body, token, cookie, DB password, customer data, or private source text persistence.

## 6. Source Attribution

| Source | Usage |
| --- | --- |
| `[ECC-SOURCE]` behavior compliance / audit scoring | Adapts repeated, structured compliance output into SFA local shell scoring. |
| `[SP-SOURCE]` verification-before-completion | Adapts evidence-before-claim: reliability requires repeated evidence, not a single optimistic pass. |
| `[LOCAL-FACT]` `scripts/harness-behavior-eval.sh` | The first wrapped eval command is the current deterministic five-scenario behavior eval. |
| `[AI-INFERENCE]` safety vs exploratory split | SFA high-risk boundary rules require `pass^k`; low-risk candidate generation may use `pass@k`. |

## 7. Verification

```bash
bash scripts/harness-behavior-reliability-test.sh
scripts/harness-behavior-reliability.sh --runs 3 --mode safety --eval-command 'scripts/harness-behavior-eval.sh'
```
