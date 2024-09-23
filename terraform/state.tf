terraform {                                        # top level block to define terraform behaviour in our backend configuration
  backend "s3" {                                   # backend block to define the s3 backend
    bucket         = "terraform-state-bucket-is"   # bucket name to store the state file
    key            = "global/s3/terraform.tfstate" # path where to store the state file within the bucket
    region         = "eu-west-3"
    dynamodb_table = "terraform-locks" # dynamodb table name to lock the state file, to prevent concurrent modifications
  }
}
