module "datalake" {
  source = "../../../modules/datalake"

  project_id  = var.project_id
  region      = var.region
  environment = "prd"

  data_engineer_members = [
    "user:igor.torves.sl@gmail.com",
    "user:igor.torves@grwt.com.br",
    "user:email.teste@gmail.com",
  ]
}