resource "terraform_data" "service_marker" {
  input = {
    project     = var.project_name
    environment = var.environment_name
    stack       = var.stack_name
    purpose     = "service stack sample"
  }
}
