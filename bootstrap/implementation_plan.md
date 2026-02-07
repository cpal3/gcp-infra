# Implementation Plan - GitHub Actions for Terraform

## Goal
Set up a GitHub Actions workflow to automate the Terraform lifecycle (plan and apply) for the **bootstrap** environment. This ensures that future changes are applied consistently via CI/CD.

## User Review Required
- **Repository Secrets**: You will need to ensure your GitHub repository is configured with any necessary secrets (though WIF avoids the need for long-lived keys, checking for other secrets like `TF_VAR_org_id` might be needed if not hardcoded).
- **Branch Protection**: We will configure the workflow to run `plan` on Pull Requests and `apply` on pushes to `main`.

## Proposed Changes

### [Root Directory]
#### [NEW] .github/workflows/terraform-bootstrap.yaml
- **Trigger**:
    - `pull_request` on `master` or `main` (paths: `bootstrap/**`) -> Runs `terraform plan`
    - `push` to `master` or `main` (paths: `bootstrap/**`) -> Runs `terraform apply`
- **Permissions**: `id-token: write` (Required for WIF), `contents: read`
- **Steps**:
    1.  Checkout Code
    2.  Authenticate to Google Cloud (using WIF provider from bootstrap)
    3.  Setup Terraform
    4.  Terraform Init
    5.  Terraform Plan (on PR)
    6.  Terraform Apply (on Push to Main)

## Verification Plan

### Automated Tests
- We cannot run the GitHub Action locally easily.
- **Verification**: Commit this file, push to GitHub, and verify the "Actions" tab shows a successful run (or at least a successful `plan`).

### Manual Verification
- Review the generated YAML file to ensure the WIF Provider string matches the output from the bootstrap step.
