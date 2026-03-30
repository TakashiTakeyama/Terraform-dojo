variable "environment_name" {
  type        = string
  description = "Environment name (e.g. dev, stg, prod)"
}

variable "project_name" {
  type        = string
  description = "Project name used for resource naming"
}

variable "github_connection_name" {
  type        = string
  description = "Name of the CodeStar Connections (GitHub) connection"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in owner/repo format (e.g. my-org/my-infra-repo)"
}

variable "trigger_branch" {
  type        = string
  description = "Branch that triggers CodePipeline on push"
}

variable "trigger_paths" {
  type        = list(string)
  description = "File paths that trigger CodePipeline on push"
  default = [
    "terraform/usecases/synthetic-monitoring/canary-code/**",
  ]
}

variable "canary_code_base_path" {
  type        = string
  default     = "terraform/usecases/synthetic-monitoring/canary-code"
  description = "Path in the repository where canary code scenarios are located"
}

variable "monitoring_root_module_path" {
  type        = string
  description = "Path to the synthetic-monitoring root module for terraform apply in Deploy stage (e.g. terraform/env/dev/synthetic-monitoring)"
}

variable "tfstate_bucket" {
  type        = string
  description = "S3 bucket containing the synthetic-monitoring stack's Terraform state"
}

variable "tfstate_key" {
  type        = string
  default     = "synthetic-monitoring/terraform.tfstate"
  description = "S3 key for the synthetic-monitoring stack's Terraform state"
}
