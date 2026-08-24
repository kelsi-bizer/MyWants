# BigQuery: the observations warehouse and deterministic signal detection.
#
# Location is the `US` multi-region -- see var.bigquery_location for why this
# is not negotiable.

resource "google_bigquery_dataset" "mywants" {
  dataset_id  = "mywants"
  location    = var.bigquery_location
  description = "MyWants AI observations warehouse and signal detection."
  labels      = var.labels
}

# ---------------------------------------------------------------------------
# observations -- the canonical normalized record every connector writes into.
# ---------------------------------------------------------------------------
resource "google_bigquery_table" "observations" {
  dataset_id          = google_bigquery_dataset.mywants.dataset_id
  table_id            = "observations"
  deletion_protection = false
  labels              = var.labels

  description = "Canonical normalized observations from every registered data source."

  time_partitioning {
    type  = "DAY"
    field = "period"
  }

  # Signal detection always filters by source + indicator + geography.
  clustering = ["source_id", "indicator", "geography"]

  schema = jsonencode([
    { name = "observation_id", type = "STRING", mode = "REQUIRED", description = "Deterministic hash of source+indicator+geography+period. Idempotency key." },
    { name = "source_id", type = "STRING", mode = "REQUIRED", description = "FK to the Firestore data_sources registry." },
    { name = "indicator", type = "STRING", mode = "REQUIRED", description = "Canonical indicator code, e.g. POP_TOTAL." },
    { name = "geography", type = "STRING", mode = "REQUIRED", description = "ISO-3166 country, US state FIPS, or metro code." },
    { name = "geography_level", type = "STRING", mode = "NULLABLE", description = "country | state | metro | county." },
    { name = "period", type = "DATE", mode = "REQUIRED", description = "Observation period start. Partition key." },
    { name = "period_grain", type = "STRING", mode = "NULLABLE", description = "year | quarter | month." },
    { name = "value", type = "FLOAT64", mode = "NULLABLE" },
    { name = "unit", type = "STRING", mode = "NULLABLE" },
    { name = "category", type = "STRING", mode = "NULLABLE", description = "One of the seven MVP categories." },
    { name = "raw_payload_uri", type = "STRING", mode = "NULLABLE", description = "GCS URI of the untransformed source payload. Provenance anchor." },
    { name = "ingest_run_id", type = "STRING", mode = "REQUIRED", description = "Groups every row written by one pipeline run." },
    { name = "ingested_at", type = "TIMESTAMP", mode = "REQUIRED" },
  ])
}

# ---------------------------------------------------------------------------
# signals -- output of ChangeDetectionAgent. Written by SQL, never by an LLM.
# ---------------------------------------------------------------------------
resource "google_bigquery_table" "signals" {
  dataset_id          = google_bigquery_dataset.mywants.dataset_id
  table_id            = "signals"
  deletion_protection = false
  labels              = var.labels

  description = "Deterministically detected changes. The model interprets these; it never measures them."

  time_partitioning {
    type  = "DAY"
    field = "detected_at"
  }

  clustering = ["method", "indicator", "geography"]

  schema = jsonencode([
    { name = "signal_id", type = "STRING", mode = "REQUIRED" },
    { name = "source_id", type = "STRING", mode = "REQUIRED" },
    { name = "indicator", type = "STRING", mode = "REQUIRED" },
    { name = "geography", type = "STRING", mode = "REQUIRED" },
    { name = "category", type = "STRING", mode = "NULLABLE" },
    { name = "period", type = "DATE", mode = "REQUIRED" },
    { name = "method", type = "STRING", mode = "REQUIRED", description = "yoy | cagr | zscore | rank_shift | breakpoint." },
    { name = "observed_value", type = "FLOAT64", mode = "NULLABLE" },
    { name = "comparison_value", type = "FLOAT64", mode = "NULLABLE", description = "The historical baseline compared against." },
    { name = "magnitude", type = "FLOAT64", mode = "NULLABLE", description = "Size of the change in the method's own units." },
    { name = "direction", type = "STRING", mode = "NULLABLE", description = "rising | falling | flat." },
    { name = "strength", type = "FLOAT64", mode = "NULLABLE", description = "Normalized 0-1 for ranking across methods." },
    { name = "provenance_id", type = "STRING", mode = "REQUIRED", description = "FK to the Firestore provenance chain." },
    { name = "detected_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "detection_run_id", type = "STRING", mode = "REQUIRED" },
  ])
}

# ---------------------------------------------------------------------------
# backtest_runs -- replays history to test whether the engine WOULD have
# caught known market gaps. This is what turns "our AI finds opportunities"
# from a claim into a number.
# ---------------------------------------------------------------------------
resource "google_bigquery_table" "backtest_runs" {
  dataset_id          = google_bigquery_dataset.mywants.dataset_id
  table_id            = "backtest_runs"
  deletion_protection = false
  labels              = var.labels

  description = "Historical replay results: did the engine surface a known gap from data available at the time?"

  schema = jsonencode([
    { name = "backtest_id", type = "STRING", mode = "REQUIRED" },
    { name = "scenario", type = "STRING", mode = "REQUIRED", description = "Human-readable name of the known gap being tested." },
    { name = "as_of_period", type = "DATE", mode = "REQUIRED", description = "Data after this date is withheld from the run." },
    { name = "expected_indicator", type = "STRING", mode = "NULLABLE" },
    { name = "expected_geography", type = "STRING", mode = "NULLABLE" },
    { name = "detected", type = "BOOL", mode = "REQUIRED", description = "Did the engine surface it?" },
    { name = "detected_rank", type = "INT64", mode = "NULLABLE", description = "Position in the scored opportunity list, if detected." },
    { name = "signals_considered", type = "INT64", mode = "NULLABLE" },
    { name = "notes", type = "STRING", mode = "NULLABLE" },
    { name = "run_at", type = "TIMESTAMP", mode = "REQUIRED" },
  ])
}

# ---------------------------------------------------------------------------
# entity_performance -- closes the feedback loop:
# Data -> Opportunity -> Entity -> Performance -> Better Data Model
# ---------------------------------------------------------------------------
resource "google_bigquery_table" "entity_performance" {
  dataset_id          = google_bigquery_dataset.mywants.dataset_id
  table_id            = "entity_performance"
  deletion_protection = false
  labels              = var.labels

  description = "Post-activation telemetry that feeds scoring-weight tuning."

  time_partitioning {
    type  = "DAY"
    field = "recorded_at"
  }

  schema = jsonencode([
    { name = "entity_id", type = "STRING", mode = "REQUIRED" },
    { name = "opportunity_id", type = "STRING", mode = "REQUIRED" },
    { name = "metric", type = "STRING", mode = "REQUIRED", description = "time_to_activation | manifest_fill_rate | milestone_completion | contributor_count." },
    { name = "value", type = "FLOAT64", mode = "NULLABLE" },
    { name = "composite_score_at_approval", type = "FLOAT64", mode = "NULLABLE", description = "Lets us correlate predicted score against realized outcome." },
    { name = "recorded_at", type = "TIMESTAMP", mode = "REQUIRED" },
  ])
}
