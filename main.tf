module "ssm_ec2" {
  source = "./modules/ssm-ec2"

  vpc_name        = var.vpc_name
  workspaces_name = var.workspaces_name
  ssm_ec2         = var.ssm_ec2
  user_data       = var.user_data
  ami_name        = var.ami_name
}