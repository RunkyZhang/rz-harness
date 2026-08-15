#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

usage() {
  cat <<'USAGE'
Usage:
  scripts/sfa-ios-pack.sh [options]

Options:
  --check                         Validate local iOS packaging prerequisites only.
  --repo <path>                   Override SFA iOS repo path.
  --scheme <name>                 Xcode scheme. Default: SFA_IOS_SCHEME or FProject.
  --workspace <name>              Workspace name under FProject. Default: FProject.xcworkspace.
  --configuration <name>          Xcode configuration. Default: SFA_IOS_CONFIGURATION or Debug.
  --method <method>               Export method. Default: SFA_IOS_EXPORT_METHOD or Development.
  --upload <none|pgyer>           Upload exported ipa. Default: none.
  --notes <text>                  Build notes for artifact metadata and optional Pgyer upload.
  --output-dir <path>             Output directory. Default: artifacts/ios-pack/<timestamp>.
  -h, --help                      Show this help.

Environment:
  SFA_REPO_MOBILE_SFA_IOS         Canonical local SFA iOS repo path.
  SFA_REPO_IOS_SFA                Backward-compatible local SFA iOS repo path.
  SFA_IOS_DEVELOPMENT_TEAM        Optional Apple development team ID.
  SFA_IOS_CODE_SIGN_IDENTITY      Optional code signing identity.
  SFA_IOS_PROVISIONING_PROFILE    Optional provisioning profile specifier/name.
  SFA_IOS_BUNDLE_ID               Optional bundle ID for exportOptions provisioningProfiles.
  SFA_IOS_SIGNING_STYLE           Optional export signing style. Default: automatic.
  PGYER_U_KEY                     Required only for --upload pgyer.
  PGYER_API_KEY                   Required only for --upload pgyer.

Examples:
  scripts/sfa-ios-pack.sh --check
  scripts/sfa-ios-pack.sh --configuration Debug --method Development --upload none --notes "SIT validation"
  PGYER_U_KEY=... PGYER_API_KEY=... scripts/sfa-ios-pack.sh --upload pgyer --notes "SIT validation"
USAGE
}

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

info() {
  printf 'INFO: %s\n' "$1"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

xml_escape() {
  printf '%s' "$1" \
    | sed -e 's/&/\&amp;/g' \
          -e 's/</\&lt;/g' \
          -e 's/>/\&gt;/g' \
          -e 's/"/\&quot;/g' \
          -e "s/'/\&apos;/g"
}

normalize_method() {
  case "$1" in
    Development|development) printf 'development' ;;
    AdHoc|adhoc|ad-hoc) printf 'ad-hoc' ;;
    AppStore|appstore|app-store|app-store-connect) printf 'app-store' ;;
    Enterprise|enterprise) printf 'enterprise' ;;
    *) printf '%s' "$1" ;;
  esac
}

if [[ -f "$root/config/repos.local.sh" ]]; then
  # shellcheck disable=SC1091
  source "$root/config/repos.local.sh"
fi

mode="pack"
repo_override=""
scheme="${SFA_IOS_SCHEME:-FProject}"
workspace="${SFA_IOS_WORKSPACE:-FProject.xcworkspace}"
configuration="${SFA_IOS_CONFIGURATION:-Debug}"
method="${SFA_IOS_EXPORT_METHOD:-Development}"
upload="none"
notes=""
output_dir=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --check)
      mode="check"
      shift
      ;;
    --repo)
      [[ "$#" -ge 2 ]] || fail "missing value for --repo"
      repo_override="$2"
      shift 2
      ;;
    --scheme)
      [[ "$#" -ge 2 ]] || fail "missing value for --scheme"
      scheme="$2"
      shift 2
      ;;
    --workspace)
      [[ "$#" -ge 2 ]] || fail "missing value for --workspace"
      workspace="$2"
      shift 2
      ;;
    --configuration)
      [[ "$#" -ge 2 ]] || fail "missing value for --configuration"
      configuration="$2"
      shift 2
      ;;
    --method)
      [[ "$#" -ge 2 ]] || fail "missing value for --method"
      method="$2"
      shift 2
      ;;
    --upload)
      [[ "$#" -ge 2 ]] || fail "missing value for --upload"
      upload="$2"
      shift 2
      ;;
    --notes)
      [[ "$#" -ge 2 ]] || fail "missing value for --notes"
      notes="$2"
      shift 2
      ;;
    --output-dir)
      [[ "$#" -ge 2 ]] || fail "missing value for --output-dir"
      output_dir="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "unknown option: $1"
      ;;
  esac
