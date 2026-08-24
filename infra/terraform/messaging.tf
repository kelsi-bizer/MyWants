# Pub/Sub carries the pipeline between stages, and Cloud Tasks carries
# long-running A2A agent work.
#
# Every topic gets a dead-letter topic. A stage that fails five times parks
# its message rather than retrying forever or dropping it silently -- on
# Day 6 the replay tooling reads from these.

locals {
  # The Data Opportunity Loop, one topic per transition.
  topics = [
    "ingest-requested",     # Scheduler -> IngestAgent
    "observations-landed",  # IngestAgent -> ChangeDetectionAgent
    "signals-detected",     # ChangeDetectionAgent -> SignalFusionAgent
    "wants-updated",        # Want capture -> WantClusterAgent
    "mismatches-found",     # SignalFusionAgent -> OpportunityAgent
    "opportunity-scored",   # ScoringAgent -> review queue
    "opportunity-approved", # admin approval -> EntityPlannerAgent
    "entity-planned",       # EntityPlannerAgent -> ContributorMatchAgent
    "manifest-satisfied",   # ActivationWatcher -> FleetDispatcher
    "agent-task-dispatch",  # FleetDispatcher -> A2A workers
  ]
}

resource "google_pubsub_topic" "dead_letter" {
  name   = "dead-letter"
  labels = var.labels
}

resource "google_pubsub_topic" "topics" {
  for_each = toset(local.topics)

  name   = each.key
  labels = var.labels

  message_retention_duration = "604800s" # 7 days -- covers a full weekend outage
}

# One pull subscription per topic. Cloud Run push endpoints are wired in 0.6
# once the services exist and have URLs to push to.
resource "google_pubsub_subscription" "subscriptions" {
  for_each = toset(local.topics)

  name   = "${each.key}-sub"
  topic  = google_pubsub_topic.topics[each.key].id
  labels = var.labels

  ack_deadline_seconds       = 600 # agent stages are slow; 10 min avoids redelivery storms
  message_retention_duration = "604800s"

  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }

  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dead_letter.id
    max_delivery_attempts = 5
  }
}

# Pub/Sub's own service agent needs rights to publish into the DLQ and to ack
# on the source subscription. Without both, dead-lettering silently no-ops.
data "google_project" "current" {}

locals {
  pubsub_agent = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  topic  = google_pubsub_topic.dead_letter.id
  role   = "roles/pubsub.publisher"
  member = local.pubsub_agent
}

resource "google_pubsub_subscription_iam_member" "dlq_subscriber" {
  for_each = google_pubsub_subscription.subscriptions

  subscription = each.value.id
  role         = "roles/pubsub.subscriber"
  member       = local.pubsub_agent
}

# ---------------------------------------------------------------------------
# Cloud Tasks: A2A tasks can run for minutes. Pub/Sub's ack deadline caps at
# 10 minutes, so long-running agent work is dispatched here instead, with the
# A2A push-notification callback landing on the fleet service.
# ---------------------------------------------------------------------------
resource "google_cloud_tasks_queue" "agent_tasks" {
  name     = "agent-tasks"
  location = var.region

  rate_limits {
    max_dispatches_per_second = 10
    max_concurrent_dispatches = 20
  }

  retry_config {
    max_attempts  = 5
    min_backoff   = "5s"
    max_backoff   = "300s"
    max_doublings = 4
  }
}
