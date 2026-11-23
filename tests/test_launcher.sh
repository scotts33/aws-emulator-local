#!/usr/bin/env bash
# Read the shipped launcher and the Dockerfile it builds.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="${ROOT}/bin/up"
DOCKERFILE="${ROOT}/Dockerfile"
text="$(cat "$LAUNCHER")"
image="$(cat "$DOCKERFILE")"

fail=0
say() {
  echo "$1" >&2
  fail=1
}

if ! grep -q 'aws-emulator-aarch64.rpm' <<<"$text"; then
  say "FAIL launcher does not install aws-emulator-aarch64.rpm"
fi
if ! grep -q 'aws-emulator-aarch64.rpm' <<<"$image"; then
  say "FAIL Dockerfile does not install aws-emulator-aarch64.rpm"
fi
if grep -q 'aws-emulator-x86_64.rpm' <<<"$image$text"; then
  say "FAIL x86_64 package is present"
fi
if ! grep -q 'rpm -i' <<<"$image"; then
  say "FAIL Dockerfile does not install the rpm"
fi
if ! grep -q -- '--memory=' <<<"$text"; then
  say "FAIL launcher has no memory cap"
fi
if ! grep -q '127.0.0.1:${PORT}:${PORT}' <<<"$text"; then
  say "FAIL launcher does not publish 127.0.0.1:9297"
fi
if ! grep -q '^PORT=9297$' <<<"$text"; then
  say "FAIL launcher port is not 9297"
fi
if grep -E -- '--auth([=[:space:]]|$)' <<<"$text$image"; then
  say "FAIL auth is disabled or passed through"
fi
# mkdir -p is not a host publish. The emulator port is --port, not docker -p.
scan="$(printf '%s\n' "$text" | grep -v 'mkdir -p' || true)"
pubs="$(grep -oE -- '-p[[:space:]]+[^[:space:]\\]+' <<<"$scan" || true)"
if [[ -z "$pubs" ]]; then
  say "FAIL launcher does not publish a port"
fi
pub_count=0
while IFS= read -r pub; do
  [[ -z "$pub" ]] && continue
  pub_count=$((pub_count + 1))
  value="${pub#-p}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value#\"}"
  value="${value%\"}"
  value="${value#\'}"
  value="${value%\'}"
  case "$value" in
    127.0.0.1:*) ;;
    *) say "FAIL publish is not loopback-only: ${value}" ;;
  esac
  case "$value" in
    *0.0.0.0*) say "FAIL publish contains 0.0.0.0: ${value}" ;;
  esac
  case "$value" in
    '127.0.0.1:${PORT}:${PORT}'|127.0.0.1:9297:9297) ;;
    *) say "FAIL publish is not port 9297 on both sides: ${value}" ;;
  esac
done <<<"$pubs"
if [[ "$pub_count" != 1 ]]; then
  say "FAIL expected one host publish, found ${pub_count}"
fi
if grep -q -- '--port=' <<<"$text"; then
  :
else
  say "FAIL emulator port is not set with --port"
fi
# Inside the container the emulator must listen on all interfaces so Docker can forward.
if ! grep -q 'EMULATOR_BIND_ADDRESS=0.0.0.0' <<<"$image"; then
  say "FAIL Dockerfile does not bind 0.0.0.0 inside the container"
fi
if ! grep -q 'EMULATOR_TELEMETRY=off' <<<"$image"; then
  say "FAIL Dockerfile does not turn telemetry off"
fi
if ! grep -q -- '--read-only' <<<"$text"; then
  say "FAIL launcher root filesystem is writable"
fi
if ! grep -q -- '--cap-drop=ALL' <<<"$text"; then
  say "FAIL launcher does not drop all capabilities"
fi
if ! grep -q 'no-new-privileges' <<<"$text"; then
  say "FAIL launcher allows new privileges"
fi
if ! grep -q 'EMULATOR_TELEMETRY=off' <<<"$text"; then
  say "FAIL launcher does not set EMULATOR_TELEMETRY=off"
fi
if ! grep -q -- '--telemetry off' <<<"$text"; then
  say "FAIL launcher does not pass --telemetry off"
fi

if [[ "$fail" != 0 ]]; then
  exit 1
fi
echo "launcher check passed"
echo "rpm=aws-emulator-aarch64.rpm"
echo "publish=127.0.0.1:9297"
echo "memory=--memory="
echo "auth=on"
