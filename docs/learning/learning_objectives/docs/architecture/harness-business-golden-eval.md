# Harness Business Golden Eval

> Phase 5 contract for sanitized business golden cases. This layer reuses `scripts/eval-golden.sh`; it does not checkout or modify real business repositories.

```yaml
contract_status: DOCS_AND_LOCAL_RUNNER
runner: scripts/harness-business-golden-eval.sh
test: scripts/harness-business-golden-eval-test.sh
candidate_gate: scripts/harness-business-golden-candidate-gate.sh
candidate_gate_test: scripts/harness-business-golden-candidate-gate-test.sh
candidate_intake: scripts/harness-business-golden-candidate-intake.sh
candidate_intake_test: scripts/harness-business-golden-candidate-intake-test.sh
candidate_report: scripts/harness-business-golden-candidate-report.sh
candidate_report_test: scripts/harness-business-golden-candidate-report-test.sh
seed_cases:
  - fullstack-crud-pass
  - missing-smoke-report-fail
  - allowed-path-violation-fail
  - long-promo-sku-single-pack-unit-pass
  - download-center-export-integration-pass
  - add-distribution-qr-estimated-reward-amount-pass
```

## Purpose

Business Golden Eval checks whether harness artifacts for business-like SFA changes are mechanically gradeable.

It is different from behavior eval:

- behavior eval checks whether an agent obeys harness stop rules;
- business golden eval checks whether a completed business-change package has required artifacts and gates.

## Scope

Current scope is intentionally narrow:

- sanitized fixture roots only;
- no real business repo checkout;
- no DB, Feishu, credential, or production log content;
- one passing fullstack CRUD case;
- one promoted sanitized historical backend case;
- one promoted sanitized historical fullstack Download Center case;
- one promoted sanitized historical fullstack distribution QR estimated reward case;
- two negative calibration cases.

## Case Layout

Cases live under:

```text
evals/business-golden/<case-id>/
```

Each case is a self-contained `SFA_EVAL_ROOT`:

```text
metadata.env
changes/<change-id>/
docs/contracts/<change-id>-api.md
repo/
```

`metadata.env` contains:

```bash
CASE_ID=fullstack-crud-pass
CHANGE_ID=bg-fullstack-crud-pass
EXPECTED_RESULT=PASS
CHANGED_FILES=repo/src/example.java
```

The suite runner delegates each case to:

```bash
SFA_EVAL_ROOT=<case-dir> scripts/eval-golden.sh <change-id> <changed-files...>
```

## Candidate Intake

Historical SFA changes must not be promoted directly into `evals/business-golden/<case-id>/`.

They first enter:

```text
evals/business-golden/candidates/<candidate-id>.env
```

Use the intake helper to create a safe initial candidate record:

```bash
scripts/harness-business-golden-candidate-intake.sh \
  --candidate-id <candidate-id> \
  --source-change-id <change-id> \
  --source-change-path changes/<change-id> \
  --lane backend
```

The intake helper only writes `PROMOTION_STATE=CANDIDATE`,
`REDACTION_STATUS=NEEDS_REVIEW`, `BUSINESS_REPO_ACCESS=NO`, and an empty
`REDACTION_REVIEW_PATH`. It does not read business repositories, does not mark a
candidate sanitized, and does not create or promote a golden case.

Use the report helper to inspect the candidate queue without exposing source
paths:

```bash
scripts/harness-business-golden-candidate-report.sh
```

The report prints candidate counts and the next safe action for each row. It
does not print `SOURCE_CHANGE_PATH`, raw source evidence, business data, or
personal paths.

Candidate metadata contains:

```bash
CANDIDATE_ID=add-distribution-qr-estimated-reward-amount
SOURCE_CHANGE_ID=add-distribution-qr-estimated-reward-amount
SOURCE_CHANGE_PATH=changes/add-distribution-qr-estimated-reward-amount
LANE=fullstack
PROMOTION_STATE=CANDIDATE
REDACTION_STATUS=NEEDS_REVIEW
BUSINESS_REPO_ACCESS=NO
GOLDEN_CASE_ID=
REDACTION_REVIEW_PATH=
```

Promotion states:

| State | Meaning |
| --- | --- |
| `CANDIDATE` | Source change exists, but has not completed redaction / fixture shaping |
| `READY` | Redaction is complete and target `GOLDEN_CASE_ID` is declared |
| `PROMOTED` | Matching `evals/business-golden/<GOLDEN_CASE_ID>/metadata.env` exists |
| `REJECTED` | Candidate is intentionally not used |

Guardrails:

- `SOURCE_CHANGE_PATH` must be repo-relative, never a personal absolute path;
- `SOURCE_CHANGE_PATH` must be a safe `changes/<id>` path without spaces or parent traversal;
- `READY` and `PROMOTED` require `REDACTION_STATUS=SANITIZED`;
- `READY` and `PROMOTED` require `REDACTION_REVIEW_PATH` to point to an existing repo-relative review file;
- redaction review files must include structured table rows for `redaction_status | SANITIZED` and `business_repo_access | NO`, plus an explicit `Approved for PROMOTED candidate state` decision;
- candidate gate output does not print `SOURCE_CHANGE_PATH`; use the candidate report helper for queue-level status;
- `PROMOTED` requires the target golden case fixture to exist;
- candidate gate does not read or modify business repositories.

## Seed Cases

| Case | Expected | Purpose |
| --- | --- | --- |
| `fullstack-crud-pass` | PASS | Minimal complete fullstack CRUD package |
| `long-promo-sku-single-pack-unit-pass` | PASS | Sanitized historical backend package promoted from candidate intake |
| `download-center-export-integration-pass` | PASS | Sanitized historical fullstack Download Center package promoted from candidate intake |
| `add-distribution-qr-estimated-reward-amount-pass` | PASS | Sanitized historical fullstack distribution QR estimated reward package promoted from candidate intake |
| `missing-smoke-report-fail` | FAIL | Missing PC smoke report must fail closed |
| `allowed-path-violation-fail` | FAIL | Changed file outside `allowed_paths` must fail closed |

## Verification

```bash
bash scripts/harness-business-golden-eval-test.sh
scripts/harness-business-golden-eval.sh
bash scripts/harness-business-golden-candidate-gate-test.sh
scripts/harness-business-golden-candidate-gate.sh
bash scripts/harness-business-golden-candidate-intake-test.sh
bash scripts/harness-business-golden-candidate-report-test.sh
```
