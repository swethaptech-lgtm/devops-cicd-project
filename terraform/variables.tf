variable "monitoring_namespace" {
  description = "Name of the Kubernetes namespace used for monitoring"
  type        = string
  default     = "monitoring"
}

variable "monitoring_service_account" {
  description = "Name of the ServiceAccount used in the monitoring namespace"
  type        = string
  default     = "monitoring-sa"
}
