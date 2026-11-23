#!/usr/bin/env bash
# Drive bin/emulator-env. Planted credential variables must be cleared.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTRY="${ROOT}/bin/emulator-env"

export AWS_ACCESS_KEY_ID="planted-access-key"
export AWS_SECRET_ACCESS_KEY="planted-secret-key"
export AWS_SESSION_TOKEN="planted-session-token"
export AWS_PROFILE="planted-profile"
export AWS_ENDPOINT_URL="https://aws.example.invalid"

echo "BEFORE AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
echo "BEFORE AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
echo "BEFORE AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN}"
echo "BEFORE AWS_PROFILE=${AWS_PROFILE}"
echo "BEFORE AWS_ENDPOINT_URL=${AWS_ENDPOINT_URL}"

eval "$("$ENTRY")"

echo "AFTER AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID-<unset>}"
echo "AFTER AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY-<unset>}"
echo "AFTER AWS_SESSION_TOKEN=${AWS_SESSION_TOKEN-<unset>}"
echo "AFTER AWS_PROFILE=${AWS_PROFILE-<unset>}"
echo "AFTER AWS_ENDPOINT_URL=${AWS_ENDPOINT_URL-<unset>}"
echo "AFTER AWS_SHARED_CREDENTIALS_FILE=${AWS_SHARED_CREDENTIALS_FILE-<unset>}"
echo "AFTER AWS_CONFIG_FILE=${AWS_CONFIG_FILE-<unset>}"
echo "AFTER AWS_CA_BUNDLE=${AWS_CA_BUNDLE-<unset>}"

fail=0
for name in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE; do
  if [[ -n "${!name+x}" ]]; then
    echo "FAIL ${name} is still set: ${!name}" >&2
    fail=1
  fi
done

base="${HOME}/.aws/emulator/9297"
if [[ "${AWS_ENDPOINT_URL}" != "https://127.0.0.1:9297" ]]; then
  echo "FAIL AWS_ENDPOINT_URL=${AWS_ENDPOINT_URL}" >&2
  fail=1
fi
if [[ "${AWS_SHARED_CREDENTIALS_FILE}" != "${base}/emulator_credentials" ]]; then
  echo "FAIL credentials file ${AWS_SHARED_CREDENTIALS_FILE}" >&2
  fail=1
fi
if [[ "${AWS_CONFIG_FILE}" != "${base}/config" ]]; then
  echo "FAIL config file ${AWS_CONFIG_FILE}" >&2
  fail=1
fi
if [[ "${AWS_CA_BUNDLE}" != "${base}/ca.pem" ]]; then
  echo "FAIL CA bundle ${AWS_CA_BUNDLE}" >&2
  fail=1
fi

if [[ "$fail" != 0 ]]; then
  exit 1
fi
echo "env check passed"
