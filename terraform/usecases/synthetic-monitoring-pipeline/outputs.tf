output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.this.name
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.this.arn
}

output "deployments_bucket_name" {
  description = "S3 bucket name where canary zip files are stored"
  value       = aws_s3_bucket.canary_deployments.bucket
}
