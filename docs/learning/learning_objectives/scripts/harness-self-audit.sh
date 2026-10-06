#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

required=(
  AGENTS.md
  README.md
  docs/README.md
  docs/architecture/repo-registry.md
  docs/architecture/agent-registry.md
  docs/architecture/changes-retention-policy.md
  docs/architecture/change-artifacts-spec.md
  docs/architecture/adapter-compliance.md
  docs/architecture/ecc-integration.md
  docs/archive/README.md
  docs/domain-glossary.md
  docs/skills-routing.md
  docs/pitfalls/README.md
  docs/pitfalls/TEMPLATE.md
  docs/pitfalls/SFA-PIT-001-map-system-node-sass-runtime.md
  docs/pitfalls/SFA-PIT-002-map-system-login-product-group.md
  docs/pitfalls/SFA-PIT-003-map-system-temporary-route.md
  docs/pitfalls/SFA-PIT-004-codegraph-route-query.md
  docs/samples/README.md
  docs/samples/TEMPLATE.md
  docs/decision-log/2026-05-29-knowledge-lifecycle.md
  docs/standards/java/README.md
  docs/standards/java/alibaba-java-review-checklist.md
  docs/standards/java/alibaba-java-songshan-fulltext.txt
  docs/baseline/frontend-merchant-wechatapp.md
  templates/spec-tier-s.md
  templates/spec-tier-m.md
  templates/spec-tier-l.md
  templates/requirement-intake.md
  templates/frontend-style-profile.md
  templates/plan-tier-m.md
  templates/harness-status.md
  templates/harness-state.yml
  templates/technical-solution.md
  templates/verification-map.md
  templates/retro.md
  templates/ai-test-report.md
  templates/miniapp-local-env.md
  templates/temporary-state-ledger.md
  templates/codegraph-evidence.md
  templates/dirty-worktree-ledger.md
  templates/review.md
  templates/pre-pr-review.md
  templates/decisions.md
  templates/api-contract.md
  templates/codex-agent.toml
  templates/agent-candidate-confirmation.md
  templates/local-backend-services.yml
  templates/local-routing.yml
  templates/skill-usage.md
  templates/pc-e2e-smoke-plan.md
  templates/pc-e2e-smoke-report.md
  rules/backend-java.mdc
  rules/frontend-vue2.mdc
  rules/frontend-wechat-miniprogram.mdc
  rules/mobile-ios-objc.mdc
  rules/mobile-android-java.mdc
  lanes/fullstack-crud.md
  lanes/bugfix-fast.md
  lanes/pc-e2e-smoke.md
  skills/explorer/SKILL.md
  skills/reviewer/SKILL.md
  skills/grill/SKILL.md
  skills/diagnose/SKILL.md
  skills/tdd/SKILL.md
  skills/handoff/SKILL.md
  skills/third-party/mattpocock-skills.md
  skills/third-party/external-codex-skills.md
  skills/third-party/ecc-skills.md
  evals/harness-config-quality/scenario.json
  evals/harness-config-quality/verifier-result.json
  scripts/confidence-gate.sh
  scripts/requirement-intake-gate.sh
  scripts/requirement-intake-gate-test.sh
  scripts/frontend-style-profile-gate-test.sh
  scripts/technical-solution-gate.sh
  scripts/technical-solution-feishu-sync.sh
  scripts/technical-solution-feishu-sync-gate.sh
  scripts/technical-solution-feishu-sync-test.sh
  scripts/verification-map-gate.sh
  scripts/verification-map-gate-test.sh
  scripts/verification-run.sh
  scripts/verification-run-test.sh
  scripts/ai-test-report-gate.sh
  scripts/retro-gate.sh
  scripts/retro-gate-test.sh
  scripts/reviewer-gate.sh
  scripts/business-code-start-gate.sh
  scripts/business-dirty-worktree-gate.sh
  scripts/workstream-dispatch-gate.sh
  scripts/harness-status.sh
  scripts/change-scaffold.sh
  scripts/change-artifacts-gate.sh
  scripts/change-artifacts-gate-test.sh
  scripts/superseded-docs-gate.sh
  scripts/superseded-docs-gate-test.sh
  scripts/agent-workspace.sh
  scripts/agent-task-brief.sh
  scripts/agent-review-package.sh
  scripts/harness-bootstrap-smoke.sh
  scripts/agent-handoff-workflow-test.sh
  scripts/change-stage-gate.sh
  scripts/change-stage-gate-test.sh
  scripts/harness-observability-ready.sh
  scripts/adapter-compliance-gate.sh
  scripts/agent-registry-gate.sh
  scripts/agent-registry-gate-test.sh
  scripts/codex-agent-generator.sh
  scripts/codex-agent-generator-test.sh
  scripts/agent-dispatch-plan.sh
  scripts/agent-dispatch-plan-test.sh
  scripts/agent-dispatch-plan-gate.sh
  scripts/agent-dispatch-plan-gate-test.sh
  scripts/agent-output-contract-gate.sh
  scripts/agent-output-contract-gate-test.sh
  scripts/no-personal-paths.sh
  scripts/lib/agent-registry.mjs
  scripts/lib/tempfiles.sh
  scripts/ecc/ecc-sidecar.sh
  scripts/ecc/ecc-sidecar-test.sh
  scripts/ui-confirmation-gate.sh
  scripts/ui-screen-breakdown-gate-test.sh
  scripts/harness-ux-gates-test.sh
	  scripts/assumption-leak-gate.sh
	  scripts/contract-delta-gate.sh
  scripts/java-mechanical-quality.sh
  scripts/diff-hygiene-gate.sh
  scripts/mobile-mechanical-quality.sh
  scripts/architecture-drift-gate.sh
  scripts/temp-hardcode-scan.sh
  scripts/knowledge-reference-gate.sh
  scripts/knowledge-lint.sh
  scripts/decision-gate.sh
  scripts/allowed-paths.sh
  scripts/parallel-worktree-gate.sh
  scripts/mvn-targeted-test.sh
  scripts/canonical-command-gate.sh
  scripts/frontend-lint-build.sh
  scripts/frontend-dev-server.sh
  scripts/gitnexus-impact.sh
  scripts/gitnexus-detect-changes.sh
  scripts/harness-gc-test.sh
  scripts/codegraph-preflight.sh
  scripts/codegraph-evidence-gate.sh
  scripts/skill-usage-gate.sh
  scripts/generate-local-routing.sh
  scripts/generate-local-routing.mjs
  scripts/generate-opencode-local-config.sh
  scripts/local-routing-gate.sh
  scripts/local-routing-business-config-gate.sh
  scripts/miniapp-local-env-gate.sh
  scripts/temporary-state-ledger-gate.sh
  scripts/harness-local-proxy.mjs
  scripts/business-repo-bootstrap.sh
  scripts/business-repo-bootstrap-test.sh
  scripts/harness-sensor-runner.sh
  scripts/harness-sensor-runner-test.sh
  scripts/team-rollout-preflight.sh
	  scripts/dev-env-check.sh
	  scripts/eval-golden.sh
	  scripts/harness-team-readiness-test.sh
  hooks/cursor-before-shell-execution.sh
  hooks/cursor-after-file-edit.sh
  hooks/codex-pre-tool-use.sh
  hooks/codex-post-tool-use.sh
  .cursor/hooks.json
  .cursor/rules/sfa-harness-core.mdc
  .cursor/rules/sfa-backend-java.mdc
  .cursor/rules/sfa-frontend-vue2.mdc
  .codex/hooks.json
  .codex/config.toml
  opencode.json
  .opencode/agents/sfa-harness-explorer.md
  .opencode/agents/sfa-harness-reviewer.md
)

