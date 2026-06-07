variable "project_id" {
    description = "ID do projeto GCP onde os datasets serão criados"
    type        = string
}

variable "region" {
    description = "Região dos datasets no BigQuery"
    type        = string
    default     = "us-central1"
}

variable "environment" {
    description = "Ambiente (dev ou prd)"
    type        = string
}

variable "data_engineer_members" {
    description = "Lista de usuários com acesso aos datasets"
    type        = list(string)
    default     = []
}

