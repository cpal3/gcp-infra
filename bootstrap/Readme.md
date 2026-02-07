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

---

## Next Steps

1.  **Grant Permissions**:
    The created Service Account (`terraform-runner@...`) needs permissions to create folders and projects in your Organization. Grant it `roles/resourcemanager.folderAdmin` and `roles/resourcemanager.projectCreator` at the Organization level.

2.  **Configure GitHub Actions**:
    Use the `workload_identity_provider` output in your GitHub Actions YAML:
    ```yaml
    - uses: "google-github-actions/auth@v1"
      with:
        workload_identity_provider: "projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-provider"
        service_account: "terraform-runner@seed-project-123.iam.gserviceaccount.com"
    ```