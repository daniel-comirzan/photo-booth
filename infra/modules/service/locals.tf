locals {
  lb_internal = var.service == "frontend" ? true : false
  lb_access   = var.service == "frontend" ? var.external_lb_access_cidr : var.access_cidr
  lb_protocol = var.service == "frontend" ? "HTTPS" : "HTTP"

}