# Firestore Native: operational state plus native vector search for Want
# clustering, which is why we don't need a separate vector database.

resource "google_firestore_database" "mywants" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.firestore_location
  type        = "FIRESTORE_NATIVE"

  # Firestore location is PERMANENT. Guard against an accidental replace.
  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Vector index on wants.embedding is NOT managed here.
#
# The provider's vector_config schema is new enough that getting the field
# ordering wrong fails at apply time, and a broken apply blocks every later
# task. Firestore vector indexes are created by a documented, idempotent
# gcloud call instead:
#
#   bash scripts/create-vector-index.sh
#
# Everything durable stays in Terraform; this one index is a single
# create-once command that cannot drift.
# ---------------------------------------------------------------------------

# Opportunity review queue: the admin console lists by status, newest first.
resource "google_firestore_index" "opportunities_by_status" {
  project    = var.project_id
  database   = google_firestore_database.mywants.name
  collection = "opportunities"

  fields {
    field_path = "status"
    order      = "ASCENDING"
  }

  fields {
    field_path = "composite_score"
    order      = "DESCENDING"
  }

  fields {
    field_path = "__name__"
    order      = "DESCENDING"
  }
}

# Manifest items: the ActivationWatcher asks "any unsatisfied required items
# left on this entity?" on every contribution write.
resource "google_firestore_index" "manifest_items_by_entity" {
  project    = var.project_id
  database   = google_firestore_database.mywants.name
  collection = "manifest_items"

  fields {
    field_path = "entity_id"
    order      = "ASCENDING"
  }

  fields {
    field_path = "satisfied"
    order      = "ASCENDING"
  }

  fields {
    field_path = "__name__"
    order      = "ASCENDING"
  }
}

# Agent registry: FleetDispatcher matches open AI-worker items to agents by
# capability, filtered to those the governance layer currently trusts.
resource "google_firestore_index" "agent_registry_by_capability" {
  project    = var.project_id
  database   = google_firestore_database.mywants.name
  collection = "agent_registry"

  fields {
    field_path   = "capabilities"
    array_config = "CONTAINS"
  }

  fields {
    field_path = "trust_tier"
    order      = "ASCENDING"
  }

  fields {
    field_path = "__name__"
    order      = "ASCENDING"
  }
}
