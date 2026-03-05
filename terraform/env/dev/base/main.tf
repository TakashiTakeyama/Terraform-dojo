resource "terraform_data" "stack_marker" {
  input = {
    project     = var.project_name
    environment = var.environment_name
    stack       = var.stack_name
    purpose     = "base stack sample"
  }
}
