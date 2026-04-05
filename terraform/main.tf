# Configuration VPC (réutilisation du Bloc 1)
data "aws_vpc" "meditrack_vpc" {
  id = "vpc-0c2104571acf62314" # VPC du Bloc 1
}

# Sous-réseaux privés (réutilisation du Bloc 1)
data "aws_subnet" "private_subnet_1" {
  id = "subnet-0a1b2c3d4e5f6g7h" # Remplacer par l'ID du sous-réseau privé du Bloc 1
}

data "aws_subnet" "private_subnet_2" {
  id = "subnet-0i9j8k7l6m5n4o3p" # Remplacer par l'ID du sous-réseau privé du Bloc 1
}

# Sous-réseaux publics (réutilisation du Bloc 1)
data "aws_subnet" "public_subnet_1" {
  id = "subnet-0q1r2s3t4u5v6w7x" # Remplacer par l'ID du sous-réseau public du Bloc 1
}

data "aws_subnet" "public_subnet_2" {
  id = "subnet-0y9z0a1b2c3d4e5f" # Remplacer par l'ID du sous-réseau public du Bloc 1
}

# Security Group pour l'instance EC2 (réutilisation du Bloc 1)
data "aws_security_group" "meditrack_sg" {
  id = "sg-0a1b2c3d4e5f6g7h" # Remplacer par l'ID du SG du Bloc 1
}

# ECR Repository (Elastic Container Registry)
resource "aws_ecr_repository" "meditrack_api" {
  name = "meditrack-api"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# RDS PostgreSQL Database
resource "aws_db_instance" "meditrack_db" {
  identifier = "meditrack-db"
  engine = "postgres"
  engine_version = "14.9"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  max_allocated_storage = 100
  storage_encrypted = true
  storage_type = "gp2"
  username = "meditrack_user"
  password = "MediTrack2024!" # À remplacer par une valeur sécurisée en production
  db_name = "meditrack"
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.meditrack_db_subnet_group.name
  skip_final_snapshot = true
  publicly_accessible = false
  backup_retention_period = 7
  multi_az = false
  deletion_protection = false
  tags = {
    Name = "MediTrack-DB"
  }
}

# Security Group pour RDS
resource "aws_security_group" "rds_sg" {
  name = "meditrack-rds-sg"
  description = "Security group for MediTrack RDS"
  vpc_id = data.aws_vpc.meditrack_vpc.id

  ingress {
    description = "PostgreSQL from EC2"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_group_ids = [data.aws_security_group.meditrack_sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MediTrack-RDS-SG"
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "meditrack_db_subnet_group" {
  name = "meditrack-db-subnet-group"
  description = "MediTrack DB subnet group"
  subnet_ids = [
    data.aws_subnet.private_subnet_1.id,
    data.aws_subnet.private_subnet_2.id
  ]
  tags = {
    Name = "MediTrack-DB-Subnet-Group"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "meditrack_cluster" {
  name = "meditrack-cluster"
  tags = {
    Name = "MediTrack-Cluster"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "meditrack_task" {
  family = "meditrack-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name = "meditrack-api"
      image = "${aws_ecr_repository.meditrack_api.repository_url}:latest"
      portMappings = [
        {
          containerPort = 3000
          protocol = "tcp"
        }
      ]
      environment = [
        {
          name = "DB_HOST"
          value = aws_db_instance.meditrack_db.address
        },
        {
          name = "DB_USER"
          value = aws_db_instance.meditrack_db.username
        },
        {
          name = "DB_NAME"
          value = aws_db_instance.meditrack_db.name
        },
        {
          name = "DB_PASSWORD"
          value = aws_db_instance.meditrack_db.password
        },
        {
          name = "DB_PORT"
          value = "5432"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group" = "/ecs/meditrack-api"
          "awslogs-region" = "eu-west-3"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "MediTrack-Task"
  }
}

# ECS Service
resource "aws_ecs_service" "meditrack_service" {
  name = "meditrack-service"
  cluster = aws_ecs_cluster.meditrack_cluster.arn
  task_definition = aws_ecs_task_definition.meditrack_task.arn
  desired_count = 1
  launch_type = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets = [
      data.aws_subnet.private_subnet_1.id,
      data.aws_subnet.private_subnet_2.id
    ]
    security_groups = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.meditrack_tg.arn
    container_name = "meditrack-api"
    container_port = 3000
  }

  depends_on = [aws_lb_listener.meditrack_http_listener]

  tags = {
    Name = "MediTrack-Service"
  }
}

# Security Group pour le service ECS
resource "aws_security_group" "ecs_service_sg" {
  name = "meditrack-ecs-service-sg"
  description = "Security group for MediTrack ECS service"
  vpc_id = data.aws_vpc.meditrack_vpc.id

  ingress {
    description = "HTTP from ALB"
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    security_group_ids = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MediTrack-ECS-Service-SG"
  }
}

# Application Load Balancer (ALB)
resource "aws_lb" "meditrack_alb" {
  name = "meditrack-alb"
  internal = false
  load_balancer_type = "application"
  subnets = [
    data.aws_subnet.public_subnet_1.id,
    data.aws_subnet.public_subnet_2.id
  ]
  security_groups = [aws_security_group.alb_sg.id]
  enable_deletion_protection = false
  tags = {
    Name = "MediTrack-ALB"
  }
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name = "meditrack-alb-sg"
  description = "Security group for MediTrack ALB"
  vpc_id = data.aws_vpc.meditrack_vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MediTrack-ALB-SG"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "meditrack_tg" {
  name = "meditrack-tg"
  port = 3000
  protocol = "HTTP"
  vpc_id = data.aws_vpc.meditrack_vpc.id
  target_type = "ip"
  deregistration_delay = 30

  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 30
    matcher = "200"
    path = "/"
    port = 3000
    protocol = "HTTP"
    timeout = 5
  }

  tags = {
    Name = "MediTrack-TG"
  }
}

# ALB Listener (HTTP)
resource "aws_lb_listener" "meditrack_http_listener" {
  load_balancer_arn = aws_lb.meditrack_alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.meditrack_tg.arn
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "meditrack-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for ECS Task Execution
resource "aws_iam_policy" "ecs_task_execution_policy" {
  name = "meditrack-ecs-task-execution-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_attachment" {
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/meditrack-api"
  retention_in_days = 30
  tags = {
    Name = "MediTrack-ECS-Logs"
  }
}