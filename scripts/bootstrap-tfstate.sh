#!/usr/bin/env bash
# Create the GCS bucket that holds Terraform state.
#
# Chicken-and-egg: Terraform's backend bucket cannot be created by the
# Terraform that uses it. This runs once, before the first `terraform init`.
# Safe to re-run.
#
#   bash scripts/bootstrap-tfstate.sh
#
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-mywants-ai-hack26}"
REGION="${REGION:-us-central1}"
BUCKET="${PROJECT_ID}-tfstate"

if gcloud storage buckets describe "gs://${BUCKET}" >/dev/null 2>&1; then
  echo "State bucket gs://${BUCKET} already exists."
else
  echo "Creating state bucket gs://${BUCKET}"
  gcloud storage buckets create "gs://${BUCKET}" \
    --project="${PROJECT_ID}" \
    --location="${REGION}" \
    --uniform-bucket-level-access \
    --public-access-prevention
fi

# Versioning matters here: it is the only way back from a corrupted or
# accidentally-truncated state file.
gcloud storage buckets update "gs://${BUCKET}" --versioning

echo
echo "Ready. Now run:"
echo "  cd infra/terraform && terraform init && terraform plan"
