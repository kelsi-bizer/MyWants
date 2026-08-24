#!/usr/bin/env bash
# Create the Firestore vector index that powers Want clustering.
#
# Kept out of Terraform deliberately -- see the note in infra/terraform/firestore.tf.
# Idempotent: re-running when the index exists is a no-op.
#
#   bash scripts/create-vector-index.sh
#
set -uo pipefail

PROJECT_ID="${PROJECT_ID:-mywants-ai-hack26}"

# MUST match models.EMBEDDING_DIMENSIONS. A mismatch does not fail at index
# creation -- it fails later at query time, with an error that does not
# obviously point back to here.
DIMENSION=768

echo "Creating vector index on wants.embedding (${DIMENSION} dims)..."

OUTPUT=$(gcloud firestore indexes composite create \
  --project="${PROJECT_ID}" \
  --collection-group=wants \
  --query-scope=COLLECTION \
  --field-config="field-path=embedding,vector-config={\"dimension\":${DIMENSION},\"flat\":{}}" \
  2>&1) || true

if echo "${OUTPUT}" | grep -qi "already exists"; then
  echo "  already exists — nothing to do"
elif echo "${OUTPUT}" | grep -qiE "error|denied|invalid"; then
  echo "  FAILED:"
  echo "${OUTPUT}" | sed 's/^/    /'
  exit 1
else
  echo "  created (index build runs in the background; it is not queryable instantly)"
fi

echo
echo "Current wants indexes:"
gcloud firestore indexes composite list \
  --project="${PROJECT_ID}" \
  --filter="collectionGroup:wants" \
  --format="table(name.basename(), state)" 2>/dev/null || true
