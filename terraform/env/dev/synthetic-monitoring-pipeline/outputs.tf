output "pipeline_name" {
  description = "Name of the synthetics CodePipeline"
  value       = module.synthetic_monitoring_pipeline.pipeline_name
}

output "deployments_bucket_name" {
  description = "S3 bucket name for canary deployments"
  value       = module.synthetic_monitoring_pipeline.deployments_bucket_name
}
