terraform {
  backend "s3" {
    bucket         = "macropay-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "macropay-dynamodb-table"
    encrypt        = true
  }
}