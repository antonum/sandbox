output "timescale_service_hostname" {
  value = timescale_service.test.hostname
}

output "timescale_service_port" {
  value = timescale_service.test.port
}

output "timescale_service_password" {
  value = timescale_service.test.password
  sensitive = true
}

output "timescale_service_psql" {
  value = "psql -d \"postgres://tsdbadmin:${timescale_service.test.password}@${timescale_service.test.hostname}:${timescale_service.test.port}/tsdb?sslmode=require\""
  sensitive = true
}

// use the following to capture password:
//terraform output timescale_service_password
//terraform output timescale_service_psql

//psql -d "postgres://tsdbadmin:ip00vkg6pe1jeasd@lpifmr8t11.ocssgijfrc.tsdb.cloud.timescale.com:32753/tsdb?sslmode=require"