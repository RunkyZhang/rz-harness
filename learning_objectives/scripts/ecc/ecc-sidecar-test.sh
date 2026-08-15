#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
wrapper="$root/scripts/ecc/ecc-sidecar.sh"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

missing_home="$tmpdir/missing"
missing_output="$(SFA_ECC_HOME="$missing_home" "$wrapper" status)"
printf '%s\n' "$missing_output" | grep -q 'ECC_STATUS=UNAVAILABLE'

fake_ecc="$tmpdir/ECC"
mkdir -p "$fake_ecc/scripts"
cat >"$fake_ecc/package.json" <<'JSON'
{"name":"fake-ecc"}
JSON
cat >"$fake_ecc/scripts/consult.js" <<'JS'
console.log(JSON.stringify({ok: true, argv: process.argv.slice(2)}));
JS
cat >"$fake_ecc/install.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >"$ECC_FAKE_ARGS_OUT"
printf '{"dryRun":true}\n'
SH
chmod +x "$fake_ecc/install.sh"

args_out="$tmpdir/install-args.txt"
ECC_FAKE_ARGS_OUT="$args_out" SFA_ECC_HOME="$fake_ecc" \
  "$wrapper" install-plan --profile minimal >/dev/null

grep -q -- '--target codex' "$args_out"
grep -q -- '--dry-run' "$args_out"
grep -q -- '--json' "$args_out"

if ECC_FAKE_ARGS_OUT="$args_out" SFA_ECC_HOME="$fake_ecc" \
  "$wrapper" install-plan --target cursor --profile minimal >/dev/null 2>&1; then
  printf 'FAIL: install-plan accepted non-codex target\n' >&2
  exit 1
fi

if ECC_FAKE_ARGS_OUT="$args_out" SFA_ECC_HOME="$fake_ecc" \
  "$wrapper" install-plan --target=cursor --profile minimal >/dev/null 2>&1; then
  printf 'FAIL: install-plan accepted target=cursor\n' >&2
  exit 1
fi

if ECC_FAKE_ARGS_OUT="$args_out" SFA_ECC_HOME="$fake_ecc" \
  "$wrapper" install-plan --profile minimal --apply >/dev/null 2>&1; then
  printf 'FAIL: install-plan accepted apply mode\n' >&2
  exit 1
fi

if ECC_FAKE_ARGS_OUT="$args_out" SFA_ECC_HOME="$fake_ecc" \
  "$wrapper" install-plan --profile minimal --dry-run=false >/dev/null 2>&1; then
  printf 'FAIL: install-plan accepted dry-run=false\n' >&2
  exit 1
fi

consult_output="$(SFA_ECC_HOME="$fake_ecc" "$wrapper" consult security reviews)"
printf '%s\n' "$consult_output" | grep -q '"ok":true'
printf '%s\n' "$consult_output" | grep -q -- '--target'

printf 'PASS: ECC sidecar wrapper keeps ECC optional and dry-run scoped\n'
