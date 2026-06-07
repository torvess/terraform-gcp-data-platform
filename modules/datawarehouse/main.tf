locals {
    layers = ["bronze", "silver", "gold"]
}

resource "google_bigquery_dataset" "layers" {
    for_each = toset(local.layers)

    dataset_id = each.value
    project = var.project_id
    location = var.region
    description = "Camada ${each.value} - gerenciado por Terraform"

    delete_contents_on_destroy = var.environment == "dev" ? true : false

    labels = {
        managed_by = "terraform"
        environment = var.environment
        layer = each.value
    }
}