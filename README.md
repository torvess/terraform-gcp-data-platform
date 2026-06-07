# terraform-gcp-data-platform

Infrastructure as Code (IaC) for a GCP data platform using Terraform. This project provisions a full data platform architecture across isolated GCP projects, separating concerns between environments (dev/prd) and layers (data lake and data warehouse).

Changes to infrastructure are managed via Pull Requests — a GitHub Actions workflow runs `terraform plan` automatically on every PR and `terraform apply` after merge, with mandatory approval before deploying to production.

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

> In a production environment, these projects would be organized under GCP folders (platform, datalake, datawarehouse) within a GCP Organization. This setup reflects the same logical separation without requiring an organization account.

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
├── .github/
│   └── workflows/
│       └── terraform-apply.yml  ← CI/CD pipeline for plan and apply
│
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
    │   │   ├── main.tf
    │   │   ├── backend.tf
    │   │   ├── variables.tf
    │   │   └── terraform.tfvars
    │   └── datawarehouse/       ← Calls datawarehouse module with dev config
    │       ├── main.tf
    │       ├── backend.tf
    │       ├── variables.tf
    │       └── terraform.tfvars
    └── prd/
        ├── datalake/            ← Calls datalake module with prd config
        │   ├── main.tf
        │   ├── backend.tf
        │   ├── variables.tf
        │   └── terraform.tfvars
        └── datawarehouse/       ← Calls datawarehouse module with prd config
            ├── main.tf
            ├── backend.tf
            ├── variables.tf
            └── terraform.tfvars
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
| `google_storage_bucket_iam_member` | IAM binding per data engineer (bucket level) |

**Differences between environments:**
- `dev` → `force_destroy = true`, no versioning, lifecycle of 30 days
- `prd` → `force_destroy = false`, versioning enabled, lifecycle of 90 days

### datawarehouse-dev / datawarehouse-prd
| Resource | Description |
|---|---|
| `google_bigquery_dataset` | Datasets: bronze, silver, gold |
| `google_bigquery_dataset_iam_member` | IAM binding per data engineer (dataset level) |

**Differences between environments:**
- `dev` → `delete_contents_on_destroy = true`
- `prd` → `delete_contents_on_destroy = false`

---

## Terraform State

Each environment has its own isolated state file stored in the remote GCS bucket in `platform-infra`:

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

## CI/CD — GitHub Actions

Every infrastructure change goes through a Pull Request workflow:

```
open PR targeting main (changes in environments/**)
        │
        └── terraform plan runs automatically on all 4 environments
                │
                └── plan output posted as PR comment
                        │
                        └── merge PR
                                │
                                └── mandatory approval required (production environment)
                                        │
                                        └── terraform apply runs on all 4 environments
```

### Workflow jobs

| Job | Trigger | What it does |
|---|---|---|
| `terraform-plan` | Pull request | Runs `terraform plan` and posts output as PR comment |
| `terraform-apply` | Push to main | Runs `terraform apply` after manual approval |

### Required secrets

| Secret | Description |
|---|---|
| `GCP_CREDENTIALS` | Service account JSON key with Editor role on all projects |

### Setting up the service account

```bash
# create service account in platform-infra
gcloud iam service-accounts create github-actions \
  --project=platform-infra-XXXX \
  --display-name="GitHub Actions"

# grant Editor role on each project
gcloud projects add-iam-policy-binding <project-id> \
  --member="serviceAccount:github-actions@platform-infra-XXXX.iam.gserviceaccount.com" \
  --role="roles/editor"

# grant BigQuery Data Owner on datawarehouse projects
gcloud projects add-iam-policy-binding <datawarehouse-project-id> \
  --member="serviceAccount:github-actions@platform-infra-XXXX.iam.gserviceaccount.com" \
  --role="roles/bigquery.dataOwner"

# generate key and add to GitHub secrets as GCP_CREDENTIALS
gcloud iam service-accounts keys create key.json \
  --iam-account=github-actions@platform-infra-XXXX.iam.gserviceaccount.com

# delete the key locally after adding to GitHub secrets
rm key.json
```

---

## Adding a New Member

To grant a user access to all environments, open a Pull Request:

**1. Create a branch**
```bash
git checkout -b feat/add-new-member
```

**2. Add the user to each environment's `main.tf`**
```hcl
# environments/dev/datalake/main.tf
# environments/dev/datawarehouse/main.tf
# environments/prd/datalake/main.tf
# environments/prd/datawarehouse/main.tf

data_engineer_members = [
  "user:existing@gmail.com",
  "user:new-member@gmail.com",   ← add here
]
```

**3. Commit and push**
```bash
git add .
git commit -m "feat: add new-member to all environments"
git push origin feat/add-new-member
```

**4. Open a Pull Request**

GitHub Actions will automatically run `terraform plan` and post the expected changes as a comment. After review and merge, `terraform apply` runs automatically.

---

## Initial Setup

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Git](https://git-scm.com/downloads)
- GCP account with 5 projects created and billing enabled
- Owner or Editor role on each project

### 1. Clone the repository

```bash
git clone https://github.com/torvess/terraform-gcp-data-platform
cd terraform-gcp-data-platform
```

### 2. Authenticate with GCP

```bash
gcloud init
gcloud auth application-default login
```

If using multiple GCP accounts (e.g. personal and corporate):

```bash
# create a named configuration for this project
gcloud config configurations create portfolio
gcloud config configurations activate portfolio
gcloud auth application-default login
```

### 3. Create the terraform.tfvars files

These files are not committed to the repository. Create them locally:

```
bootstrap/terraform.tfvars
environments/dev/datalake/terraform.tfvars
environments/dev/datawarehouse/terraform.tfvars
environments/prd/datalake/terraform.tfvars
environments/prd/datawarehouse/terraform.tfvars
```

Each file follows this pattern:
```hcl
project_id = "<your-gcp-project-id>"
region     = "us-central1"
```

### 4. Bootstrap — create remote state bucket

```bash
cd bootstrap
terraform init
terraform apply
```

After apply, update `bootstrap/backend.tf` to use the GCS bucket:

```hcl
terraform {
  backend "gcs" {
    bucket = "<your-platform-infra-project-id>-tfstate"
    prefix = "bootstrap"
  }
}
```

Then migrate the local state:
```bash
terraform init -migrate-state
```

### 5. Apply each environment

```bash
# dev
cd environments/dev/datalake && terraform init && terraform apply
cd ../datawarehouse && terraform init && terraform apply

# prd
cd ../../prd/datalake && terraform init && terraform apply
cd ../datawarehouse && terraform init && terraform apply
```

---

## References

- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Language Documentation](https://developer.hashicorp.com/terraform/language)
- [GCP IAM Roles — Cloud Storage](https://cloud.google.com/storage/docs/access-control/iam-roles)
- [GCP IAM Roles — BigQuery](https://cloud.google.com/bigquery/docs/access-control)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)