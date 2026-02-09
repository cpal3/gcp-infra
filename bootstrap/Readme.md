# GCP Terraform Bootstrap

This directory contains the **initial configuration** to bootstrap your Google Cloud Platform (GCP) environment. It sets up the "Seed Project" which acts as the control plane for all subsequent infrastructure.

## What this creates

1.  **Seed Project**: A dedicated project to host Terraform state and CI/CD identity.
2.  **GCS Bucket**: A single bucket to store Terraform state for *all* your environments (Bootstrap, Foundation, Networking, Prod, Non-Prod).
3.  **Service Account**: A "Terraform Runner" service account that CI/CD pipelines will impersonate.
4.  **Workload Identity Federation**: Configures trust between GitHub Actions and GCP, allowing keyless authentication.

## Prerequisites

1.  **Google Cloud SDK** installed and authenticated (`gcloud auth login`).
2.  **Terraform** installed (>= 1.0).
3.  **Permissions**: You must have `roles/resourcemanager.projectCreator` and `roles/billing.user` on the Organization or Folder where you are creating this using your **personal admin account**.

## Setup Instructions

### Phase 1: Local State (The "Chicken and Egg" Step)

Since the GCS bucket doesn't exist yet, we must first run Terraform with **local state** to create it.

1.  **Configure Variables**:
    Copy the example file and fill in your details.
    ```bash
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars with your Org ID, Billing ID, and GitHub Repo (user/repo)
    ```

2.  **Initialize**:
    ```bash
    terraform init
    ```

3.  **Apply**:
    ```bash
    terraform apply
    ```
    Review the plan. It will create the Project, Bucket, Service Account, and WIF Pool. Type `yes`.

4.  **Note Outputs**:
    Take note of the `terraform_state_bucket` and `workload_identity_provider` outputs.

---

### Phase 2: Migrate to Remote State

Now that the bucket exists, we will move the local `terraform.tfstate` file to the GCS bucket.

1.  **Create `backend.tf`**:
    Create a new file named `backend.tf` in this directory with the following content (replace `YOUR_BUCKET_NAME` with the output from Step 4):

    ```hcl
    terraform {
      backend "gcs" {
        bucket  = "YOUR_BUCKET_NAME"
        prefix  = "terraform/bootstrap"
      }
    }
    ```

2.  **Migrate**:
    Run the init command again. Terraform will detect the backend change and ask to migrate the state.
    ```bash
    terraform init -migrate-state
    ```
    Type `yes` when prompted.

**Success!** Your bootstrap state is now securely stored in GCS. You can delete the local `terraform.tfstate` and `terraform.tfstate.backup` files.

## Portability: Using this for Any Organization

This codebase is designed to be reusable across different GCP Organizations. To deploy to a new Org:

1.  **Repository**: Clone or fork this repo.
2.  **Phase 1 (Local)**: Run the steps in "Phase 1" using the new `org_id` and `billing_account`.
3.  **Manual Unlock**: Follow the "Security & IAM" section below to grant the 4 mandatory roles to the new Service Account.
4.  **GitHub Secrets**: Update the GitHub Repository Secrets with the values for the new Organization.

### Manual vs. Automated Split

| Task | Manual (One-Time) | Automated (Terraform) |
| :--- | :---: | :---: |
| Create Seed Project & Bucket | **Yes** (Phase 1) | No (Controlled by local apply) |
| Grant WIF/Bucket Admin to Runner | No | **Yes** (via `bootstrap/main.tf`) |
| Grant Org-Level Roles (Folders, etc.)| **Yes** (Initial unlock) | **Yes** (via `iam_roles.yaml`) |
| Manage Folders & Environment Projects| No | **Yes** (via Foundation pipeline) |

---

## Security & IAM

To avoid "Permission Denied" errors during the initial bootstrap, you must manually grant several roles to the **Terraform Runner Service Account** at the **Organization Level**.

### Mandatory Manual Roles
Grant these roles to `terraform-runner@...` using the GCP Console (ensure you select the **Organization** in the top dropdown):

1.  **Organization IAM Administrator** (`roles/resourcemanager.organizationIamAdmin`): 
    *Why?* Required so the Bootstrap pipeline can manage the roles listed in `iam_roles.yaml`.
2.  **Organization Viewer** (`roles/resourcemanager.organizationViewer`): 
    *Why?* Required for Terraform to see organizational resources.
3.  **Billing Account User** (`roles/billing.user`): 
    *Why?* Required to attach billing accounts to new projects.
4.  **Folder Admin** (`roles/resourcemanager.folderAdmin`): 
    *Why?* Required to create the initial folder hierarchy.

Once these are granted **one time**, the Bootstrap pipeline will be "unlocked" and can manage its own future role updates via the `iam_roles.yaml` file.

---

## Next Steps

1.  **Configure GitHub Actions**:
    Use the `workload_identity_provider` output in your GitHub Actions YAML:
    ```yaml
    - uses: "google-github-actions/auth@v2"
      with:
        workload_identity_provider: "projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider"
        service_account: "terraform-runner@seed-project-123.iam.gserviceaccount.com"
    ```