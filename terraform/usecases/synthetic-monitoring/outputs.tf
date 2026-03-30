output "web_canary_name" {
  description = "Name of the web (browser) canary"
  value       = aws_synthetics_canary.web.name
}

output "api_canary_name" {
  description = "Name of the API canary"
  value       = aws_synthetics_canary.api.name
}

output "canary_execution_role_arn" {
  description = "ARN of the canary execution IAM role"
  value       = aws_iam_role.canary_execution.arn
}

output "canary_execution_role_name" {
  description = "Name of the canary execution IAM role"
  value       = aws_iam_role.canary_execution.name
}

output "artifacts_bucket_name" {
  description = "S3 bucket name for canary execution artifacts"
  value       = aws_s3_bucket.canary_artifacts.bucket
}
