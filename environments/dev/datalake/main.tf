module "datalake" {
  source = "../../../modules/datalake"

  project_id  = var.project_id
  region      = var.region
  environment = "dev"

  data_engineer_members = [
    "user:igor.torves.sl@gmail.com"
  ]
}