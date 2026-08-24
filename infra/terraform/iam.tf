# Service accounts, one per workload, each with only what it needs.
#
# The agents SA is the broad one because agents genuinely touch everything;
# web and api are deliberately narrow so a compromised frontend cannot write
# to the ledger or run BigQuery jobs.

locals {
  service_accounts = {
    agents = {
      display_name = "MyWants agents and pipeline jobs"
      roles = [
        "roles/aiplatform.user",     # Gemini via GEAP
        "roles/datastore.user",      # Firestore read/write
        "roles/bigquery.jobUser",    # run queries
        "roles/bigquery.dataEditor", # write observations + signals
        "roles/storage.objectAdmin", # raw payloads, provenance, deliverables
        "roles/pubsub.publisher",
        "roles/pubsub.subscriber",
        "roles/cloudtasks.enqueuer",
        "roles/secretmanager.secretAccessor",
        "roles/cloudtrace.agent", # the observability story
        "roles/logging.logWriter",
      ]
    }

    api = {
      display_name = "MyWants FastAPI service"
      roles = [
        "roles/datastore.user",
        "roles/storage.objectViewer", # serve deliverables, never write them
        "roles/pubsub.publisher",     # publish wants-updated, opportunity-approved
        "roles/secretmanager.secretAccessor",
        "roles/cloudtrace.agent",
        "roles/logging.logWriter",
      ]
    }

    web = {
      display_name = "MyWants Next.js web app"
      roles = [
        "roles/datastore.user", # server components read Firestore directly
        "roles/logging.logWriter",
      ]
    }

    scheduler = {
      display_name = "MyWants Cloud Scheduler invoker"
      roles = [
        "roles/run.invoker", # trigger the pipeline on a cadence
      ]
    }
  }

  # Flatten {sa => [roles]} into one binding per (sa, role) pair.
  sa_role_pairs = merge([
    for sa_key, sa in local.service_accounts : {
      for role in sa.roles : "${sa_key}:${role}" => {
        sa_key = sa_key
        role   = role
      }
    }
  ]...)
}

resource "google_service_account" "accounts" {
  for_each = local.service_accounts

  account_id   = "mywants-${each.key}"
  display_name = each.value.display_name
}

resource "google_project_iam_member" "bindings" {
  for_each = local.sa_role_pairs

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.accounts[each.value.sa_key].email}"
}

# Cloud Build deploys to Cloud Run and must be able to act as the runtime
# service accounts. Without actAs, deploys fail with a confusing permission
# error that does not mention impersonation.
resource "google_project_iam_member" "cloudbuild_deployer" {
  for_each = toset([
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.writer",
    "roles/logging.logWriter",
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com"
}
