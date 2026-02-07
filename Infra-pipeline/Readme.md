# Infrastructure Pipeline Strategy

This document outlines the operational strategy for deploying the GCP Landing Zone.

## Execution Model

| Layer | Component | Execution Method | Reason |
| :--- | :--- | :--- | :--- |
| **0** | **Bootstrap** | **Manual** (Local CLI) | Runs once to create the "Chicken and Egg" prerequisites (State Bucket, Seed Service Account). Depends on high-privileged personal credentials. |
| **1** | **Foundation** | **Pipeline** | Defines long-lived, structural resources (Folders, Policies). Should be version-controlled and approved via PRs. |
| **2** | **Networking** | **Pipeline** | Critical connectivity layer. Changes carry high risk and should go through rigorous CI/CD checks. |
| **3** | **Projects** | **Pipeline** | High frequency of changes (new apps/teams). Automated to ensure governance and speed. |

## Pipeline Workflow (Azure DevOps / GitHub Actions)

For Layers 1 (Foundation) and above, the pipeline should follow this standard flow:

1.  **Pull Request (PR) Trigger**:
    -   `terraform init`
    -   `terraform validate`
    -   `terraform plan` (Save output)
    -   **Post-step**: Comment the Plan output on the PR for review.

2.  **Merge to Main Trigger**:
    -   `terraform init`
    -   `terraform apply` (Auto-approve)

## Terraform Setup per Layer

Each layer (Foundation, Networking) must have its own `backend.tf` configuration pointing to the bucket created in Layer 0.

### Recommended State Structure
- `bootstrap`: `gs://<BOOTSTRAP_BUCKET>/terraform/bootstrap/default.tfstate`
- `foundation`: `gs://<BOOTSTRAP_BUCKET>/terraform/foundation/default.tfstate`
- `networking`: `gs://<BOOTSTRAP_BUCKET>/terraform/networking/default.tfstate`

## CI/CD Authentication: Workload Identity Federation (Best Practice)

Instead of using Service Account Keys (JSON), configure **Workload Identity Federation**.

### 1. Setup in Seed Project (Terraform)
Create a Workload Identity Pool and Provider in your **Seed Project**.

### 2. Connect from GitHub Actions
Use the `google-github-actions/auth` action.

```yaml
- id: 'auth'
  name: 'Authenticate to Google Cloud'
  uses: 'google-github-actions/auth@v1'
  with:
    workload_identity_provider: 'projects/123456789/locations/global/workloadIdentityPools/my-pool/providers/my-provider'
    service_account: 'terraform-runner@my-seed-project.iam.gserviceaccount.com'
```

### 3. Connect from Azure DevOps
create a Service Connection using "Workload Identity Federation" (Automatic) or Configure manual federation using `oidc` issuer URL.

**Benefits**:
- No secrets to rotate.
- Short-lived tokens.
- Auditable access.