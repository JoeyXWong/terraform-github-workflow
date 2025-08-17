output "project_id" {
  description = "MongoDB Atlas project ID"
  value       = mongodbatlas_project.main.id
}

output "cluster_id" {
  description = "MongoDB Atlas cluster ID"
  value       = mongodbatlas_cluster.main.cluster_id
}

output "cluster_name" {
  description = "MongoDB Atlas cluster name"
  value       = mongodbatlas_cluster.main.name
}

output "mongodb_version" {
  description = "MongoDB version"
  value       = mongodbatlas_cluster.main.mongo_db_version
}

output "connection_string_standard" {
  description = "Standard connection string for the cluster"
  value       = mongodbatlas_cluster.main.connection_strings[0].standard
  sensitive   = true
}

output "connection_string_standard_srv" {
  description = "Standard SRV connection string for the cluster"
  value       = mongodbatlas_cluster.main.connection_strings[0].standard_srv
  sensitive   = true
}

output "cluster_state" {
  description = "Current state of the cluster"
  value       = mongodbatlas_cluster.main.state_name
}

output "cluster_provider" {
  description = "Cloud provider hosting the cluster"
  value       = mongodbatlas_cluster.main.provider_name
}

output "cluster_region" {
  description = "Region where the cluster is deployed"
  value       = mongodbatlas_cluster.main.provider_region_name
}

output "cluster_instance_size" {
  description = "Instance size of the cluster"
  value       = mongodbatlas_cluster.main.provider_instance_size_name
}

output "database_users" {
  description = "List of database users created"
  value = {
    admin    = mongodbatlas_database_user.main.username
    app_user = var.create_app_user ? mongodbatlas_database_user.app_user[0].username : null
    readonly = var.create_readonly_user ? mongodbatlas_database_user.readonly_user[0].username : null
  }
}

output "project_settings" {
  description = "MongoDB Atlas project settings"
  value = {
    collect_database_specifics_statistics = mongodbatlas_project.main.is_collect_database_specifics_statistics_enabled
    data_explorer_enabled                 = mongodbatlas_project.main.is_data_explorer_enabled
    performance_advisor_enabled           = mongodbatlas_project.main.is_performance_advisor_enabled
    realtime_performance_panel_enabled    = mongodbatlas_project.main.is_realtime_performance_panel_enabled
    schema_advisor_enabled                = mongodbatlas_project.main.is_schema_advisor_enabled
  }
}

output "ip_access_list" {
  description = "IP access list configuration"
  value = {
    cidr_block = mongodbatlas_project_ip_access_list.main.cidr_block
    comment    = mongodbatlas_project_ip_access_list.main.comment
  }
}