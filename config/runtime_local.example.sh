#!/usr/bin/env bash
# 复制为 config/runtime_local.sh 后按本机修改。不要提交 config/runtime_local.sh。
# 用法：source config/runtime_local.sh

# --- 业务仓磁盘路径（与 git-registry.md 的 path_env 对齐）---
# export RZ_PROJECTS_ROOT="${RZ_PROJECTS_ROOT:-$HOME/projects}"
# export RZ_REPO_SFA_SALES_MANAGEMENT="${RZ_REPO_SFA_SALES_MANAGEMENT:-$RZ_PROJECTS_ROOT/sfa-sales-management}"
# export RZ_REPO_SFA_BACKEND="${RZ_REPO_SFA_BACKEND:-$RZ_PROJECTS_ROOT/sfa-backend}"
# export RZ_REPO_SFA_ROOT="${RZ_REPO_SFA_ROOT:-$RZ_PROJECTS_ROOT/sfa-root}"
# export RZ_REPO_SFA_BASE="${RZ_REPO_SFA_BASE:-$RZ_PROJECTS_ROOT/sfa-base}"
# export RZ_REPO_ARCH_OPEN="${RZ_REPO_ARCH_OPEN:-$RZ_PROJECTS_ROOT/arch-open}"
# export RZ_REPO_ARCH_EVENT="${RZ_REPO_ARCH_EVENT:-$RZ_PROJECTS_ROOT/arch-event}"
# export RZ_REPO_SFA_COMMON_SDK="${RZ_REPO_SFA_COMMON_SDK:-$RZ_PROJECTS_ROOT/sfa-common-sdk}"
# export RZ_REPO_MAP_SYSTEM="${RZ_REPO_MAP_SYSTEM:-$RZ_PROJECTS_ROOT/mapSystem}"
# export RZ_REPO_SIGN_UP="${RZ_REPO_SIGN_UP:-$RZ_PROJECTS_ROOT/sign-up}"
# export RZ_REPO_SFA_IOS="${RZ_REPO_SFA_IOS:-$RZ_PROJECTS_ROOT/sfa-ios}"
# export RZ_REPO_SFA_ANDROID="${RZ_REPO_SFA_ANDROID:-$RZ_PROJECTS_ROOT/sfa-android}"

# --- 本机工具 ---
# export RZ_BACKEND_MAVEN_COMMAND="${RZ_BACKEND_MAVEN_COMMAND:-mvn}"
# export RZ_FRONTEND_PACKAGE_MANAGER="${RZ_FRONTEND_PACKAGE_MANAGER:-npm}"

# --- 通信：本地服务地址、端口、代理 ---
# export RZ_LOCAL_BACKEND_URL="${RZ_LOCAL_BACKEND_URL:-http://127.0.0.1:8080}"
# export RZ_FRONTEND_DEV_PORT="${RZ_FRONTEND_DEV_PORT:-9527}"
# export RZ_HARNESS_PROXY_HOST="${RZ_HARNESS_PROXY_HOST:-127.0.0.1}"
# export RZ_HARNESS_PROXY_PORT="${RZ_HARNESS_PROXY_PORT:-19080}"

# --- 用户 / 账号（明文密码不要写进 spec / evidence）---
# export RZ_E2E_USERNAME=""
# export RZ_E2E_PASSWORD_SOURCE="keychain" # 或 local-env / browser-session

# --- 数据库（仅本文件或钥匙串）---
# export RZ_LOCAL_DB_HOST="127.0.0.1"
# export RZ_LOCAL_DB_PORT="3306"
# export RZ_LOCAL_DB_NAME=""
# 密码：放本文件（已被 gitignore）或钥匙串，不要写进版本库文档。
