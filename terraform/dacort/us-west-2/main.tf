provider "aws" {
    version = "~> 2.53"
    region = "us-west-2"
}


# Base VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "damons-vpc"
  cidr = "10.20.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
  database_subnets = ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"]
  public_subnets  = ["10.20.101.0/24", "10.20.102.0/24", "10.20.103.0/24"]
  
  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = "damons-vpc"
  }
}


# Service discovery 🕺
resource "aws_service_discovery_public_dns_namespace" "fargate" {
  name = "damon.local"
  description = "Fargate discovery managed zone."
}


# Security group for ECS cluster
resource "aws_security_group" "nsg_task" {
  name        = "damon-task"
  description = "Limit connections from internal resources while allowing damon-task to connect to all external resources"
  vpc_id      =  module.vpc.vpc_id

  tags = {
    Terraform = "true"
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


module "mysql_service" {
  source            = "../../modules/ecs_database"
  ecs_cluster_id    = aws_ecs_cluster.ecs-damon.id
  ecs_task_family   = "mysql"
  ecs_task_cpu      = "256"
  ecs_task_memory   = "512"
  container_port    = 3306
  instance_count    = 1

  subnet_ids              = module.vpc.public_subnets
  security_group_id       = aws_security_group.nsg_task.id
  discovery_namespace_id  = aws_service_discovery_public_dns_namespace.fargate.id

  task_definition_template_path = "task-definitions/mysql.json"
  template_vars = {}
}


# DNS record for the ECS service
resource "aws_service_discovery_service" "fargate" {
  name = "dacort"
  dns_config {
    namespace_id = aws_service_discovery_public_dns_namespace.fargate.id
    routing_policy = "MULTIVALUE"
    dns_records {
      ttl = 10
      type = "A"
    }

    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }
  health_check_custom_config {
    failure_threshold = 5
  }
}




# Mongo task and service definitions
resource "aws_ecs_task_definition" "mongo" {
  family                    = "service"
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                       = "256"
  memory                    = "512"

  container_definitions = file("task-definitions/service.json")

  tags = {
    Terraform = "true"
    Environment = "damons-vpc"
  }
}

resource "aws_ecs_service" "mongo" {
  name            = "mongodb"
  cluster         = aws_ecs_cluster.ecs-damon.id
  task_definition = aws_ecs_task_definition.mongo.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # Note that I'm putting this on the public subnet so I can easily test it
  # It _should_ probably be on a private subnet. :)
  #
  # `subnets` was previously private and I switched it to public, but it didn't take.
  # When I destroyed everything and recreated it was fine...
  network_configuration {
    security_groups   = [aws_security_group.nsg_task.id]
    subnets           =  module.vpc.public_subnets
    assign_public_ip  = true
  }

  # Try to register this service
  service_registries {
    registry_arn = aws_service_discovery_service.fargate.arn
    port = "27017"
  }
}