output "tgw_id" {
  description = "EC2 Transit Gatewayの識別子"
  value       = module.tgw.ec2_transit_gateway_id
}

output "tgw_rtb_id" {
  description = "EC2 Transit Gateway ルートテーブルの識別子"
  value       = module.tgw.ec2_transit_gateway_route_table_id
}

output "vpc_id" {
  description = "VPCのID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "プライベートサブネットのIDリスト"
  value       = module.vpc.private_subnets
}

output "vpc_cidr_block" {
  description = "VPCのCIDRブロック"
  value       = module.vpc.vpc_cidr_block
}

output "tgw_vpc_attachment_id" {
  description = "EC2 Transit Gateway VPCアタッチメントの識別子"
  value       = module.tgw.ec2_transit_gateway_vpc_attachment_ids["vpc"]
}
