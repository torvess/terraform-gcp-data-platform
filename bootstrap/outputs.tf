output "terraform_state_bucket" {
    description = "Nome do bucket que vai guardar o TF state dos outros projetos"
    value       = google_storage_bucket.terraform_state.name
}

output "terraform_state_bucket_url" {
    description = "URL do bucket para usar no backend.tf dos environments"
    value       = google_storage_bucket.terraform_state.url
}