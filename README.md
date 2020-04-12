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

### Auto scaling groups

https://github.com/terraform-aws-modules/terraform-aws-autoscaling/blob/master/main.tf

## Issues I ran into

- Trying to change my ECS service dicovery hostname
https://github.com/terraform-providers/terraform-provider-aws/issues/4853

- The encrypted AMI example here appears to be incorrect. I get `tags` syntax errors and then it can't find the ami...
https://registry.terraform.io/modules/terraform-aws-modules/ec2-instance/aws/2.5.0
Probably because I was using an older version? Nope. So I just removed security for now. :)

- Also want to have a persistent EBS (or EFS?) for maintaining data across EC2 instances. https://serverfault.com/questions/831974/can-i-re-use-an-ebs-volume-with-aws-asg

- EC2 dev box can't resolve service discovery...unsure why. Some reference here: https://github.com/devops-workflow/terraform-aws-ecs-service-discovery/blob/master/main.tf