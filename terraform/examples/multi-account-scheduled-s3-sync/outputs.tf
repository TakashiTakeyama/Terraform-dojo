output "source_bucket" {
  value       = aws_s3_bucket.source.bucket
  description = "Simulated partner / source bucket name."
}

output "destination_bucket" {
  value       = aws_s3_bucket.destination.bucket
  description = "Simulated service / destination bucket name."
}

output "lambda_function_name" {
  value       = aws_lambda_function.sync.function_name
  description = "Name of the sync Lambda function."
}