done

case "$upload" in
  none|pgyer) ;;
  *) fail "--upload must be one of: none, pgyer" ;;
esac

method="$(normalize_method "$method")"
repo="${repo_override:-${SFA_REPO_MOBILE_SFA_IOS:-${SFA_REPO_IOS_SFA:-}}}"

[[ -n "$repo" ]] || fail "SFA iOS repo path is not set; set SFA_REPO_MOBILE_SFA_IOS in config/repos.local.sh or pass --repo"
[[ -d "$repo" ]] || fail "SFA iOS repo path not found: $repo"

project_dir="$repo/FProject"
[[ -d "$project_dir" ]] || fail "FProject directory not found under SFA iOS repo: $project_dir"
[[ -d "$project_dir/$workspace" ]] || fail "workspace not found: $project_dir/$workspace"

if ! have_cmd xcodebuild; then
  fail "xcodebuild is not available; install Xcode and select it with xcode-select"
fi

if [[ "$upload" == "pgyer" ]]; then
  have_cmd curl || fail "curl is required for --upload pgyer"
  [[ -n "${PGYER_U_KEY:-}" ]] || fail "PGYER_U_KEY is required for --upload pgyer"
  [[ -n "${PGYER_API_KEY:-}" ]] || fail "PGYER_API_KEY is required for --upload pgyer"
fi

info "repo=$repo"
info "workspace=$workspace"
info "scheme=$scheme"
info "configuration=$configuration"
info "export_method=$method"
info "upload=$upload"

if [[ "$mode" == "check" ]]; then
  if git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    info "git_branch=$(git -C "$repo" branch --show-current 2>/dev/null || true)"
    info "git_commit=$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || true)"
  fi
  xcodebuild -list -workspace "$project_dir/$workspace" >/dev/null
  info "xcodebuild workspace listing succeeded"
  exit 0
fi

timestamp="$(date +%Y%m%d_%H%M%S)"
if [[ -z "$output_dir" ]]; then
  output_dir="$root/artifacts/ios-pack/$timestamp"
fi
mkdir -p "$output_dir"

archive_path="$output_dir/$scheme.xcarchive"
export_path="$output_dir/export"
export_options="$output_dir/ExportOptions.plist"
archive_log="$output_dir/archive.log"
export_log="$output_dir/export.log"
metadata_file="$output_dir/build-metadata.txt"
mkdir -p "$export_path"

git_commit="unknown"
if git -C "$repo" rev-parse --short HEAD >/dev/null 2>&1; then
  git_commit="$(git -C "$repo" rev-parse --short HEAD)"
fi

signing_style="${SFA_IOS_SIGNING_STYLE:-automatic}"
team_id="${SFA_IOS_DEVELOPMENT_TEAM:-}"
bundle_id="${SFA_IOS_BUNDLE_ID:-}"
provisioning_profile="${SFA_IOS_PROVISIONING_PROFILE:-}"

