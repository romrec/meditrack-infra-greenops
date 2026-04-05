# Variables for MediTrack API deployment

# AWS Region
variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-3"
}

# VPC ID (from Bloc 1)
variable "vpc_id" {
  description = "ID of the existing VPC from Bloc 1"
  type        = string
  default     = "vpc-0c2104571acf62314"
}

# Private Subnets (from Bloc 1)
variable "private_subnets" {
  description = "List of private subnet IDs from Bloc 1"
  type        = list(string)
  default     = ["subnet-0a1b2c3d4e5f6g7h", "subnet-0i9j8k7l6m5n4o3p"]
}

# Public Subnets (from Bloc 1)
variable "public_subnets" {
  description = "List of public subnet IDs from Bloc 1"
  type        = list(string)
  default     = ["subnet-0q1r2s3t4u5v6w7x", "subnet-0y9z0a1b2c3d4e5f"]
}

# Security Group ID (from Bloc 1)
variable "security_group_id" {
  description = "ID of the existing security group from Bloc 1"
  type        = string
  default     = "sg-0a1b2c3d4e5f6g7h"
}

# Database configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "meditrack"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "meditrack_user"
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "MediTrack2024!"
}

# ECR repository name
variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "meditrack-api"
}

# ECS configuration
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "meditrack-cluster"
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory (MB) for the ECS task"
  type        = number
  default     = 512
}

# ALB configuration
variable "alb_name" {
  description = "Name of the Application Load Balancer"
  type        = string
  default     = "meditrack-alb"
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project = "MediTrack"
    Environment = "production"
    ManagedBy = "Terraform"
  }
}