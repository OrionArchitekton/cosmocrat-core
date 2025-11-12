// Minimal day-1 module skeleton — extend as needed.
terraform {
  required_version = ">= 1.6.0"
}

variable "tenant" { type = string }
variable "tailscale_target" { type = string }

resource "null_resource" "seed" {
  provisioner "local-exec" {
    command = "echo Seeding ${var.tenant} on ${var.tailscale_target} (placeholder)"
  }
}
