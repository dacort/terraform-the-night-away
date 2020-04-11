provider "aws" {
    version = "~> 2.53"
    region = "us-west-2"
}

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




resource "aws_ecs_cluster" "ecs-damon" {
  name = "ecs-damon-life"
}

resource "aws_ecs_task_definition" "mongo" {
  family                = "service"
  container_definitions = file("task-definitions/service.json")

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }
}

resource "aws_ecs_service" "mongo" {
  name            = "mongodb"
  cluster         = aws_ecs_cluster.ecs-damon.id
  task_definition = aws_ecs_task_definition.mongo.arn
  desired_count   = 1

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  }
}