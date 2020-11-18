terraform {
  backend "s3" {
    bucket         = "okury-terraformbackend"
    key            = "dev/task3/terraform.tfstate"
  }
}