module "synthetic_monitoring_pipeline" {
  source = "../../../usecases/synthetic-monitoring-pipeline"

  environment_name = var.environment_name
  project_name     = var.project_name

  github_connection_name      = "${var.environment_name}-github-connection"
  github_repository           = "my-org/my-infra-repo"
  trigger_branch              = "develop"
  monitoring_root_module_path = "terraform/env/${var.environment_name}/synthetic-monitoring"
  tfstate_bucket              = "<state-bucket>"
}
