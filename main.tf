provider "google" {
  project = "devops-react-app"
  region  = "asia-south1"
}

resource "google_container_cluster" "gke" {
  name     = "terraform-cluster"
  location = "asia-east1-b"

  initial_node_count = 1

  node_config {
    machine_type = "e2-medium"
  }
}

data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
}

resource "kubernetes_deployment" "react_app" {
  metadata {
    name = "react-app"
    labels = {
      app = "react-app"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "react-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "react-app"
        }
      }

      spec {
        container {
          name  = "react-app"
          image = "asia-south1-docker.pkg.dev/devops-react-app/devops-repo/react-app:latest"

          port {
            container_port = 3000
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "react_service" {
  metadata {
    name = "react-service"
  }

  spec {
    selector = {
      app = "react-app"
    }

    port {
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}