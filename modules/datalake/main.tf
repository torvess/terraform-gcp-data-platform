locals {
    layers = ["raw"]
}

resource "google_storage_bucket" "layers" {
    for_each = toset(local.layers)

    name     = "${var.project_id}-${each.value}"
    project  = var.project_id
    location = var.region
    force_destroy = var.environment == "dev" ? true : false

    versioning {
        enabled = var.environment == "prd" ? true : false
    }

    uniform_bucket_level_access = true

    lifecycle_rule {
        condition {
            age = var.environment == "prd" ? 90 : 30
        }
        action {
            type = "Delete"
        }
    }

    labels = {
        managed_by = "terraform"
        environment = var.environment
        layer       = each.value
    }
}

