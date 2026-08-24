# Artifact Registry, Secret Manager, and the budget alert that keeps a
# runaway BigQuery scan from becoming a surprise.

resource "google_artifact_registry_repository" "containers" {
  location      = var.region
  repository_id = "mywants"
  format        = "DOCKER"
  description   = "Container images for MyWants Cloud Run services and jobs."
  labels        = var.labels

  # Keep the registry from accumulating every intermediate build over 8 days
  # of high-velocity pushes.
  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }
}

# ---------------------------------------------------------------------------
# Secrets. Values are NOT set here -- Terraform state would capture them.
# Populate with:
#   echo -n "sk_test_..." | gcloud secrets versions add stripe-test-key --data-file=-
# ---------------------------------------------------------------------------
resource "google_secret_manager_secret" "secrets" {
  for_each = toset([
    "stripe-test-key",
  ])

  secret_id = each.key
  labels    = var.labels

  replication {
    auto {}
  }
}
