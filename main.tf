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
  cidr_block = "172.60.0.0/16"
  private-1-subnet-cidr  = "172.60.1.0/24"
  private-2-subnet-cidr  = "172.60.2.0/24"
  public-1-subnet-cidr   = "172.60.3.0/24"
  public-2-subnet-cidr   = "172.60.4.0/24"
  rds_instance_identifier = "postgres-rds"
  Environment = "dev"
  name = "dbs-cluster"
  desired-size = 3
  max-size =4
  min-size = 2
  max-unavailable = 2
  instance-types = [ "t2.micro" ]
}


#######################################
#ECR  SETUP
#######################################
module "ecr" {

  source = "./modules/ecr"
  trusted_accounts = [ "651611223190" ]
  repository_list = [ "dbsreg", "dbshub"]
}
