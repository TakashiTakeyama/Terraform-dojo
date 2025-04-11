variable "vpc" {
  description = "デフォルトのVPC設定"
  type = object({
    name               = string
    destination_s3_arn = string
    ipam_pool_id       = string
    cidr               = optional(string)
  })
}

variable "peer_dev_network" {
  description = "peerの開発環境ネットワーク設定（Transit Gateway名と共有先アカウント）"
  type = map(object({
    description    = string
    ram_principals = list(string)
  }))
}

variable "peer2_dev_network" {
  description = "peer2の設定情報"
  type = object({
    peer_vpc_id          = string
    peer_subnet_ids      = list(string)
    peer_route_table_ids = list(string)
  })
}

variable "peer3_dev_network" {
  description = "peer3の設定情報"
  type = object({
    peer_vpc_id          = string
    peer_subnet_ids      = list(string)
    peer_route_table_ids = list(string)
  })
}

variable "cidr" {
  description = "開発環境ネットワークのCIDRブロック（IPAMプールから割り当て）"
  type        = string
}

variable "PEER_ACCESS_KEY" {
  description = "peerのアクセスキー"
  type        = string
}

variable "PEER_SECRET_KEY" {
  description = "peerのシークレットキー"
  type        = string
}

variable "PEER2_ACCESS_KEY" {
  description = "peer2のアクセスキー"
  type        = string
}

variable "PEER2_SECRET_KEY" {
  description = "peer2のシークレットキー"
  type        = string
}

variable "PEER3_ACCESS_KEY" {
  description = "peer3のアクセスキー"
  type        = string
}

variable "PEER3_SECRET_KEY" {
  description = "peer3のシークレットキー"
  type        = string
}
