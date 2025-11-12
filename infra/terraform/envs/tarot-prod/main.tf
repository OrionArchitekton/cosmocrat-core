terraform {
  required_version = ">= 1.6.0"
}
module "cosmocrat" {
  source          = "../../cosmocrat-stack"
  tenant          = "tarot-by-marie"
  tailscale_target= "edge-01"
}
