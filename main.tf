terraform {
  required_providers {
    timescale = {
      source  = "timescale/timescale"
      version = "~> 1.13.1"
    }
  }
}

# Authenticate using client credentials.
# They are issued through the Timescale UI.
# When required, they will exchange for a short-lived JWT to do the calls.
provider "timescale" {
  project_id = var.ts_project_id
  access_key = var.ts_access_key
  secret_key = var.ts_secret_key
}



resource "timescale_service" "test" {
  name       = "anton-tf-test"
  milli_cpu  = 500
  memory_gb  = 2
  region_code = "us-east-1"
  enable_ha_replica = false
  timeouts = {
    create = "30m"
  }
}