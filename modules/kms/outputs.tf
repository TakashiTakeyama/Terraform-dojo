output "kms" {
  description = "KMSキー"
  value       = module.kms
}

output "kms_key_arn" {
  description = "KMSキーのARN"
  value       = module.kms.key_arn
}


