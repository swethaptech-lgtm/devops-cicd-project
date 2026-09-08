output "monitoring_namespace_name" {
  description = "Monitoring namespace is created by Terraform"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "monitoring_service_account_name" {
  description = "Monitoring ServiceAccount is created by Terraform"
  value       = kubernetes_service_account.monitoring_sa.metadata[0].name
}
