# Damon learns Terraform

Spin up a (mostly) complete Terraform environment with the following:
- Base VPC
- Personal security group for access to fun services
- ECS
- A MongoDB container

## References

### Overall

Segment AWS Stack: https://segment.com/blog/the-segment-aws-stack/

### ECS

Task definition: https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html

Came across https://github.com/turnerlabs/terraform-ecs-fargate-service-discovery - super useful