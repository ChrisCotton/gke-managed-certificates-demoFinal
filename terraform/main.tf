/*
Copyright 2018 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// google_dns_resource goes here.
data "google_compute_zones" "available" {}

resource "google_container_cluster" "primary" {
  name = "${var.cluster_name}"
  zone = "${data.google_compute_zones.available.names[0]}"
  initial_node_count = 3

  additional_zones = [
    "${data.google_compute_zones.available.names[1]}"
  ]

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
}

provider "kubernetes" {
  host = "https://${google_container_cluster.primary.endpoint}"
  username = "${google_container_cluster.primary.master_auth.0.username}"
  password = "${google_container_cluster.primary.master_auth.0.password}"
  client_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.client_certificate)}"
  client_key = "${base64decode(google_container_cluster.primary.master_auth.0.client_key)}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)}"
}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = "${var.cluster_name}"
  }
}

//Build out the DNS Managed Zones in GCP
resource "google_dns_managed_zone" "env_dns_zone" {
  name            = "jld"
  dns_name        = "${var.domain}."
}

resource "google_dns_record_set" "dns" {
  name            = "${var.cluster_name}.${google_dns_managed_zone.env_dns_zone.dns_name}"
  type            = "TXT"
  ttl             = 300
  managed_zone    = "${google_dns_managed_zone.env_dns_zone.name}"

  rrdatas         = ["test"]
}

output "cluster_name" {
  value = "${var.cluster_name}"
}

output "project" {
  value = "${var.project}"
}

output "region" {
  value = "${var.region}"
}

output "domain" {
  value = "${var.domain}"
}

//output "cluster_password" {
//  value = "${data.google_container_cluster.primary.master_auth.0.password}"
//}
//
//output "endpoint" {
//  value = "${data.google_container_cluster.primary.endpoint}"
//}
//
//output "instance_group_urls" {
//  value = "${data.google_container_cluster.primary.instance_group_urls}"
//}
//
//output "node_config" {
//  value = "${data.google_container_cluster.primary.node_config}"
//}
//
//output "node_pools" {
//  value = "${data.google_container_cluster.primary.node_pool}"
//}
