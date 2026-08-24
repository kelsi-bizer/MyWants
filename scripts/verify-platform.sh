#!/usr/bin/env bash
# Re-verify every platform assumption in docs/platform-notes.md.
#
# Run this after any dependency bump, or whenever something behaves oddly.
# It probes the live API rather than trusting docs — the publisher-model
# listing endpoint returns empty for this project, so a real call is the only
# reliable way to know whether a model is available.
#
#   bash scripts/verify-platform.sh
#
set -uo pipefail

PROJECT_ID="${PROJECT_ID:-mywants-ai-hack26}"
TOKEN="$(gcloud auth print-access-token)"
FAILED=0

probe() {  # probe <location> <model> <method> <payload>
  local loc="$1" model="$2" method="$3" payload="$4"
  local base="https://aiplatform.googleapis.com"
  [ "${loc}" != "global" ] && base="https://${loc}-aiplatform.googleapis.com"
  curl -sS -o /dev/null -w '%{http_code}' -X POST \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    "${base}/v1/projects/${PROJECT_ID}/locations/${loc}/publishers/google/models/${model}:${method}" \
    -d "${payload}"
}

expect() {  # expect <want> <got> <label>
  if [ "$2" = "$1" ]; then
    printf '  ok    %s (%s)\n' "$3" "$2"
  else
    printf '  FAIL  %s — expected %s, got %s\n' "$3" "$1" "$2"
    FAILED=1
  fi
}

GEN='{"contents":[{"role":"user","parts":[{"text":"hi"}]}]}'
EMB='{"instances":[{"content":"hello world"}]}'

echo "Platform verification — project ${PROJECT_ID}"

echo "Generative models must work on global:"
for m in gemini-3.7-flash gemini-3.6-flash gemini-3.5-flash gemini-3.5-flash-lite; do
  expect 200 "$(probe global "${m}" generateContent "${GEN}")" "${m} @global"
done

echo "Generative models are NOT available in-region (documents why we use global):"
expect 404 "$(probe us-central1 gemini-3.7-flash generateContent "${GEN}")" "gemini-3.7-flash @us-central1"

echo "Embedding model must work in-region (co-located with Firestore):"
expect 200 "$(probe us-central1 gemini-embedding-001 predict "${EMB}")" "gemini-embedding-001 @us-central1"

echo "Model IDs must satisfy hackathon eligibility (>= Gemini 3.5):"
if python3 -c "
import sys; sys.path.insert(0, 'services/agents')
import models; models.assert_compliant()
" 2>/dev/null; then
  printf '  ok    models.assert_compliant()\n'
else
  printf '  FAIL  models.assert_compliant() — a model older than 3.5 is configured\n'
  FAILED=1
fi

if [ "${FAILED}" -eq 0 ]; then
  echo "All platform assumptions hold."
else
  echo "Platform verification FAILED — see docs/platform-notes.md before continuing."
  exit 1
fi
