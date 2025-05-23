provider "aws" {
  region = "eu-west-1"
  alias  = "primary"

  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "dr"

  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}
