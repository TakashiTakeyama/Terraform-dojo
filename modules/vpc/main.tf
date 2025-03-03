resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"

  policy = jsonencode({
    // S3へのアクセスを制限するポリシー
  })
} 