missing=()
for path in "${required[@]}"; do
  [[ -f "$path" ]] || missing+=("$path")
done

if [[ "${#missing[@]}" -gt 0 ]]; then
  printf 'FAIL: missing required harness files:\n' >&2
  printf ' - %s\n' "${missing[@]}" >&2
  exit 1
fi

ag_lines="$(wc -l < AGENTS.md | tr -d ' ')"
[[ "$ag_lines" -le 100 ]] || fail "AGENTS.md must stay <= 100 lines; current=$ag_lines"

for rule in rules/*.mdc; do
  grep -q '^globs:' "$rule" || fail "missing globs in $rule"
  grep -q '^alwaysApply:' "$rule" || fail "missing alwaysApply in $rule"
done

scripts/harness-gc-test.sh
scripts/change-artifacts-gate-test.sh
scripts/superseded-docs-gate-test.sh
scripts/requirement-intake-gate-test.sh
scripts/frontend-style-profile-gate-test.sh
scripts/technical-solution-feishu-sync-test.sh
scripts/ui-screen-breakdown-gate-test.sh
scripts/verification-run-test.sh
scripts/retro-gate-test.sh
scripts/agent-handoff-workflow-test.sh
scripts/business-repo-bootstrap-test.sh
scripts/harness-sensor-runner-test.sh
scripts/change-stage-gate-test.sh
scripts/agent-registry-gate-test.sh
scripts/codex-agent-generator-test.sh
scripts/agent-dispatch-plan-test.sh
scripts/agent-dispatch-plan-gate-test.sh
scripts/agent-output-contract-gate-test.sh

grep -q 'templates/local-routing.yml' docs/README.md || fail "docs index must list local routing template"
grep -q 'architecture/agent-registry.md' docs/README.md || fail "docs index must list agent registry doc"
grep -q 'templates/codex-agent.toml' docs/README.md || fail "docs index must list Codex agent template"
grep -q 'templates/agent-candidate-confirmation.md' docs/README.md || fail "docs index must list agent candidate confirmation template"
grep -q 'scripts/agent-registry-gate.sh' docs/README.md || fail "docs index must list agent registry gate"
grep -q 'scripts/agent-registry-gate-test.sh' docs/README.md || fail "docs index must list agent registry gate test"
grep -q 'scripts/codex-agent-generator.sh' docs/README.md || fail "docs index must list Codex agent generator"
grep -q 'scripts/codex-agent-generator-test.sh' docs/README.md || fail "docs index must list Codex agent generator test"
grep -q 'scripts/agent-dispatch-plan.sh' docs/README.md || fail "docs index must list agent dispatch planner"
grep -q 'scripts/agent-dispatch-plan-test.sh' docs/README.md || fail "docs index must list agent dispatch planner test"
grep -q 'scripts/agent-dispatch-plan-gate.sh' docs/README.md || fail "docs index must list agent dispatch plan gate"
grep -q 'scripts/agent-dispatch-plan-gate-test.sh' docs/README.md || fail "docs index must list agent dispatch plan gate test"
grep -q 'scripts/agent-output-contract-gate.sh' docs/README.md || fail "docs index must list agent output contract gate"
grep -q 'scripts/agent-output-contract-gate-test.sh' docs/README.md || fail "docs index must list agent output contract gate test"
grep -q 'agent-dispatch-plan.md' docs/architecture/change-artifacts-spec.md || fail "change artifact spec must list agent dispatch plan"
grep -q 'agent-candidate-confirmation.md' docs/architecture/change-artifacts-spec.md || fail "change artifact spec must list agent candidate confirmation"
grep -q -- '--candidate-confirmation' scripts/agent-dispatch-plan.sh || fail "agent dispatch planner must expose candidate confirmation flag"
grep -q 'candidate confirmation' scripts/lib/agent-registry.mjs || fail "agent registry lib must validate candidate confirmation"
grep -q -- '--candidate-confirmation' docs/onboarding.md || fail "onboarding must document candidate confirmation"
grep -q 'agent-candidate-confirmation.md' templates/plan-tier-m.md || fail "Tier M plan must document candidate confirmation"
grep -q 'agent-dispatch-plan.sh' scripts/change-scaffold.sh || fail "change scaffold must generate agent dispatch plan for Tier M/L"
grep -q 'agent-dispatch-plan-gate.sh' scripts/change-stage-gate.sh || fail "change stage gate must consume agent dispatch plan gate"
grep -q 'agent-output-contract-gate.sh' scripts/change-stage-gate.sh || fail "change stage gate must consume agent output contract gate"
grep -q 'architecture/change-artifacts-spec.md' docs/README.md || fail "docs index must list change artifacts spec"
grep -q 'architecture/adapter-compliance.md' docs/README.md || fail "docs index must list adapter compliance matrix"
grep -q 'architecture/ecc-integration.md' docs/README.md || fail "docs index must list ECC integration doc"
grep -q 'templates/harness-status.md' docs/README.md || fail "docs index must list harness status template"
grep -q 'templates/requirement-intake.md' docs/README.md || fail "docs index must list requirement intake template"
grep -q 'templates/frontend-style-profile.md' docs/README.md || fail "docs index must list frontend style profile template"
grep -q 'templates/ai-test-report.md' docs/README.md || fail "docs index must list AI test report template"
grep -q 'scripts/requirement-intake-gate.sh' docs/README.md || fail "docs index must list requirement intake gate"
grep -q 'scripts/requirement-intake-gate-test.sh' docs/README.md || fail "docs index must list requirement intake gate test"
grep -q 'scripts/frontend-style-profile-gate-test.sh' docs/README.md || fail "docs index must list frontend style profile gate test"
grep -q 'style_conformance' docs/README.md || fail "docs index must mention style_conformance"
grep -q 'scripts/technical-solution-gate.sh' docs/README.md || fail "docs index must list technical solution gate"
grep -q 'scripts/technical-solution-feishu-sync.sh' docs/README.md || fail "docs index must list technical solution Feishu sync helper"
grep -q 'scripts/technical-solution-feishu-sync-gate.sh' docs/README.md || fail "docs index must list technical solution Feishu sync gate"
grep -q 'scripts/technical-solution-feishu-sync-test.sh' docs/README.md || fail "docs index must list technical solution Feishu sync test"
grep -q 'templates/verification-map.md' docs/README.md || fail "docs index must list verification map template"
grep -q 'templates/miniapp-local-env.md' docs/README.md || fail "docs index must list miniapp local env template"
grep -q 'templates/temporary-state-ledger.md' docs/README.md || fail "docs index must list temporary state ledger template"
grep -q 'templates/codegraph-evidence.md' docs/README.md || fail "docs index must list CodeGraph evidence template"
grep -q 'templates/dirty-worktree-ledger.md' docs/README.md || fail "docs index must list dirty worktree ledger template"
grep -q 'scripts/verification-map-gate.sh' docs/README.md || fail "docs index must list verification map gate"
grep -q 'scripts/verification-run.sh' docs/README.md || fail "docs index must list verification run"
grep -q 'scripts/verification-run-test.sh' docs/README.md || fail "docs index must list verification run test"
grep -q 'scripts/business-code-start-gate.sh' docs/README.md || fail "docs index must list business code start gate"
grep -q 'scripts/business-dirty-worktree-gate.sh' docs/README.md || fail "docs index must list dirty worktree gate"
grep -q 'scripts/workstream-dispatch-gate.sh' docs/README.md || fail "docs index must list workstream dispatch gate"
grep -q 'scripts/ai-test-report-gate.sh' docs/README.md || fail "docs index must list AI test report gate"
grep -q 'templates/retro.md' docs/README.md || fail "docs index must list retro template"
grep -q 'scripts/retro-gate.sh' docs/README.md || fail "docs index must list retro gate"
grep -q 'scripts/retro-gate-test.sh' docs/README.md || fail "docs index must list retro gate test"
grep -q 'retro-gate.sh' scripts/change-stage-gate.sh || fail "closeout stage must run retro gate"
grep -q 'scripts/ui-confirmation-gate.sh' docs/README.md || fail "docs index must list UI confirmation gate"
grep -q 'scripts/ui-screen-breakdown-gate-test.sh' docs/README.md || fail "docs index must list UI screen breakdown gate test"
grep -q 'scripts/harness-status.sh' docs/README.md || fail "docs index must list harness status script"
grep -q 'scripts/change-scaffold.sh' docs/README.md || fail "docs index must list change scaffold script"
grep -q 'scripts/change-artifacts-gate.sh' docs/README.md || fail "docs index must list change artifacts gate"
grep -q 'scripts/change-artifacts-gate-test.sh' docs/README.md || fail "docs index must list change artifacts gate test"
grep -q 'scripts/superseded-docs-gate.sh' docs/README.md || fail "docs index must list superseded docs gate"
grep -q 'scripts/superseded-docs-gate-test.sh' docs/README.md || fail "docs index must list superseded docs gate test"
grep -q 'scripts/agent-workspace.sh' docs/README.md || fail "docs index must list agent workspace script"
grep -q 'scripts/agent-task-brief.sh' docs/README.md || fail "docs index must list agent task brief script"
grep -q 'scripts/agent-review-package.sh' docs/README.md || fail "docs index must list agent review package script"
grep -q 'scripts/harness-bootstrap-smoke.sh' docs/README.md || fail "docs index must list bootstrap smoke script"
grep -q 'scripts/agent-handoff-workflow-test.sh' docs/README.md || fail "docs index must list agent handoff workflow test"
grep -q 'scripts/harness-observability-ready.sh' docs/README.md || fail "docs index must list harness observability readiness script"
grep -q 'scripts/adapter-compliance-gate.sh' docs/README.md || fail "docs index must list adapter compliance gate"
grep -q 'scripts/no-personal-paths.sh' docs/README.md || fail "docs index must list no personal paths gate"
grep -q 'scripts/ecc/ecc-sidecar.sh' docs/README.md || fail "docs index must list ECC sidecar wrapper"
grep -q 'templates/local-backend-services.yml' docs/README.md || fail "docs index must list local backend services template"
grep -q 'scripts/generate-local-routing.sh' docs/README.md || fail "docs index must list local routing generator"
grep -q 'scripts/local-routing-gate.sh' docs/README.md || fail "docs index must list local routing gate"
grep -q 'scripts/local-routing-business-config-gate.sh' docs/README.md || fail "docs index must list local routing business config gate"
grep -q 'scripts/miniapp-local-env-gate.sh' docs/README.md || fail "docs index must list miniapp local env gate"
grep -q 'scripts/temporary-state-ledger-gate.sh' docs/README.md || fail "docs index must list temporary state ledger gate"
grep -q 'local-routing.yml' lanes/pc-e2e-smoke.md || fail "pc e2e lane must mention local routing"
grep -q 'local-routing.yml' templates/pc-e2e-smoke-plan.md || fail "pc e2e plan template must mention local routing"
grep -q '本地代理命中' templates/pc-e2e-smoke-report.md || fail "pc e2e report template must include proxy hit summary"
grep -q 'scripts/business-repo-bootstrap.sh' docs/README.md || fail "docs index must list business repo bootstrap"
grep -q 'scripts/business-repo-bootstrap-test.sh' docs/README.md || fail "docs index must list business repo bootstrap test"
grep -q 'scripts/harness-sensor-runner.sh' docs/README.md || fail "docs index must list harness sensor runner"
grep -q 'scripts/harness-sensor-runner-test.sh' docs/README.md || fail "docs index must list harness sensor runner test"
grep -q 'scripts/frontend-dev-server.sh' docs/README.md || fail "docs index must list frontend dev server helper"
grep -q 'scripts/canonical-command-gate.sh' docs/README.md || fail "docs index must list canonical command gate"
grep -q 'scripts/codegraph-evidence-gate.sh' docs/README.md || fail "docs index must list CodeGraph evidence gate"
grep -q 'SFA-PIT-001' docs/README.md || fail "docs index must list mapSystem Node runtime pitfall"
grep -q 'SFA-PIT-002' docs/README.md || fail "docs index must list mapSystem login product group pitfall"
grep -q 'SFA-PIT-003' docs/README.md || fail "docs index must list mapSystem temporary route pitfall"
grep -q 'SFA-PIT-004' docs/README.md || fail "docs index must list CodeGraph route query pitfall"
grep -q 'SFA-PIT-001' docs/pitfalls/README.md || fail "pitfalls index must list SFA-PIT-001"
grep -q 'SFA-PIT-002' docs/pitfalls/README.md || fail "pitfalls index must list SFA-PIT-002"
grep -q 'SFA-PIT-003' docs/pitfalls/README.md || fail "pitfalls index must list SFA-PIT-003"
grep -q 'SFA-PIT-004' docs/pitfalls/README.md || fail "pitfalls index must list SFA-PIT-004"
grep -q 'Node `14.21.3`' docs/baseline/frontend-map-system.md || fail "mapSystem baseline must mention Node 14.21.3"
grep -q 'frontend-merchant-wechatapp' docs/architecture/repo-registry.md || fail "repo registry must include merchant wechatapp"
grep -q 'backend-ceo-member' docs/architecture/repo-registry.md || fail "repo registry must include backend ceo member"
grep -q 'mobile-sfa-ios' docs/architecture/repo-registry.md || fail "repo registry must include iOS app repo"
grep -q 'mobile-sfa-android' docs/architecture/repo-registry.md || fail "repo registry must include Android app repo"
grep -q 'SFA_REPO_FRONTEND_MERCHANT_WECHATAPP' config/repos.local.example.sh || fail "local repo example must configure merchant wechatapp"
grep -q 'SFA_REPO_BACKEND_CEO_MEMBER' config/repos.local.example.sh || fail "local repo example must configure backend ceo member"
grep -q 'SFA_REPO_MOBILE_SFA_IOS' config/repos.local.example.sh || fail "local repo example must configure iOS app repo"
grep -q 'SFA_REPO_MOBILE_SFA_ANDROID' config/repos.local.example.sh || fail "local repo example must configure Android app repo"
grep -q 'SFA_REPO_FRONTEND_MERCHANT_WECHATAPP' scripts/dev-env-check.sh || fail "dev env check must inspect merchant wechatapp"
grep -q 'SFA_REPO_BACKEND_CEO_MEMBER' scripts/dev-env-check.sh || fail "dev env check must inspect backend ceo member"
grep -q 'SFA_REPO_MOBILE_SFA_IOS' scripts/dev-env-check.sh || fail "dev env check must inspect iOS app repo"
grep -q 'SFA_REPO_MOBILE_SFA_ANDROID' scripts/dev-env-check.sh || fail "dev env check must inspect Android app repo"
grep -q 'frontend-wechat-miniprogram.mdc' docs/README.md || fail "docs index must list wechat miniprogram frontend rule"
grep -q 'backend-ceo-member.md' docs/README.md || fail "docs index must list backend ceo member baseline"
grep -q 'mobile-ios-objc.mdc' docs/README.md || fail "docs index must list iOS mobile rule"
grep -q 'mobile-android-java.mdc' docs/README.md || fail "docs index must list Android mobile rule"
grep -q 'merchant-wechatapp' docs/onboarding.md || fail "onboarding must mention merchant wechatapp"
grep -q 'SFA_REPO_BACKEND_CEO_MEMBER' docs/onboarding.md || fail "onboarding must mention backend ceo member"
grep -q 'SFA_REPO_MOBILE_SFA_IOS' docs/onboarding.md || fail "onboarding must mention iOS app repo"
grep -q 'SFA_REPO_MOBILE_SFA_ANDROID' docs/onboarding.md || fail "onboarding must mention Android app repo"
grep -q 'Node.*>=18.18.0' docs/baseline/frontend-merchant-wechatapp.md || fail "merchant wechatapp baseline must mention Node >=18.18.0"
grep -q 'project.config.json' rules/frontend-wechat-miniprogram.mdc || fail "wechat miniprogram rule must protect project config"
grep -q 'miniprogram/config/env.ts' rules/frontend-wechat-miniprogram.mdc || fail "wechat miniprogram rule must protect env config"
grep -q 'scripts/mobile-mechanical-quality.sh' docs/README.md || fail "docs index must list mobile mechanical quality gate"
grep -q 'scripts/architecture-drift-gate.sh' docs/README.md || fail "docs index must list architecture drift gate"
grep -q 'scripts/mobile-mechanical-quality.sh' rules/mobile-ios-objc.mdc || fail "iOS rule must require mobile mechanical quality gate"
grep -q 'scripts/architecture-drift-gate.sh' rules/mobile-ios-objc.mdc || fail "iOS rule must require architecture drift gate"
grep -q 'scripts/mobile-mechanical-quality.sh' rules/mobile-android-java.mdc || fail "Android rule must require mobile mechanical quality gate"
grep -q 'scripts/architecture-drift-gate.sh' rules/mobile-android-java.mdc || fail "Android rule must require architecture drift gate"
grep -q 'rules/mobile-ios-objc.mdc' docs/baseline/mobile-sfa-ios.md || fail "iOS baseline must point to mobile iOS rule"
grep -q 'rules/mobile-android-java.mdc' docs/baseline/mobile-sfa-android.md || fail "Android baseline must point to mobile Android rule"
grep -q 'architecture-drift-gate.sh' templates/pre-pr-review.md || fail "pre-pr template must require architecture drift gate"
grep -q 'mobile-mechanical-quality.sh' templates/pre-pr-review.md || fail "pre-pr template must require mobile mechanical quality gate"
grep -q 'organizationFor123' templates/pc-e2e-smoke-plan.md || fail "pc e2e plan must check mapSystem product group loading"
grep -q '临时路由' docs/baseline/frontend-map-system.md || fail "mapSystem baseline must mention temporary route requirement"
grep -q 'HomeIndex' templates/pc-e2e-smoke-plan.md || fail "pc e2e plan must check mapSystem route does not jump HomeIndex"
grep -q '临时路由' templates/pc-e2e-smoke-report.md || fail "pc e2e report must include mapSystem temporary route row"
grep -q '临时路由菜单' templates/pre-pr-review.md || fail "pre-pr template must require mapSystem temporary route evidence"
grep -q '不得新增顶层 `openspec/`' rules/backend-java.mdc || fail "backend rules must block new top-level openspec by default"
if [[ -d openspec ]] && find openspec -type f | grep -q .; then
  fail "top-level openspec directory must not contain files"
fi
grep -q 'GitNexus' templates/pre-pr-review.md || fail "pre-pr template must include GitNexus evidence"
grep -q 'docs/skills-routing.md' AGENTS.md || fail "AGENTS must require harness skills routing"
grep -q 'skill-usage.md' AGENTS.md || fail "AGENTS must require skill usage record"
grep -q 'skills/grill/SKILL.md' docs/skills-routing.md || fail "skills routing must include grill"
grep -q 'skills/explorer/SKILL.md' docs/skills-routing.md || fail "skills routing must include explorer"
grep -q 'skills/diagnose/SKILL.md' docs/skills-routing.md || fail "skills routing must include diagnose"
grep -q 'skills/tdd/SKILL.md' docs/skills-routing.md || fail "skills routing must include tdd"
grep -q 'skills/reviewer/SKILL.md' docs/skills-routing.md || fail "skills routing must include reviewer"
grep -q 'skills/handoff/SKILL.md' docs/skills-routing.md || fail "skills routing must include handoff"
grep -q 'external-codex-skills.md' docs/skills-routing.md || fail "skills routing must include external Codex lens boundary"
grep -q 'ecc-skills.md' docs/skills-routing.md || fail "skills routing must include ECC sidecar lens boundary"
grep -q 'skill-usage-gate.sh changes/<change-id>' templates/pre-pr-review.md || fail "pre-pr template must require skill usage gate"
grep -q 'reviewer-gate.sh changes/<change-id>' templates/pre-pr-review.md || fail "pre-pr template must require reviewer gate"
grep -q 'technical_solution_alignment' templates/pre-pr-review.md || fail "pre-pr template must require technical solution alignment review field"
grep -q 'brooks-sweep' templates/pre-pr-review.md || fail "pre-pr template must explicitly forbid brooks-sweep"
grep -q 'technical_solution_alignment' skills/reviewer/SKILL.md || fail "reviewer skill must output technical solution alignment"
grep -q 'maintainability_readability' skills/reviewer/SKILL.md || fail "reviewer skill must output maintainability/readability status"
grep -q 'scripts/reviewer-gate.sh changes/<change-id>' skills/reviewer/SKILL.md || fail "reviewer skill must require reviewer gate"
grep -q 'external-codex-skills.md' skills/reviewer/SKILL.md || fail "reviewer skill must read external Codex lens boundary when relevant"
grep -q 'brooks-sweep' skills/reviewer/SKILL.md || fail "reviewer skill must forbid brooks-sweep"
grep -q '不得预设 Reviewer 结论' skills/reviewer/SKILL.md || fail "reviewer skill must forbid orchestrator pre-judging reviewer findings"
grep -q '不要报' skills/reviewer/SKILL.md || fail "reviewer skill must name pre-judging phrases"
grep -q 'brooks-review' templates/skill-usage.md || fail "skill usage template must record Brooks lens status"
grep -q 'ECC sidecar' templates/skill-usage.md || fail "skill usage template must record ECC sidecar lens status"
grep -q 'brooks-sweep' skills/third-party/external-codex-skills.md || fail "external Codex skills boundary must forbid brooks-sweep"
grep -q 'ECC 缺失时不得阻断普通 harness 使用' skills/third-party/ecc-skills.md || fail "ECC skills boundary must keep ECC optional"
grep -q 'docs/skills-routing.md' templates/plan-tier-m.md || fail "plan template must require skills routing"
grep -q 'reviewer-gate.sh changes/<change-id>' templates/plan-tier-m.md || fail "plan template must require reviewer gate"
grep -q '## Global Constraints' templates/plan-tier-m.md || fail "plan template must include Global Constraints"
grep -q '\*\*Interfaces:\*\*' templates/plan-tier-m.md || fail "plan template must include per-task Interfaces"
grep -q '独立验证' templates/plan-tier-m.md || fail "plan template must require per-task independent verification"
grep -q 'agent-task-brief.sh' templates/plan-tier-m.md || fail "plan template must mention agent task brief handoff"
grep -q 'agent-review-package.sh' templates/plan-tier-m.md || fail "plan template must mention agent review package handoff"
grep -q 'code-comment-log-quality.sh' templates/pre-pr-review.md || fail "pre-pr template must require code comment/log quality gate"
grep -q 'diff-hygiene-gate.sh' templates/pre-pr-review.md || fail "pre-pr template must require diff hygiene gate"
grep -q 'technical-solution-gate.sh' AGENTS.md || fail "AGENTS must require technical solution gate"
grep -q 'reviewer-gate.sh' AGENTS.md || fail "AGENTS must require reviewer gate after implementation"
grep -q '本次 harness 流程和停止点' templates/spec-tier-m.md || fail "Tier M spec template must include workflow stop points"
grep -q '本次 harness 流程和停止点' templates/spec-tier-l.md || fail "Tier L spec template must include workflow stop points"
grep -q 'harness-status.md' templates/spec-tier-m.md || fail "Tier M spec template must include harness status"
grep -q 'harness-status.md' templates/spec-tier-l.md || fail "Tier L spec template must include harness status"
grep -q 'Workstream Dispatch' templates/harness-status.md || fail "harness status template must include Workstream Dispatch"
grep -q 'verification-map.md' templates/spec-tier-m.md || fail "Tier M spec template must include verification map"
grep -q 'verification-map.md' templates/spec-tier-l.md || fail "Tier L spec template must include verification map"
grep -q 'verification-map-gate.sh' templates/plan-tier-m.md || fail "plan template must require verification map gate"
grep -q 'business-code-start-gate.sh' templates/plan-tier-m.md || fail "plan template must require business code start gate"
grep -q 'business-dirty-worktree-gate.sh' templates/plan-tier-m.md || fail "plan template must require dirty worktree gate"
grep -q 'workstream-dispatch-gate.sh' templates/plan-tier-m.md || fail "plan template must require workstream dispatch gate"
grep -q 'canonical-command-gate.sh' templates/plan-tier-m.md || fail "plan template must require canonical command gate"
grep -q 'local-routing-business-config-gate.sh' templates/plan-tier-m.md || fail "plan template must require local routing business config gate"
grep -q 'miniapp-local-env-gate.sh' templates/plan-tier-m.md || fail "plan template must require miniapp local env gate"
grep -q 'temporary-state-ledger-gate.sh' templates/plan-tier-m.md || fail "plan template must require temporary state ledger gate"
grep -q 'codegraph-evidence-gate.sh' templates/plan-tier-m.md || fail "plan template must require CodeGraph evidence gate"
grep -q 'verification-map-gate.sh' templates/technical-solution.md || fail "technical solution template must require verification map gate"
grep -q 'verification_map_status: PENDING' templates/verification-map.md || fail "verification map template must include pending status"
grep -q 'runner: shell/manual/N/A' templates/verification-map.md || fail "verification map template must document runner contract"
grep -q 'retro_status: PENDING' templates/retro.md || fail "retro template must include pending status"
grep -q 'gate_false_positive_count' templates/retro.md || fail "retro template must track gate false positives"
grep -q 'instinct_candidate_count' templates/retro.md || fail "retro template must track instinct candidates"
grep -q 'ai-test-report.md' templates/spec-tier-m.md || fail "Tier M spec template must include AI test report"
grep -q 'ai-test-report.md' templates/spec-tier-l.md || fail "Tier L spec template must include AI test report"
grep -q 'confirmation_status: PENDING' templates/technical-solution.md || fail "technical solution template must include confirmation status"
grep -q 'allowed_next_stage: none' templates/technical-solution.md || fail "technical solution template must include allowed next stage"
grep -q 'prd_source_type: local' templates/technical-solution.md || fail "technical solution template must include PRD source type"
grep -q 'feishu_solution_source_sha256' templates/technical-solution.md || fail "technical solution template must include Feishu sync hash"
grep -q '全栈技术方案' templates/technical-solution.md || fail "technical solution template must require full-stack technical solution"
grep -q 'PRD 端到端覆盖矩阵' templates/technical-solution.md || fail "technical solution template must include PRD end-to-end coverage matrix"
grep -q '前端/客户端页面方案' templates/technical-solution.md || fail "technical solution template must include frontend/client page plan"
grep -q 'MISSING_FULLSTACK_SCOPE' scripts/technical-solution-gate.sh || fail "technical solution gate must enforce full-stack scope"
grep -q 'MISSING_PRD_COVERAGE_MATRIX' scripts/technical-solution-gate.sh || fail "technical solution gate must enforce PRD coverage"
grep -q 'MISSING_CLIENT_SURFACE' scripts/technical-solution-gate.sh || fail "technical solution gate must enforce client surface coverage"
grep -q 'MISSING_EXPORT_SURFACE' scripts/technical-solution-gate.sh || fail "technical solution gate must enforce export coverage"
grep -q 'MISSING_ANALYTICS_SURFACE' scripts/technical-solution-gate.sh || fail "technical solution gate must enforce analytics coverage"
grep -q 'technical-solution-feishu-sync-gate.sh' scripts/technical-solution-gate.sh || fail "technical solution gate must call Feishu sync gate"
grep -q 'TECH_SOLUTION_FEISHU/STALE_SYNC' scripts/technical-solution-feishu-sync-gate.sh || fail "Feishu sync gate must detect stale technical solution sync"
grep -q '全栈方案点' templates/spec-tier-m.md || fail "Tier M spec template must include full-stack solution stop"
grep -q '全栈方案点' templates/spec-tier-l.md || fail "Tier L spec template must include full-stack solution stop"
grep -q 'PRD 全栈覆盖盘点' templates/spec-tier-m.md || fail "Tier M spec template must include PRD full-stack coverage inventory"
grep -q 'PRD 全栈覆盖盘点' templates/spec-tier-l.md || fail "Tier L spec template must include PRD full-stack coverage inventory"
grep -q 'technical-solution-feishu-sync.sh' AGENTS.md || fail "AGENTS must require Feishu technical solution sync"
grep -q '全栈技术方案' AGENTS.md || fail "AGENTS must require full-stack technical solution"
grep -q 'recommendation: 修复后重测' templates/ai-test-report.md || fail "AI test report template must include release recommendation"
grep -q 'AI 测试报告确认' templates/pre-pr-review.md || fail "pre-pr template must include AI test report confirmation"
grep -q 'High-risk SQL is globally forbidden' AGENTS.md || fail "AGENTS must globally forbid high-risk SQL"
grep -q '高危 SQL 全局禁止执行' rules/backend-java.mdc || fail "backend rule must globally forbid high-risk SQL"
grep -q 'backend-test-plan.md.*before' AGENTS.md || fail "AGENTS must require backend test plan before implementation"
grep -q '不得先写后端行为代码' rules/backend-java.mdc || fail "backend rule must forbid behavior code before test plan"
grep -q '复杂 PC 页面没有跑起来给人工确认' rules/frontend-vue2.mdc || fail "frontend rule must block unconfirmed complex PC UI pass claims"
grep -q 'organizationFor123' rules/frontend-vue2.mdc || fail "frontend rule must require mapSystem product group login flow"
grep -q 'scripts/diff-hygiene-gate.sh' AGENTS.md || fail "AGENTS must require diff hygiene gate before merge"
grep -q 'scripts/diff-hygiene-gate.sh' rules/mobile-ios-objc.mdc || fail "iOS rule must require diff hygiene gate"
grep -q 'scripts/diff-hygiene-gate.sh' rules/mobile-android-java.mdc || fail "Android rule must require diff hygiene gate"
grep -q 'temp-hardcode-scan.sh' templates/pre-pr-review.md || fail "pre-pr template must require temp hardcode scan"
grep -q 'codegraph-preflight.sh <repo-id-or-path>' AGENTS.md || fail "AGENTS must require CodeGraph preflight before business CodeGraph review"
grep -q 'codegraph_explore' AGENTS.md || fail "AGENTS must prefer CodeGraph explore for broad questions"
[[ -x scripts/codegraph-bootstrap.sh ]] || fail "CodeGraph bootstrap script must exist and be executable"
grep -q 'scripts/codegraph-bootstrap.sh' docs/README.md || fail "docs index must list CodeGraph bootstrap"
grep -q 'scripts/codegraph-preflight.sh' docs/README.md || fail "docs index must list CodeGraph preflight"
grep -q 'auto-sync' docs/onboarding.md || fail "onboarding must document CodeGraph auto-sync"
grep -q 'scripts/codegraph-bootstrap.sh --all' docs/onboarding.md || fail "onboarding must document CodeGraph bootstrap all-repo setup"
grep -q 'scripts/codegraph-bootstrap.sh <new-repo-id>' docs/onboarding.md || fail "onboarding must document CodeGraph bootstrap for new repos"
grep -q 'scripts/codegraph-preflight.sh <repo-id-or-path>' docs/onboarding.md || fail "onboarding must document optional CodeGraph sync usage"
grep -q 'CODEGRAPH_PROJECT_PATH' docs/onboarding.md || fail "onboarding must require explicit CodeGraph projectPath"
grep -q 'CodeGraph 索引刷新' templates/pre-pr-review.md || fail "pre-pr template must include CodeGraph sync evidence"
grep -q 'CODEGRAPH_PROJECT_PATH' templates/pre-pr-review.md || fail "pre-pr template must require CodeGraph projectPath evidence"
grep -q 'codegraph_explore' templates/pre-pr-review.md || fail "pre-pr template must require CodeGraph explore-first route query flow"
grep -q 'codegraph_explore' docs/onboarding.md || fail "onboarding must document CodeGraph explore-first route query flow"
grep -q '未把 CodeGraph 无输出解释为' templates/pre-pr-review.md || fail "pre-pr template must warn that CodeGraph misses are not no-impact proof"
grep -q 'staleness banner' docs/onboarding.md || fail "onboarding must document CodeGraph staleness banner handling"
grep -q 'beforeShellExecution' .cursor/hooks.json || fail "Cursor hooks must include beforeShellExecution"
grep -q 'afterFileEdit' .cursor/hooks.json || fail "Cursor hooks must include afterFileEdit"
grep -q 'PreToolUse' .codex/hooks.json || fail "Codex hooks must include PreToolUse"
grep -q 'PostToolUse' .codex/hooks.json || fail "Codex hooks must include PostToolUse"
grep -q '@AGENTS.md' .cursor/rules/sfa-harness-core.mdc || fail "Cursor core rule must reference AGENTS.md"
grep -q '@rules/backend-java.mdc' .cursor/rules/sfa-backend-java.mdc || fail "Cursor backend rule must reference backend source rule"
grep -q '@rules/frontend-vue2.mdc' .cursor/rules/sfa-frontend-vue2.mdc || fail "Cursor frontend rule must reference frontend source rule"
grep -q '^hooks[[:space:]]*=[[:space:]]*true$' .codex/config.toml || fail "Codex config must enable hooks"
grep -q -- '--json' scripts/harness-status.sh || fail "harness status must support JSON output"
scripts/no-personal-paths.sh
scripts/adapter-compliance-gate.sh docs/architecture/adapter-compliance.md
scripts/ecc/ecc-sidecar-test.sh
scripts/harness-observability-ready.sh
grep -q 'scripts/team-rollout-preflight.sh' README.md || fail "README must document team rollout preflight"
grep -q 'ECC 可选增强' README.md || fail "README must document optional ECC sidecar"
grep -q 'scripts/team-rollout-preflight.sh' docs/onboarding.md || fail "onboarding must document team rollout preflight"
grep -q 'ECC 可选 sidecar' docs/onboarding.md || fail "onboarding must document optional ECC sidecar"
grep -q 'config/agent-registry.yml' docs/onboarding.md || fail "onboarding must document agent registry"
grep -q 'codex-agent-generator.sh --dry-run' docs/onboarding.md || fail "onboarding must document Codex agent generator dry-run"
grep -q 'allow-global' docs/onboarding.md || fail "onboarding must document Codex global write opt-in"
grep -q 'agent-dispatch-plan.sh' docs/onboarding.md || fail "onboarding must document agent dispatch planner"
grep -q 'agent-dispatch-plan-gate.sh' docs/onboarding.md || fail "onboarding must document agent dispatch plan gate"
grep -q 'agent-output-contract-gate.sh' docs/onboarding.md || fail "onboarding must document agent output contract gate"
grep -q 'Agent dispatch plan' templates/harness-status.md || fail "harness status template must list agent dispatch plan gate"
grep -q 'agent-dispatch-plan-gate.sh' templates/plan-tier-m.md || fail "plan template must require agent dispatch plan gate"
grep -q 'agent-output-contract-gate.sh' templates/plan-tier-m.md || fail "plan template must require agent output contract gate"

grep -q '"instructions"' opencode.json || fail "missing instructions in opencode.json"
grep -q '"permission"' opencode.json || fail "missing permission in opencode.json"
grep -q 'scripts/harness-sensor-runner.sh \*' opencode.json || fail "OpenCode must allow harness sensor runner command"
if grep -q 'external_directory' opencode.json || grep -q 'SFA_PROJECTS_ROOT' opencode.json .opencode/agents/*.md; then
  fail "versioned OpenCode config must not risk broad external_directory expansion; generate config/opencode.local.json instead"
fi
grep -q '^config/opencode.local.json$' .gitignore || fail ".gitignore must ignore generated OpenCode local config"
grep -q '^.harness/generated/$' .gitignore || fail ".gitignore must ignore generated harness adapter output"
grep -q '^  edit: deny$' .opencode/agents/sfa-harness-explorer.md || fail "explorer agent must deny edit"
grep -q '^  edit: deny$' .opencode/agents/sfa-harness-reviewer.md || fail "reviewer agent must deny edit"
grep -q 'Registry: `sfa-harness-explorer`' .opencode/agents/sfa-harness-explorer.md || fail "explorer agent must declare registry marker"
grep -q 'Registry: `sfa-harness-reviewer`' .opencode/agents/sfa-harness-reviewer.md || fail "reviewer agent must declare registry marker"
scripts/agent-registry-gate.sh
grep -q 'docs/onboarding.md' README.md || fail "README.md must link docs/onboarding.md"
grep -q 'changes-retention-policy.md' README.md || fail "README.md must link changes retention policy"
grep -q '^artifacts/$' .gitignore || fail ".gitignore must ignore artifacts/"
grep -q '^changes/\*\*/screenshots/$' .gitignore || fail ".gitignore must ignore changes screenshots"
[[ -f config/repos.local.example.sh ]] || fail "missing config/repos.local.example.sh"
[[ -f docs/onboarding.md ]] || fail "missing docs/onboarding.md"

scripts/harness-team-readiness-test.sh

printf 'PASS: harness self audit passed\n'
