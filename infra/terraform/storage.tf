# Cloud Storage: raw source payloads, provenance snapshots, and the
# deliverables AI workers produce after an Entity activates.

locals {
  buckets = {
    raw = {
      description = "Untransformed source payloads. The provenance anchor -- every observation points back to a URI here."
      age_days    = 90
      versioning  = false
    }
    provenance = {
      description = "Immutable evidence chains: source, indicator, observed value, historical comparison, transformations, AI interpretation."
      age_days    = 0 # never expire -- this is the trust story
      versioning  = true
    }
    deliverables = {
      description = "Artifacts produced by AI worker agents for activated Entities: brand briefs, landing copy, market analyses."
      age_days    = 0
      versioning  = true
    }
  }
}

resource "google_storage_bucket" "buckets" {
  for_each = local.buckets

  name     = "${var.project_id}-${each.key}"
  location = var.region
  labels   = merge(var.labels, { purpose = each.key })

  # Every access goes through IAM. No per-object ACLs to reason about.
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = each.value.versioning
  }

  dynamic "lifecycle_rule" {
    for_each = each.value.age_days > 0 ? [each.value.age_days] : []
    content {
      condition {
        age = lifecycle_rule.value
      }
      action {
        type = "Delete"
      }
    }
  }
}
