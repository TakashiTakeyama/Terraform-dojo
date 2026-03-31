output "source_bucket" {
  value       = aws_s3_bucket.source.bucket
  description = "Source bucket (stand-in for external object storage in the diagram)."
}

output "destination_bucket" {
  value       = aws_s3_bucket.destination.bucket
  description = "Destination bucket in AWS."
}

output "datasync_task_arn" {
  value       = try(aws_datasync_task.copy[0].arn, null)
  description = "DataSync task ARN when enable_task is true."
}
