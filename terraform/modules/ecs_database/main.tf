
# In theory we can have generic templates that we replace with variables
data "template_file" "service_template" {
  template = "${file("${var.task_definition_template_path}")}"
  vars     = "${var.template_vars}"
}

# Database task and service definitions
resource "aws_ecs_task_definition" "service" {
  family                    = var.ecs_task_family
  requires_compatibilities  = ["FARGATE"]
  network_mode              = "awsvpc"
  cpu                       = var.ecs_task_cpu
  memory                    = var.ecs_task_memory

  container_definitions     = data.template_file.service_template.rendered

  tags = {
    Terraform = "true"
    Environment = "damons-vpc"
  }
}

resource "aws_ecs_service" "service" {
  name            = var.ecs_task_family
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # Note that I'm putting this on the public subnet so I can easily test it
  # It _should_ probably be on a private subnet. :)
  #
  # `subnets` was previously private and I switched it to public, but it didn't take.
  # When I destroyed everything and recreated it was fine...
  network_configuration {
    security_groups   = [var.security_group_id]
    subnets           =  var.subnet_ids
    assign_public_ip  = true
  }

  # Try to register this service
  service_registries {
    registry_arn = aws_service_discovery_service.fargate.arn
    port = var.container_port
  }
}

# Register this service in Service Discovery


# DNS record for the ECS service
resource "aws_service_discovery_service" "fargate" {
  name = var.ecs_task_family
  dns_config {
    namespace_id = var.discovery_namespace_id
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