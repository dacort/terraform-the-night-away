# /**
#   We use an ecrypted Ubuntu image because we care :)
# **/
# resource "aws_ami_copy" "ubuntu-xenial-encrypted-ami" {
#   name              = "ubuntu-xenial-encrypted-ami"
#   description       = "An encrypted root ami based off ${data.aws_ami.ubuntu-xenial.id}"
#   source_ami_id     = data.aws_ami.ubuntu-xenial.id
#   source_ami_region = "us-west-2"
#   encrypted         = "true"

#   tags = {
#     Name = "ubuntu-xenial-encrypted-ami"
#   }
# }

# data "aws_ami" "encrypted-ami" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu-xenial-encrypted-ami"]
#   }

#   owners = ["self"]
# }

data "aws_ami" "ubuntu-xenial" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
}

/**
  Now for the actual instances - we use an auto-scaling group to ensure we always have something
**/

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"
  
  name = "devbox-${var.name}"

  # Launch configuration
  lc_name = "devbox-${var.name}-lc"

  image_id        = data.aws_ami.ubuntu-xenial.id
  instance_type   = "t3.xlarge"
  security_groups = [var.security_group]
  associate_public_ip_address  = true
  recreate_asg_when_lc_changes = true
  key_name        = var.ssh_key_name

  # ebs_block_device = [
  #   {
  #     device_name           = "/dev/xvdz"
  #     volume_type           = "gp2"
  #     volume_size           = "50"
  #     delete_on_termination = true
  #   },
  # ]

  root_block_device = [
    {
      volume_size = "50"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "asg-${var.name}"
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "EC2"
  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Terraform"
      value               = "true"
      propagate_at_launch = true
    },
    {
      key                 = "Environment"
      value               = "damons-vpc"
      propagate_at_launch = true
    },
  ]
}