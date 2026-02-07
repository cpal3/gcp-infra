terraform {
  backend "gcs" {
    bucket  = "ingr-seed-project-tfstate"
    prefix  = "terraform/bootstrap"
  }
}
