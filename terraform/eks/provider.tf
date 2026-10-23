provider "aws" {
  region              = "eu-north-1"
  allowed_account_ids = ["308054409751"]

  default_tags {
    tags = {
      Project = "lum-test"
    }
  }
}
