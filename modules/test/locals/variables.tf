variable "instances" {
  description = "インスタンスの設定"
  type = map(object({
    name           = string
    instance_class = string
    identifier     = string
  }))
}

variable "ingress_rules" {
  description = "インバウンドルールの設定"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

# List
# 順序付きのコレクション。
# 同じ値を重複して持つことが可能。
# インデックスによってアクセス可能。
variable "example_list" {
  type    = list(string)
  default = ["apple", "banana", "cherry", "apple"]
}

# Set
# 順序は保証されないが、各要素はユニーク（重複しない）。
# 順序が重要な場合には tolist() でリストに変換する必要があります。
variable "example_set" {
  type    = set(string)
  default = ["apple", "banana", "cherry", "apple"]
}

# Map
# キーと値のペアのコレクション。
# キーは文字列であり、各キーはユニークです。
variable "example_map" {
  type = map(string)
  default = {
    key1 = "apple"
    key2 = "banana"
    key3 = "cherry"
  }
}

# Object
# 複数の属性（フィールド）を持つ複合データ型です。
# 各フィールドには型が指定され、構造が固定されます。
variable "example_object" {
  type = object({
    name  = string
    count = number
    tags  = list(string)
  })
  default = {
    name  = "fruit-basket"
    count = 3
    tags  = ["apple", "banana", "cherry"]
  }
}

# List of Objects
# オブジェクトのリスト。
# 各オブジェクトは同じ構造を持ちます。
variable "list_object" {
  type = list(object({
    name  = string
    count = number
    tags  = list(string)
  }))
  default = [
    {
      name  = "fruit-basket"
      count = 3
      tags  = ["apple", "banana", "cherry"]
    }
  ]
}

# Map of Objects
# オブジェクトのマップ。
# 各キーにはオブジェクトが関連付けられます。
variable "map_object" {
  type = map(object({
    name  = string
    count = number
    tags  = list(string)
  }))
  default = {
    fruit-basket = {
      name  = "fruit-basket"
      count = 3
      tags  = ["apple", "banana", "cherry"]
    }
  }
}

