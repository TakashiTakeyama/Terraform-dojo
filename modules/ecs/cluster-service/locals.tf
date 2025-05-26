locals {
  # デフォルト設定とユーザー定義の設定をマージして最終的なサービス設定を生成
  merged_services = {
    for name, svc in var.services :
    name => merge(var.default_service_settings, svc)
  }
}
