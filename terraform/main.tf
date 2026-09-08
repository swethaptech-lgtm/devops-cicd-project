resource "kubernetes_namespace" "terraform_demo" {
  metadata {
    name = "terraform-demo"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.monitoring_namespace
  }
}

resource "kubernetes_service_account" "monitoring_sa" {
  metadata {
    name      = var.monitoring_service_account
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }
}
