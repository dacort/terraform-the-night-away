/**
  Networking variables
**/
variable "subnet_ids" {
  type        = list
  description = "Subnet IDs"
}

variable "security_group" {
  description = "Security Group ID"
}

/**
  ASG Identifiers
**/
variable "name" {
  description = "Name to give to related ASG resources"
}

variable "ssh_key_name" {
  description = "SSH Key ID - must already exist"
}