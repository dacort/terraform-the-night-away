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

Also useful for figuring out modules: https://github.com/vishalmodak/terraform_ecs_fargate

### Security Groups

Nice way to add my own IP as part of terraform: https://github.com/terraform-providers/terraform-provider-aws/blob/master/examples/eks-getting-started/workstation-external-ip.tf

## Issues I ran into

- Trying to change my ECS service dicovery hostname
https://github.com/terraform-providers/terraform-provider-aws/issues/4853