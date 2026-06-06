variable "project_id" {
    description = "ID do projeto GCP onde os buckets serão criados"
    type        = string
}

variable "region" {
    description = "Região dos buckets"
    type        = string
    default     = "us-central1"
}

variable "environment" {
    description = "Ambiente (dev ou prd)"
    type        = string
}

variable "data_engineer_members" {
    description = "Lista de usuários com acesso de leitura e escrita nos buckets"
    type        = list(string)
    default     = []
}

