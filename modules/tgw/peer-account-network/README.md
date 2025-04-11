# ネットワークインフラストラクチャモジュール

マルチアカウントネットワーク環境を管理するためのモジュール

## 概要

### サンプル構成図
![サンプル構成図](../../image/tgw-nat.png)

参考URL: [AWSトランジットゲートウェイを使用したNATゲートウェイの集約によるコスト最適化のためのルート設計](https://blog.serverworks.co.jp/route-design-for-aggregating-nat-gateways-using-aws-transit-gateway-to-optimize-costs)

このモジュールは以下の機能を提供します：

- Transit Gateway（TGW）を活用したマルチアカウントネットワーク接続
- 複数のピアアカウントからのアウトバウンド通信の一元管理
- アカウント間の安全な通信経路の確立

## 環境構成

以下の環境をサポートしています：

- `dev/`: Dev環境

## 使用方法

### 新規ピアアカウントの追加手順

1. **VPC情報の設定**
   - 接続対象VPCの情報を以下の形式で追加します（Privateサブネット）：
   ```hcl
   peer_account_name = {
     peer_vpc_id          = "vpc-xxxxxxxx"
     peer_subnet_ids      = ["subnet-xxxxx", "subnet-xxxxx", "subnet-xxxxx"]
     peer_route_table_ids = ["rtb-xxxxx", "rtb-xxxxx", "rtb-xxxxx"]
   }
   ```

2. **認証情報の追加**
   - ピアアカウントのアクセスキーとシークレットキーを設定します

3. **モジュール設定**
   - `terraform.tfvars`にピアアカウント情報と認証情報を追加
   - 新しいピアアカウント用のモジュールを作成（注：providerブロックはfor_eachに対応していないため、個別にモジュールを作成する必要があります）
