# Enable Kubernetes Engine API for the project.
  resource "google_project_service" "kubernetes" {
  project = "${var.project}"
  service = "container.googleapis.com"
}

# Manages a Google Kubernetes Engine (GKE) cluster.
resource "google_container_cluster" "kubernetes" {
  name = "${var.cluster}"
  project = "${var.project}"

  # Waits for Kubernetes Engine API to be enabled
  depends_on = ["google_project_service.kubernetes"]

  # Must be set if `node_pool` is not set.
  initial_node_count = 1

  # Disable basic auth
  master_auth {
    username = ""
    password = ""
  }

  ip_allocation_policy {
    use_ip_aliases = true
  }

  # Parameters used in creating the cluster's nodes.
  node_config {
    # The following scopes are necessary to ensure the correct functioning of the cluster.
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    tags = ["network-cluster"]
  }
}

# sql instance names should be unique and can't be reused within a week so we will add a random number
resource "random_id" "db_name_suffix" {
  byte_length = 6
}

resource "google_sql_database_instance" "master" {
  name = "master-instance-helloworld-${random_id.db_name_suffix.hex}"

  database_version = "POSTGRES_9_6"
  region = "europe-west2"

  settings {
    tier = "db-f1-micro"
  }
  project = "${var.project}"
}

resource "google_sql_database" "users" {
  name      = "hello"
  instance  = "${google_sql_database_instance.master.name}"
  project = "${var.project}"
}

resource "google_sql_user" "users" {
  name     = "hello-user"
  instance = "${google_sql_database_instance.master.name}"
  password = "${var.database_password}"
  project = "${var.project}"
}

# Fetches the project name, and provides the appropriate URLs to use for container registry.
data "google_container_registry_repository" "kubernetes" {
  # The GCR region to use.
  region = "eu"
  project = "${var.project}"
}
