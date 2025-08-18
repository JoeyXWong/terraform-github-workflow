terraform {
  required_version = ">= 1.0"
  required_providers {
    mongodbatlas = {
      source  = "mongodb/mongodbatlas"
      version = "~> 1.37"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "mongodbatlas" {
  public_key  = var.mongodb_atlas_public_key
  private_key = var.mongodb_atlas_private_key
}

provider "aws" {
  region = var.aws_region
}


resource "mongodbatlas_cluster" "main" {
  project_id = "631fe0432febff28714358b8"
  name       = var.cluster_name

  # Free tier M0 configuration
  provider_name               = "TENANT"
  backing_provider_name       = var.cloud_provider
  provider_region_name        = var.mongodb_region
  provider_instance_size_name = "M0"

  # MongoDB version
  mongo_db_major_version = var.mongodb_version

  # Storage and backup (limited on M0)
  auto_scaling_disk_gb_enabled = false
  
  # Advanced configuration
  advanced_configuration {
    javascript_enabled                   = true
    minimum_enabled_tls_protocol        = "TLS1_2"
    no_table_scan                       = false
    oplog_size_mb                       = 1024
    sample_size_bi_connector            = 5000
    sample_refresh_interval_bi_connector = 300
  }

  # Termination protection
  termination_protection_enabled = false
}
