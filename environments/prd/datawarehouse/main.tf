module "datawarehouse" {
  source = "../../../modules/datawarehouse"

  project_id  = var.project_id
  region      = var.region
  environment = "prd"

  data_engineer_members = [
    "user:igor.torves.sl@gmail.com"
  ]
}