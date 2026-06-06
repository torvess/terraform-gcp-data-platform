terraform {
  backend "gcs" {
    bucket = "platform-infra-498617-tfstate"
    prefix = "dev/datawarehouse"
  }
}