terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  # State lives in GCS so the environment survives a Cloud Shell VM recycle.
  # Create the bucket first: bash scripts/bootstrap-tfstate.sh
  backend "gcs" {
    bucket = "mywants-ai-hack26-tfstate"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
