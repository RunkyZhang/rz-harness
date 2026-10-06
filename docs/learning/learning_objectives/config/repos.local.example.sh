#!/usr/bin/env bash
# Copy this file to config/repos.local.sh and adjust paths for your machine.
# Do not commit config/repos.local.sh.

export SFA_HARNESS_ROOT="${SFA_HARNESS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)}"
export SFA_PROJECTS_ROOT="${SFA_PROJECTS_ROOT:-$HOME/codex/sfa-projects}"

export SFA_REPO_BACKEND_SALES_MANAGEMENT="${SFA_REPO_BACKEND_SALES_MANAGEMENT:-$SFA_PROJECTS_ROOT/sfa-sales-management}"
export SFA_REPO_BACKEND_SFA_BACKEND="${SFA_REPO_BACKEND_SFA_BACKEND:-$SFA_PROJECTS_ROOT/sfa-backend}"
export SFA_REPO_BACKEND_SFA_ROOT="${SFA_REPO_BACKEND_SFA_ROOT:-$SFA_PROJECTS_ROOT/sfa-root}"
export SFA_REPO_BACKEND_CEO_MEMBER="${SFA_REPO_BACKEND_CEO_MEMBER:-$SFA_PROJECTS_ROOT/backend-ceo-member}"
export SFA_REPO_FRONTEND_MAP_SYSTEM="${SFA_REPO_FRONTEND_MAP_SYSTEM:-$SFA_PROJECTS_ROOT/mapSystem}"
export SFA_REPO_FRONTEND_SIGN_UP="${SFA_REPO_FRONTEND_SIGN_UP:-$SFA_PROJECTS_ROOT/sign-up}"
export SFA_REPO_FRONTEND_MERCHANT_WECHATAPP="${SFA_REPO_FRONTEND_MERCHANT_WECHATAPP:-$SFA_PROJECTS_ROOT/merchant-wechatapp}"
export SFA_REPO_FRONTEND_SFAINTL="${SFA_REPO_FRONTEND_SFAINTL:-$SFA_PROJECTS_ROOT/SfaIntl}"
export SFA_REPO_MOBILE_SFA_IOS="${SFA_REPO_MOBILE_SFA_IOS:-$SFA_PROJECTS_ROOT/sfa-ios}"
export SFA_REPO_MOBILE_SFA_ANDROID="${SFA_REPO_MOBILE_SFA_ANDROID:-$SFA_PROJECTS_ROOT/sfa-android}"

# Tooling hints used by humans and agents when recording evidence.
export SFA_BACKEND_MAVEN_COMMAND="${SFA_BACKEND_MAVEN_COMMAND:-mvn}"
export SFA_BACKEND_MAVEN_ARGS="${SFA_BACKEND_MAVEN_ARGS:-}"
export SFA_FRONTEND_PACKAGE_MANAGER="${SFA_FRONTEND_PACKAGE_MANAGER:-npm}"
export SFA_FRONTEND_PACKAGE_MANAGER_ARGS="${SFA_FRONTEND_PACKAGE_MANAGER_ARGS:-}"
export SFA_BACKEND_JAVA_MAJOR="${SFA_BACKEND_JAVA_MAJOR:-8}"
export SFA_FRONTEND_NODE_VERSION="${SFA_FRONTEND_NODE_VERSION:-14.21.3}"
export SFA_FRONTEND_MERCHANT_WECHATAPP_NODE_VERSION="${SFA_FRONTEND_MERCHANT_WECHATAPP_NODE_VERSION:-18.18.0}"
export SFA_FRONTEND_NODE_BIN_DIR="${SFA_FRONTEND_NODE_BIN_DIR:-}"
export SFA_FRONTEND_MAP_SYSTEM_DEV_PORT="${SFA_FRONTEND_MAP_SYSTEM_DEV_PORT:-9527}"
export SFA_FRONTEND_SIGN_UP_DEV_PORT="${SFA_FRONTEND_SIGN_UP_DEV_PORT:-8080}"
export SFA_FRONTEND_SFAINTL_DEV_PORT="${SFA_FRONTEND_SFAINTL_DEV_PORT:-9528}"
export SFA_FRONTEND_DEV_HOST="${SFA_FRONTEND_DEV_HOST:-0.0.0.0}"

