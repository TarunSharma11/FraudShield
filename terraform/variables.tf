variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project prefix"
  type        = string
  default     = "fraudshield"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "msk_broker_nodes" {
  description = "Number of MSK broker nodes"
  type        = number
  default     = 2
}

variable "msk_kafka_version" {
  description = "Kafka version for MSK"
  type        = string
  default     = "3.6.0"
}

variable "ec2_broker_instance_type" {
  description = "MSK broker instance type"
  type        = string
  default     = "kafka.m5.large"
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.small"
}

variable "redis_num_nodes" {
  description = "ElastiCache replica count (including primary)"
  type        = number
  default     = 2
}

variable "ecs_task_cpu" {
  description = "Fargate task CPU (units)"
  type        = number
  default     = 256
}

variable "ecs_task_memory" {
  description = "Fargate task memory (MB)"
  type        = number
  default     = 512
}

variable "fastapi_image" {
  description = "FastAPI Docker image (ECR URL or public)"
  type        = string
  default     = "public.ecr.aws/docker/library/python:3.11-slim" # placeholder; will be overridden
}

variable "fastapi_container_port" {
  description = "FastAPI container port"
  type        = number
  default     = 8000
}

variable "enable_managed_grafana" {
  description = "Whether to create an Amazon Managed Grafana workspace"
  type        = bool
  default     = false
}
