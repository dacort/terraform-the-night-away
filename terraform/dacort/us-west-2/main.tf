provider "aws" {
  version = "~> 2.53"
  region  = "us-west-2"
}


# Base VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "damons-vpc"
  cidr = "10.20.0.0/16"

  azs              = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets  = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
  database_subnets = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
  public_subnets   = ["10.20.101.0/24", "10.20.102.0/24", "10.20.103.0/24"]

  enable_nat_gateway    = true
  enable_dns_hostnames  = true

  enable_dhcp_options              = true
  dhcp_options_domain_name         = "damon.local"
  dhcp_options_domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Terraform   = "true"
    Environment = "damons-vpc"
  }
}


# Service discovery 🕺
resource "aws_service_discovery_private_dns_namespace" "fargate" {
  name        = "damon.local"
  description = "Fargate discovery managed zone."
  vpc         = module.vpc.vpc_id
}


# Security group for ECS cluster
resource "aws_security_group" "nsg_task" {
  name        = "damon-task"
  description = "Limit connections from internal resources while allowing damon-task to connect to all external resources"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Terraform   = "true"
    Environment = "damons-vpc"
  }
}

resource "aws_security_group_rule" "nsg_task_egress_rule" {
  description = "Allows task to establish connections to all resources"
  type        = "egress"
  from_port   = "0"
  to_port     = "0"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.nsg_task.id
}


# Actual ECS Cluster
resource "aws_ecs_cluster" "ecs-damon" {
  name = "ecs-damon-life"
}

# MySQL
module "mysql_service" {
  source          = "../../modules/ecs_database"
  ecs_cluster_id  = aws_ecs_cluster.ecs-damon.id
  ecs_task_family = "mysql"
  ecs_task_cpu    = "256"
  ecs_task_memory = "512"
  container_port  = 3306
  instance_count  = 1

  subnet_ids             = module.vpc.public_subnets
  security_group_id      = aws_security_group.nsg_task.id
  discovery_namespace_id = aws_service_discovery_private_dns_namespace.fargate.id

  task_definition_template_path = "task-definitions/mysql.json"
  template_vars                 = {}
}

# MongoDB
module "mongo_service" {
  source          = "../../modules/ecs_database"
  ecs_cluster_id  = aws_ecs_cluster.ecs-damon.id
  ecs_task_family = "mongo"
  ecs_task_cpu    = "256"
  ecs_task_memory = "512"
  container_port  = 27017
  instance_count  = 1

  subnet_ids             = module.vpc.public_subnets
  security_group_id      = aws_security_group.nsg_task.id
  discovery_namespace_id = aws_service_discovery_private_dns_namespace.fargate.id

  task_definition_template_path = "task-definitions/mongodb.json"
  template_vars                 = {}
}

# Damon's dev box
module "damon_ec2" {
  name           = "damon"
  ssh_key_name   = "damon"
  source         = "../../modules/dev_box"
  subnet_ids     = module.vpc.public_subnets
  security_group = aws_security_group.nsg_task.id
}
