output "dataset_ids" {
  description = "IDs dos datasets criados por camada"
  value = {
    for layer, dataset in google_bigquery_dataset.layers :
    layer => dataset.dataset_id
  }
}

output "dataset_self_links" {
  description = "Self links dos datasets por camada"
  value = {
    for layer, dataset in google_bigquery_dataset.layers :
    layer => dataset.self_link
  }
}