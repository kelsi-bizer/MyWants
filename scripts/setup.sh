#!/usr/bin/env bash
# Restore the MyWants dev environment after a Cloud Shell VM recycle.
#
# Cloud Shell wipes everything outside $HOME and generates a fresh ephemeral
# gcloud config each session, so `gcloud config set project` does not survive.
# This script is idempotent — run it any time the environment looks wrong.
#
#   bash scripts/setup.sh
#
set -euo pipefail

PROJECT_ID="mywants-ai-hack26"
REGION="us-central1"
REPO_DIR="${HOME}/mywants"
MARKER="# --- MyWants AI ---"

echo "==> Persisting project settings to ~/.bashrc"
if ! grep -qF "${MARKER}" "${HOME}/.bashrc" 2>/dev/null; then
  cat >> "${HOME}/.bashrc" <<EOF

${MARKER}
export PROJECT_ID=${PROJECT_ID}
export REGION=${REGION}
export CLOUDSDK_CORE_PROJECT=\$PROJECT_ID
export CLOUDSDK_RUN_REGION=\$REGION
# What the google-genai / ADK SDKs actually read (NOT CLOUDSDK_*):
export GOOGLE_CLOUD_PROJECT=\$PROJECT_ID
export GOOGLE_GENAI_USE_ENTERPRISE=true
export GOOGLE_GENAI_USE_VERTEXAI=true
EOF
  echo "    added"
else
  echo "    already present"
fi

# shellcheck disable=SC1091
source "${HOME}/.bashrc"

echo "==> Setting gcloud defaults for this session"
gcloud config set project "${PROJECT_ID}" --quiet
gcloud config set run/region "${REGION}" --quiet

echo "==> Python virtualenv"
cd "${REPO_DIR}"
if [ ! -d .venv ]; then
  python3 -m venv .venv
  echo "    created .venv"
fi
# shellcheck disable=SC1091
source .venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet -r services/agents/requirements.txt
echo "    dependencies installed"

echo "==> Verifying platform surface"
bash scripts/verify-platform.sh

cat <<EOF

Environment ready.

  Project : ${PROJECT_ID}
  Region  : ${REGION}  (Gemini generative calls use 'global' — see docs/platform-notes.md)
  Repo    : ${REPO_DIR}
  Venv    : source ${REPO_DIR}/.venv/bin/activate

Reminder: never run long builds in this terminal — the VM recycles after
~20 min idle. Use Cloud Build and Cloud Run jobs, which survive disconnects.
EOF
