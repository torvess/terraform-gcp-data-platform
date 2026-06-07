# terraform-gcp-data-platform

Infrastructure as Code for a GCP data platform using Terraform. This project provisions a full data platform architecture across isolated GCP projects, separating concerns between environments (dev/prd) and layers (data lake and data warehouse).

---

## Architecture

```
GCP (personal account)
│
├── platform-infra          ← Terraform bootstrap: remote state, APIs, IAM
│
├── datalake-dev            ← GCS bucket: raw layer (development)
├── datalake-prd            ← GCS bucket: raw layer (production)
│
├── datawarehouse-dev       ← BigQuery datasets: bronze / silver / gold (development)
└── datawarehouse-prd       ← BigQuery datasets: bronze / silver / gold (production)
```

### Data Flow

```
[Source]
    │
    ▼
GCS raw bucket          (datalake project)
    │
    ▼
BigQuery bronze         ← ingested and typed data
    │
    ▼
BigQuery silver         ← cleaned and transformed data
    │
    ▼
BigQuery gold           ← ready for consumption / BI
```

---

## Repository Structure

```
terraform/
├── bootstrap/                   ← Run once to create remote state bucket
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   └── terraform.tfvars
│
├── modules/
│   ├── datalake/                ← Reusable module: GCS bucket + IAM
│   │   ├── main.tf
│   │   ├── iam.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── datawarehouse/           ← Reusable module: BigQuery datasets + IAM
│       ├── main.tf
│       ├── iam.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── environments/
    ├── dev/
    │   ├── datalake/            ← Calls datalake module with dev config
    │   └── datawarehouse/       ← Calls datawarehouse module with dev config
    └── prd/
        ├── datalake/            ← Calls datalake module with prd config
        └── datawarehouse/       ← Calls datawarehouse module with prd config
```

---

## Resources Provisioned

### platform-infra
| Resource | Description |
|---|---|
| `google_storage_bucket` | Remote Terraform state bucket with versioning |
| `google_project_service` | Enables Storage, IAM, Resource Manager and Service Usage APIs |

### datalake-dev / datalake-prd
| Resource | Description |
|---|---|
| `google_storage_bucket` | GCS bucket for raw data |
| `google_storage_bucket_iam_member` | IAM binding for data engineers |

**Differences between environments:**
- `dev` → `force_destroy = true`, no versioning, lifecycle of 30 days
- `prd` → `force_destroy = false`, versioning enabled, lifecycle of 90 days

### datawarehouse-dev / datawarehouse-prd
| Resource | Description |
|---|---|
| `google_bigquery_dataset` | Datasets: bronze, silver, gold |
| `google_bigquery_dataset_iam_member` | IAM binding for data engineers |

**Differences between environments:**
- `dev` → `delete_contents_on_destroy = true`
- `prd` → `delete_contents_on_destroy = false`

---

## Terraform State

Each environment has its own isolated state file stored in the remote GCS bucket:

```
platform-infra-XXXX-tfstate/
├── bootstrap/default.tfstate
├── dev/
│   ├── datalake/default.tfstate
│   └── datawarehouse/default.tfstate
└── prd/
    ├── datalake/default.tfstate
    └── datawarehouse/default.tfstate
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- GCP account with 5 projects created and billing enabled
- Owner or Editor role on each project

---

## Setup

### 1. Authenticate with GCP

```bash
gcloud init
gcloud auth application-default login
```

### 2. Bootstrap — create remote state bucket

```bash
cd bootstrap
terraform init
terraform apply
```

After apply, migrate local state to the GCS bucket:

Update `bootstrap/backend.tf`:
```hcl
terraform {
  backend "gcs" {
    bucket = "<your-platform-infra-project-id>-tfstate"
    prefix = "bootstrap"
  }
}
```

Then run:
```bash
terraform init -migrate-state
```

### 3. Configure each environment

Fill in `terraform.tfvars` for each environment with the correct GCP project ID:

```
environments/dev/datalake/terraform.tfvars       ← datalake-dev project ID
environments/dev/datawarehouse/terraform.tfvars  ← datawarehouse-dev project ID
environments/prd/datalake/terraform.tfvars       ← datalake-prd project ID
environments/prd/datawarehouse/terraform.tfvars  ← datawarehouse-prd project ID
```

### 4. Apply each environment

```bash
# dev
cd environments/dev/datalake && terraform init && terraform apply
cd ../datawarehouse && terraform init && terraform apply

# prd
cd ../../prd/datalake && terraform init && terraform apply
cd ../datawarehouse && terraform init && terraform apply
```

---

## Switching Between Accounts (multi-account setup)

If you use multiple GCP accounts (e.g. personal and corporate), use gcloud configurations:

```bash
# create a named configuration
gcloud config configurations create portfolio

# activate personal account
gcloud config configurations activate portfolio
gcloud auth application-default login

# switch back to corporate account
gcloud config configurations activate default
gcloud auth application-default login
```

---

## References

- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)
- [GCP IAM Roles — Cloud Storage](https://cloud.google.com/storage/docs/access-control/iam-roles)
- [GCP IAM Roles — BigQuery](https://cloud.google.com/bigquery/docs/access-control)
