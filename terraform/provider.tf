terraform {
  backend "local" {
    path = "/var/lib/jenkins/terraform-state/terraform.tfstate"
  }
}


terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand("~/.kube/config")
}
