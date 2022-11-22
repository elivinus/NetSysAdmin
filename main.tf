provider "aws" {
  region = "eu-west-2"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

module "eks-cluster" {
  source = "./modules/eks-cluster"
  cidr_block = "10.0.0.0/16"
  private-1-subnet-cidr  = "10.0.1.0/24"
  private-2-subnet-cidr  = "10.0.2.0/24"
  public-1-subnet-cidr   = "10.0.3.0/24"
  public-2-subnet-cidr   = "10.0.4.0/24"
  rds_instance_identifier = "postgres-rds"
  Environment = "dev"
  name = "dbs-cluster"
  desired-size = 6
  max-size = 8
  min-size = 4
  max-unavailable = 4
  instance-types = [ "t3.2xlarge" ]
}


#######################################
#ECR  SETUP
#######################################
module "ecr" {

  source = "./modules/ecr"
  trusted_accounts = [ "651611223190" ]
  repository_list = [ "dbsreg", "dbshub"]
}