{
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>'
  printf '%s\n' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
  printf '%s\n' '<plist version="1.0">'
  printf '%s\n' '<dict>'
  printf '%s\n' '  <key>compileBitcode</key>'
  printf '%s\n' '  <false/>'
  printf '%s\n' '  <key>destination</key>'
  printf '%s\n' '  <string>export</string>'
  printf '%s\n' '  <key>method</key>'
  printf '  <string>%s</string>\n' "$(xml_escape "$method")"
  printf '%s\n' '  <key>signingStyle</key>'
  printf '  <string>%s</string>\n' "$(xml_escape "$signing_style")"
  printf '%s\n' '  <key>stripSwiftSymbols</key>'
  printf '%s\n' '  <true/>'
  printf '%s\n' '  <key>thinning</key>'
  printf '%s\n' '  <string>&lt;none&gt;</string>'
  if [[ -n "$team_id" ]]; then
    printf '%s\n' '  <key>teamID</key>'
    printf '  <string>%s</string>\n' "$(xml_escape "$team_id")"
  fi
  if [[ -n "$bundle_id" && -n "$provisioning_profile" ]]; then
    printf '%s\n' '  <key>provisioningProfiles</key>'
    printf '%s\n' '  <dict>'
    printf '    <key>%s</key>\n' "$(xml_escape "$bundle_id")"
    printf '    <string>%s</string>\n' "$(xml_escape "$provisioning_profile")"
    printf '%s\n' '  </dict>'
  fi
  printf '%s\n' '</dict>'
  printf '%s\n' '</plist>'
} > "$export_options"

archive_args=(
  -workspace "$workspace"
  -scheme "$scheme"
  -configuration "$configuration"
  -archivePath "$archive_path"
  -destination "generic/platform=iOS"
)

if [[ -n "${SFA_IOS_CODE_SIGN_IDENTITY:-}" ]]; then
  archive_args+=("CODE_SIGN_IDENTITY=${SFA_IOS_CODE_SIGN_IDENTITY}")
fi
if [[ -n "$team_id" ]]; then
  archive_args+=("DEVELOPMENT_TEAM=$team_id")
fi
if [[ -n "$provisioning_profile" ]]; then
  archive_args+=("PROVISIONING_PROFILE_SPECIFIER=$provisioning_profile")
fi

info "archive_path=$archive_path"
info "export_path=$export_path"
(
  cd "$project_dir"
  xcodebuild archive "${archive_args[@]}" | tee "$archive_log"
)

[[ -d "$archive_path" ]] || fail "archive was not produced: $archive_path"

(
  cd "$project_dir"
  xcodebuild -exportArchive \
    -archivePath "$archive_path" \
    -exportPath "$export_path" \
    -exportOptionsPlist "$export_options" \
    -allowProvisioningUpdates | tee "$export_log"
)

ipa_path="$(find "$export_path" -maxdepth 1 -type f -name '*.ipa' | head -n 1)"
[[ -n "$ipa_path" && -f "$ipa_path" ]] || fail "ipa was not produced under: $export_path"

final_ipa="$output_dir/${scheme}_${method}_${git_commit}_${timestamp}.ipa"
mv "$ipa_path" "$final_ipa"

checksum="$(shasum -a 256 "$final_ipa" | awk '{print $1}')"
{
  printf 'repo=%s\n' "$repo"
  printf 'commit=%s\n' "$git_commit"
  printf 'scheme=%s\n' "$scheme"
  printf 'configuration=%s\n' "$configuration"
  printf 'method=%s\n' "$method"
  printf 'timestamp=%s\n' "$timestamp"
  printf 'ipa=%s\n' "$final_ipa"
  printf 'sha256=%s\n' "$checksum"
  printf 'notes=%s\n' "$notes"
} > "$metadata_file"

if [[ "$upload" == "pgyer" ]]; then
  info "uploading ipa to Pgyer"
  curl \
    -F "file=@${final_ipa}" \
    -F "uKey=${PGYER_U_KEY}" \
    -F "_api_key=${PGYER_API_KEY}" \
    -F "installType=1" \
    -F "buildUpdateDescription=${notes:-SFA iOS package}" \
    "https://www.pgyer.com/apiv2/app/upload"
  printf '\n'
fi

info "ipa=$final_ipa"
info "sha256=$checksum"
info "metadata=$metadata_file"
