# Terraform で「デフォルト値＋入力値」を `merge()` で扱うパターン集

Terraform 1.x 以降なら、**`locals { merged = merge(defaults, var.input) }`** 方式で
冗長な三項演算子を排除し、コードをスリム化できる


## 0. mergeメソッド

```hcl
> merge({a="b", c="d"}, {e="f", c="z"})
{
  "a" = "b"
  "c" = "z"
  "e" = "f"
}

> merge({a="b"}, {a=[1,2], c="z"}, {d=3})
{
  "a" = [
    1,
    2,
  ]
  "c" = "z"
  "d" = 3
}
```

---

## 1. 基本形（オブジェクト）

```hcl
# variables.tf
variable "service_input" {
  description = "サービスごとの上書き値"
  type = object({
    desired_count = optional(number)
    launch_type   = optional(string)
  })
}

# locals.tf
locals {
  defaults = {
    desired_count = 1
    launch_type   = "FARGATE"
  }
  service = merge(local.defaults, var.service_input)
}
```

* `var.service_input` に指定が無いキーは **defaults の値** が入る。
* 以降は `local.service.desired_count` の **単純代入** で OK。

---

## 2. マップ(複数サービス) × デフォルト一括

```hcl
variable "services" {
  description = "サービスごとの設定マップ"
  type = map(any)
}

locals {
  default_service = {
    desired_count = 1
    launch_type   = "FARGATE"
  }

  merged_services = {
    for name, cfg in var.services :
    name => merge(local.default_service, cfg)
  }
}
```

* `for` ループで **マップ全体** を走査、各要素ごとに `merge()`。
* リソース定義では `for_each = local.merged_services`。

---

## 3. ネスト構造のマージ

```hcl
locals {
  nested_defaults = {
    network = {
      subnets         = []
      security_groups = []
    }
  }

  merged = merge(local.nested_defaults, var.input)
}
```

> `merge()` は *一段目のキー* までしかマージしません。ネスト内部もマージしたい場合は
> `deep_merge()`（1.8+）や `merge(…, { network = merge(local.nested_defaults.network, var.input.network) })` を活用。

---

## 4. `optional()` & `nullable` で型も厳密に

```hcl
variable "service_input" {
  type = object({
    desired_count = optional(number)
    launch_type   = optional(string, "FARGATE")  # デフォルトも宣言可
  })
}
```

* `optional(T, default)` で **変数側にデフォルト** を仕込めば、`merge()` 自体が不要なケースも。

---

## 5. まとめ

1. **`merge(defaults, var)`** で冗長な三項演算子をなくす。
2. 複数サービスなら **`for … : name => merge(...)`** パターン。
3. 深いネストは `deep_merge()`（Terraform 1.8+）を検討。
