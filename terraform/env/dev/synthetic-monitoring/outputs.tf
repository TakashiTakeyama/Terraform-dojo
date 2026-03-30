output "web_canary_name" {
  description = "Name of the web canary"
  value       = module.synthetic_monitoring.web_canary_name
}

output "api_canary_name" {
  description = "Name of the API canary"
  value       = module.synthetic_monitoring.api_canary_name
}
