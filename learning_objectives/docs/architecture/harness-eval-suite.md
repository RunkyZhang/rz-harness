# Harness Eval Suite

> Suite-level runner for the current harness evaluation stack. It orchestrates existing evals and gates; it does not replace their individual contracts.

```yaml
contract_status: DOCS_AND_LOCAL_RUNNER
runner: scripts/harness-eval-suite.sh
test: scripts/harness-eval-suite-test.sh
weekly_runner: scripts/harness-eval-weekly-run.sh
weekly_test: scripts/harness-eval-weekly-run-test.sh
trend_readiness: scripts/harness-eval-trend-readiness.sh
trend_readiness_test: scripts/harness-eval-trend-readiness-test.sh
default_checks: 12
telemetry_event: eval_suite_event
```

## Purpose

`scripts/harness-eval-suite.sh` turns the current eval assets into one repeatable command:

- replay fixture eval;
- live sandbox eval tests;
- live Codex trial wrapper tests;
- business golden eval;
- business golden candidate gate;
- business golden candidate intake test;
- business golden candidate report test;
- static behavior eval;
- behavior reliability wrapper;
- telemetry test;
- registry audit;
- hygiene scan.

The suite prints stable top-level metrics such as `EVAL_SUITE_TOTAL`, `EVAL_SUITE_PASSED`, `BUSINESS_GOLDEN_TOTAL`, `REPLAY_FIXTURE_MATCHED`, `PASS_POWER_K`, and `DECISION`.

Use `--record-telemetry` to write one local aggregate `eval_suite_event`.
The event records suite counts and selected child metrics only; it does not
store raw command output, prompts, transcripts, or business data. Use
`--telemetry-dir <dir>` in tests or rehearsals to keep output isolated from the
default ignored telemetry scratch path.

`scripts/harness-eval-weekly-run.sh` is the local weekly collection entrypoint.
It runs the default suite with `--record-telemetry`, then writes an
aggregate-only weekly audit summary. The summary contains counts and trend
tables, not raw prompts, transcripts, command output, credentials, or business
data. `--suite-root <repo-root>` exists for isolated runner tests and should
normally be left at the harness repository root.

`scripts/harness-eval-trend-readiness.sh` reads local `eval_suite_event`
history and checks whether the trend window is stable enough to write a CI
trial or gate-adjustment review proposal. Defaults require at least 4 suite
runs across 4 weeks, no failed suite runs, `BUSINESS_GOLDEN_TOTAL >= 6`,
`REPLAY_FIXTURE_TOTAL >= 8`, and `PASS_POWER_K >= 1`. Passing this readiness
check is not permission to change CI, gates, hooks, models, or business
repositories.

## Boundary

- The default suite does not run real business repositories.
- The default suite does not run real SIT/UAT/prod E2E.
- Live Codex coverage is limited to the wrapper test by default; real `codex exec` trials remain explicit scenario commands.
- A suite pass means harness eval assets are internally consistent. It does not prove production business behavior.

## Verification

```bash
bash scripts/harness-eval-suite-test.sh
bash scripts/harness-eval-weekly-run-test.sh
bash scripts/harness-eval-trend-readiness-test.sh
scripts/harness-eval-suite.sh
scripts/harness-eval-suite.sh --record-telemetry
scripts/harness-eval-weekly-run.sh
scripts/harness-eval-trend-readiness.sh
```
