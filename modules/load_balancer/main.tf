resource "google_compute_region_backend_service" "default" {
  name                  = "${var.lb_name}-backend"
  region                = var.region
  project               = var.project_id
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = "HTTP"

  dynamic "backend" {
    for_each = var.serverless_neg_id != null ? [1] : []
    content {
      group = var.serverless_neg_id
    }
  }
}

resource "google_compute_region_url_map" "default" {
  name            = "${var.lb_name}-url-map"
  region          = var.region
  project         = var.project_id
  default_service = google_compute_region_backend_service.default.id
}

resource "google_compute_region_target_http_proxy" "default" {
  name    = "${var.lb_name}-http-proxy"
  region  = var.region
  project = var.project_id
  url_map = google_compute_region_url_map.default.id
}

resource "google_compute_forwarding_rule" "default" {
  name                  = "${var.lb_name}-forwarding-rule"
  region                = var.region
  project               = var.project_id
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = var.network_id
  subnetwork            = var.subnetwork_id
  target                = google_compute_region_target_http_proxy.default.id
  port_range            = "80"

  labels = var.labels
}
