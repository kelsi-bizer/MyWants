variable "project_id" {
  description = "GCP project ID."
  type        = string
  default     = "mywants-ai-hack26"
}

variable "region" {
  description = <<-EOT
    Region for Firestore, Cloud Run, Pub/Sub, Cloud Tasks, and GCS.

    NOT used for BigQuery — see var.bigquery_location.
    NOT used for Gemini generative calls — those go to the `global` endpoint.
    See docs/platform-notes.md for why the three differ.
  EOT
  type        = string
  default     = "us-central1"
}

variable "bigquery_location" {
  description = <<-EOT
    BigQuery dataset location. MUST be the `US` multi-region.

    BigQuery cannot reference datasets across locations, and single-region
    locations do NOT match multi-region ones even when geographically
    contained -- `us-central1` is not `US` for query purposes.

    The `bigquery-public-data` datasets we ingest from (Census ACS, World Bank
    WDI, BLS) live in the `US` multi-region. Any query that reads them and
    writes into `mywants.observations` requires both in the same location, so
    this must stay `US`.

    Changing this later means recreating the dataset and every table in it.
  EOT
  type        = string
  default     = "US"

  validation {
    condition     = var.bigquery_location == "US"
    error_message = "Must be 'US' to join bigquery-public-data. See the description above before overriding."
  }
}

variable "firestore_location" {
  description = <<-EOT
    Firestore database location. PERMANENT -- not editable after creation.
    Changing it requires deleting and recreating the database.
  EOT
  type        = string
  default     = "us-central1"
}

variable "labels" {
  description = "Labels applied to every resource that supports them."
  type        = map(string)
  default = {
    app        = "mywants-ai"
    managed-by = "terraform"
  }
}
