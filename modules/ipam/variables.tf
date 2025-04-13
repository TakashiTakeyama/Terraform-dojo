variable "pools" {
  description = "MainPoolの一覧"
  type = list(object({
    key         = string
    description = string
    cidr        = list(string)
    locale      = string
    sub_pools = optional(list(object({
      key                      = string
      name                     = string
      cidr                     = list(string)
      ram_share_principals     = optional(list(string))
      allocation_resource_tags = map(string)
    })))
  }))
}