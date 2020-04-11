/**
  Networking variables
**/
variable "subnet_ids" {
  type        = list
  description = "Subnet IDs"
}

variable "security_group_id" {
  description = "Security group ID"
}
/**
  Global ECS variables
**/
variable "ecs_cluster_id" {
  description = "ECS cluster ID"
}

variable "ecs_task_family" {
  description = "Name for the ECS Task definition family"
}

/**
  Task-specific variables
**/

variable "ecs_task_cpu" {
  description = "ECS Task CPU Units"
}

variable "ecs_task_memory" {
  description = "ECS Task Memory Units"
}

variable "instance_count" {
  description = "Desired number of service instances"
}

variable "task_definition_template_path" {
  description = "Task definiton template file"
}

variable "template_vars" {
  type        = map(string)
  description = "list variables & values based on task definition JSON"
}

/**
  Load balancer or DNS variables
**/
variable "discovery_namespace_id" {
  description = "DNS namespace for service registry configuration"
}

variable "container_port" {
  description = "Port exposed from Container"
}