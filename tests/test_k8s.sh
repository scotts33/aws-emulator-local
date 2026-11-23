#!/usr/bin/env bash
# The RKE2 manifest must keep the emulator private and on restricted Pod Security.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="${ROOT}/deploy/rke2/aws-emulator.yaml"
text="$(cat "$manifest")"

fail=0
say() {
  echo "$1" >&2
  fail=1
}

for needle in \
  'pod-security.kubernetes.io/enforce: restricted' \
  'automountServiceAccountToken: false' \
  'imagePullPolicy: Never' \
  'readOnlyRootFilesystem: true' \
  'allowPrivilegeEscalation: false' \
  'runAsNonRoot: true' \
  'runAsUser: 1000' \
  'drop: ["ALL"]' \
  'type: RuntimeDefault' \
  'memory: 2Gi' \
  'EMULATOR_TELEMETRY' \
  'value: "off"' \
  'type: ClusterIP' \
  'policyTypes:' \
  '--telemetry'
do
  if ! grep -F -q -- "$needle" <<<"$text"; then
    say "FAIL manifest missing: ${needle}"
  fi
done

if grep -E -- '--auth([=[:space:]]|$)' <<<"$text"; then
  say "FAIL manifest disables authentication"
fi
if grep -E -- 'type:[[:space:]]*(NodePort|LoadBalancer)' <<<"$text"; then
  say "FAIL manifest publishes a Service beyond the cluster"
fi
if grep -E -- 'hostPort:|hostNetwork:[[:space:]]*true|privileged:[[:space:]]*true' <<<"$text"; then
  say "FAIL manifest uses a host or privileged path"
fi
if grep -q '0.0.0.0:' <<<"$text"; then
  say "FAIL manifest publishes 0.0.0.0"
fi

if [[ "$fail" != 0 ]]; then
  exit 1
fi
echo "k8s manifest check passed"
