#!/usr/bin/env bash

sfa_tmp_file() {
  local prefix="${1:-sfa-tmp}"
  local tmpdir="${TMPDIR:-/tmp}"
  tmpdir="${tmpdir%/}"
  mktemp "$tmpdir/${prefix}.$$.XXXXXXXXXX"
}
