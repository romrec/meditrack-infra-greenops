# Outputs for MediTrack API deployment

# ECR Repository URL
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.meditrack_api.repository_url
}

# RDS Database Endpoint
output "db_endpoint" {
  description = "Endpoint of the RDS database"
  value       = aws_db_instance.meditrack_db.address
}

# RDS Database Port
output "db_port" {
  description = "Port of the RDS database"
  value       = aws_db_instance.meditrack_db.port
}

# ECS Cluster Name
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.meditrack_cluster.name
}

# ECS Service Name
output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.meditrack_service.name
}

# ALB DNS Name
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.meditrack_alb.dns_name
}

# ALB Canonical Hosted Zone ID
output "alb_hosted_zone_id" {
  description = "Canonical hosted zone ID of the ALB"
  value       = aws_lb.meditrack_alb.canonical_hosted_zone_id
}

# ALB Listener ARN
output "alb_listener_arn" {
  description = "ARN of the ALB listener"
  value       = aws_lb_listener.meditrack_http_listener.arn
}

# Task Definition ARN
output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.meditrack_task.arn
}

# Security Group IDs
output "security_group_ids" {
  description = "List of security group IDs"
  value       = [
    aws_security_group.rds_sg.id,
    aws_security_group.ecs_service_sg.id,
    aws_security_group.alb_sg.id
  ]
}

# Subnet IDs
output "subnet_ids" {
  description = "List of subnet IDs used"
  value       = [
    data.aws_subnet.private_subnet_1.id,
    data.aws_subnet.private_subnet_2.id,
    data.aws_subnet.public_subnet_1.id,
    data.aws_subnet.public_subnet_2.id
  ]
}

# VPC ID
output "vpc_id" {
  description = "ID of the VPC used"
  value       = data.aws_vpc.meditrack_vpc.id
}

# Database Username
output "db_username" {
  description = "Database username"
  value       = aws_db_instance.meditrack_db.username
  sensitive   = true
}

# Database Name
output "db_name" {
  description = "Database name"
  value       = aws_db_instance.meditrack_db.name
  sensitive   = true
}

# CloudWatch Log Group
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs_log_group.name
}