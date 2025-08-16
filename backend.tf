terraform {
  backend "s3" {
    bucket  = "terraform-mdb"
    key     = "mongodb-atlas/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}