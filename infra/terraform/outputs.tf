output "project_id" {
  value = var.project_id
}

output "locations" {
  description = "The three locations this project uses, and why they differ."
  value = {
    infrastructure = var.region            # Firestore, Cloud Run, Pub/Sub, Tasks, GCS
    bigquery       = var.bigquery_location # US multi-region, to join bigquery-public-data
    gemini         = "global"              # gemini-3.7-flash is not served in-region
    embeddings     = var.region            # co-located with Firestore
  }
}

output "service_account_emails" {
  value = { for k, sa in google_service_account.accounts : k => sa.email }
}

output "buckets" {
  value = { for k, b in google_storage_bucket.buckets : k => b.name }
}

output "bigquery_dataset" {
  value = "${var.project_id}.${google_bigquery_dataset.mywants.dataset_id}"
}

output "artifact_registry" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers.repository_id}"
}

output "pubsub_topics" {
  value = sort([for t in google_pubsub_topic.topics : t.name])
}
