#!/usr/bin/env bash
# bin/smoke must exit non-zero before any aws or curl call.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SMOKE="${ROOT}/bin/smoke"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

cat >"${workdir}/aws" <<'EOF'
#!/bin/sh
echo "aws invoked" >>"$SMOKE_CALL_LOG"
exit 0
EOF
cat >"${workdir}/curl" <<'EOF'
#!/bin/sh
echo "curl invoked" >>"$SMOKE_CALL_LOG"
exit 0
EOF
chmod +x "${workdir}/aws" "${workdir}/curl"

run_case() {
  local label="$1"
  shift
  local log="${workdir}/${label}.log"
  : >"$log"
  set +e
  SMOKE_CALL_LOG="$log" PATH="${workdir}:${PATH}" "$@" "$SMOKE" >"${workdir}/${label}.out" 2>"${workdir}/${label}.err"
  local status=$?
  set -e
  echo "CASE ${label} status=${status}"
  echo "CASE ${label} stderr=$(cat "${workdir}/${label}.err")"
  if [[ "$status" -eq 0 ]]; then
    echo "FAIL ${label} exited 0" >&2
    exit 1
  fi
  if [[ -s "$log" ]]; then
    echo "FAIL ${label} invoked a client: $(cat "$log")" >&2
    exit 1
  fi
  echo "CASE ${label} clients=none"
}

run_case unset env -u AWS_ENDPOINT_URL bash
run_case nonlocal env AWS_ENDPOINT_URL="https://s3.us-east-1.amazonaws.com" bash
echo "smoke refuses passed"
