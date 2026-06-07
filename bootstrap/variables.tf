variable "project_id" {
    description = "ID do projeto GCP do platform-infra"
    type        = string
}

variable "region" {
    description = "Região padrão dos recursos GCP"
    type        = string
    default     = "us-central1"
}