# Local backend/app runtime hints. These are documentation-friendly defaults for
# readiness files; adjust in ignored config/repos.local.sh for your machine.
export SFA_LOCAL_BACKEND_SALES_MANAGEMENT_URL="${SFA_LOCAL_BACKEND_SALES_MANAGEMENT_URL:-http://127.0.0.1:31010}"
export SFA_LOCAL_BACKEND_SFA_BACKEND_URL="${SFA_LOCAL_BACKEND_SFA_BACKEND_URL:-http://127.0.0.1:30080}"
export SFA_LOCAL_BACKEND_SFA_ROOT_URL="${SFA_LOCAL_BACKEND_SFA_ROOT_URL:-http://127.0.0.1:30081}"
export SFA_LOCAL_BACKEND_CEO_MEMBER_URL="${SFA_LOCAL_BACKEND_CEO_MEMBER_URL:-http://127.0.0.1:9168}"
export SFA_IOS_SCHEME="${SFA_IOS_SCHEME:-FProject}"
export SFA_IOS_WORKSPACE="${SFA_IOS_WORKSPACE:-FProject.xcworkspace}"
export SFA_IOS_CONFIGURATION="${SFA_IOS_CONFIGURATION:-Debug}"
export SFA_IOS_EXPORT_METHOD="${SFA_IOS_EXPORT_METHOD:-Development}"
export SFA_IOS_SIMULATOR_NAME="${SFA_IOS_SIMULATOR_NAME:-iPhone 15}"
export SFA_ANDROID_GRADLE_TASK="${SFA_ANDROID_GRADLE_TASK:-:app:assembleDebug}"
export SFA_ANDROID_BUILD_VARIANT="${SFA_ANDROID_BUILD_VARIANT:-debug}"
export SFA_ANDROID_AVD_NAME="${SFA_ANDROID_AVD_NAME:-harness_api28_arm64}"
export SFA_ANDROID_EMAS_BUILD_URL="${SFA_ANDROID_EMAS_BUILD_URL:-https://emas.console.aliyun.com/emasService/devTool/devopsBuild/build?ProductId=3909886&AppKey=335500513&AppType=2}"
export SFA_APP_ENV_SWITCH_NOTE="${SFA_APP_ENV_SWITCH_NOTE:-record in environment-readiness.md; do not store credentials here}"

# SFA iOS packaging/signing hints. Keep real values only in ignored
# config/repos.local.sh or the calling shell. Development signing verification
# for sfaios must be coordinated with Chen Zhengwen before changing signing
# config, provisioning profiles, device registration, or Apple account access.
export SFA_IOS_DEVELOPMENT_TEAM="${SFA_IOS_DEVELOPMENT_TEAM:-}"
export SFA_IOS_CODE_SIGN_IDENTITY="${SFA_IOS_CODE_SIGN_IDENTITY:-}"
export SFA_IOS_PROVISIONING_PROFILE="${SFA_IOS_PROVISIONING_PROFILE:-}"
export SFA_IOS_BUNDLE_ID="${SFA_IOS_BUNDLE_ID:-}"
export SFA_IOS_SIGNING_STYLE="${SFA_IOS_SIGNING_STYLE:-automatic}"
export PGYER_U_KEY="${PGYER_U_KEY:-}"
export PGYER_API_KEY="${PGYER_API_KEY:-}"

# PC E2E Smoke login hints. Fill only in ignored config/repos.local.sh or use
# an existing browser login session. Do not put plaintext passwords in versioned
# specs, plans, reports, evidence, screenshots, or comments.
export SFA_PC_E2E_USERNAME="${SFA_PC_E2E_USERNAME:-}"
export SFA_PC_E2E_PASSWORD="${SFA_PC_E2E_PASSWORD:-}"
export SFA_PC_E2E_PASSWORD_SOURCE="${SFA_PC_E2E_PASSWORD_SOURCE:-local-env}"
export SFA_PC_E2E_PASSWORD_KEYCHAIN_SERVICE="${SFA_PC_E2E_PASSWORD_KEYCHAIN_SERVICE:-sfa-pc-e2e}"

# Harness-only local proxy. Normal frontend dev does not use this unless the
# smoke run starts the frontend with VUE_APP_BASE_API pointing at the proxy.
export SFA_HARNESS_SMOKE="${SFA_HARNESS_SMOKE:-0}"
export SFA_HARNESS_PROXY_HOST="${SFA_HARNESS_PROXY_HOST:-127.0.0.1}"
export SFA_HARNESS_PROXY_PORT="${SFA_HARNESS_PROXY_PORT:-19080}"

# Async-approval decision ledger (scripts/decision-gate.sh --notify).
# Target Lark chat/open_id for decision notifications. Empty = dry-run only;
# this MVP never auto-sends (fail-closed). Fill once the target is confirmed.
export SFA_DECISION_LARK_CHAT="${SFA_DECISION_LARK_CHAT:-}"
