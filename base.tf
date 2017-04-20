variable "environment" {
  type = "string"
}

variable "region" {
  type = "string"
  default = "eu-central-1"
}

provider "aws" {
  region = "${var.region}"
  assume_role {
    role_arn = "arn:aws:iam::011881316557:role/beamly-admin"
    session_name = "ecs-terraform"
  }
}