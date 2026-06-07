resource "google_bigquery_dataset_iam_member" "data_engineer" {
  for_each = {
    for pair in setproduct(toset(local.layers), toset(var.data_engineer_members)) :
    "${pair[0]}-${pair[1]}" => pair
  }

  project    = var.project_id
  dataset_id = google_bigquery_dataset.layers[each.value[0]].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = each.value[1]
}