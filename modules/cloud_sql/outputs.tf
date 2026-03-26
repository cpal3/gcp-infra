output "instance_name" {
  description = "The name of the DB instance."
  value       = google_sql_database_instance.default.name
}

output "instance_connection_name" {
  description = "The connection name of the DB instance."
  value       = google_sql_database_instance.default.connection_name
}

output "private_ip_address" {
  description = "The first private IP address assigned to the DB instance."
  value       = google_sql_database_instance.default.private_ip_address
}
