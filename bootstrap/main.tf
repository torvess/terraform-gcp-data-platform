terraform {
    required_version = ">= 1.5"

    required_providers {
        google = {
            source  = "hashicorp/google"
            version = "~> 5.0"
        }
    }

    # backend "local" {}
}

provider "google" {
    project = var.project_id
    region  = var.region
}

resource "google_storage_bucket" "terraform_state" {
    name            = "${var.project_id}-tfstate"
    location        = var.region
    force_destroy   = false

    versioning {
        enabled = true
    }

    uniform_bucket_level_access = true

    labels = {
        managed_by  = "terraform"
        environment = "platform"
    }

}

resource "google_project_service" "apis" {
    for_each = toset([
        "storage.googleapis.com",
        "cloudresourcemanager.googleapis.com",
        "iam.googleapis.com",
        "serviceusage.googleapis.com",
    ])

    project             = var.project_id
    service             = each.value
    disable_on_destroy  = false
}