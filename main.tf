terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  azs                = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnet_ids  = [for subnet in aws_subnet.public : subnet.id]
  private_subnet_ids = [for subnet in aws_subnet.private : subnet.id]
  kong_declarative_config = jsonencode({
    _format_version = "3.0"
    services = [
      {
        name = "backend-gateway-health-service"
        url  = "http://${aws_lb.backend_internal.dns_name}:${var.backend_container_port}/alive"
        routes = [
          {
            name       = "backend-gateway-health"
            paths      = ["/gateway/alive"]
            strip_path = true
          }
        ]
      },
      {
        name = "backend-gateway-participants-service"
        url  = "http://${aws_lb.backend_internal.dns_name}:${var.backend_container_port}/participants"
        routes = [
          {
            name       = "backend-gateway-participants"
            paths      = ["/gateway/participants"]
            strip_path = true
            plugins = [
              {
                name = "key-auth"
                config = {
                  key_names = ["x-api-key", "apikey"]
                }
              },
              {
                name = "acl"
                config = {
                  allow = ["frontend"]
                }
              }
            ]
          }
        ]
      },
      {
        name = "backend-gateway-results-service"
        url  = "http://${aws_lb.backend_internal.dns_name}:${var.backend_container_port}/results"
        routes = [
          {
            name       = "backend-gateway-results"
            paths      = ["/gateway/results"]
            strip_path = true
            plugins = [
              {
                name = "key-auth"
                config = {
                  key_names = ["x-api-key", "apikey"]
                }
              },
              {
                name = "acl"
                config = {
                  allow = ["frontend"]
                }
              }
            ]
          }
        ]
      },
      {
        name = "backend-gateway-vote-service"
        url  = "http://${aws_lb.backend_internal.dns_name}:${var.backend_container_port}/vote"
        routes = [
          {
            name       = "backend-gateway-vote"
            paths      = ["/gateway/vote"]
            strip_path = true
            plugins = [
              {
                name = "key-auth"
                config = {
                  key_names = ["x-api-key", "apikey"]
                }
              },
              {
                name = "acl"
                config = {
                  allow = ["frontend"]
                }
              }
            ]
          }
        ]
      },
      {
        name = "backend-gateway-login-service"
        url  = "http://${aws_lb.backend_internal.dns_name}:${var.backend_container_port}/login"
        routes = [
          {
            name       = "backend-gateway-login"
            paths      = ["/gateway/login"]
            strip_path = true
            plugins = [
              {
                name = "key-auth"
                config = {
                  key_names = ["x-api-key", "apikey"]
                }
              },
              {
                name = "acl"
                config = {
                  allow = ["frontend", "testing"]
                }
              }
            ]
          }
        ]
      }
    ]
    consumers = [
      {
        username = "cliente-web"
        keyauth_credentials = [
          { key = "gpio-api-key-2026" }
        ]
        acls = [
          { group = "frontend" }
        ]
      },
      {
        username = "cliente-test"
        keyauth_credentials = [
          { key = "gpio-test-key-2026" }
        ]
        acls = [
          { group = "testing" }
        ]
      }
    ]
    plugins = [
      {
        name = "file-log"
        config = {
          path = "/dev/stdout"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# RED: VPC CON SUBREDES PUBLICAS Y PRIVADAS
# ------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.project_name}-igw" }
}

resource "aws_subnet" "public" {
  for_each = { for index, az in local.azs : az => index }

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 1)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${each.key}"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  for_each = { for index, az in local.azs : az => index }

  vpc_id                  = aws_vpc.main.id
  availability_zone       = each.key
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 101)
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-${each.key}"
    Tier = "private"
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "${var.project_name}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = local.public_subnet_ids[0]

  tags = { Name = "${var.project_name}-nat" }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# ------------------------------------------------------------------------------
# SEGURIDAD
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "SG for public Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

resource "aws_security_group" "kong" {
  name        = "${var.project_name}-kong-sg"
  description = "SG for Kong API Gateway tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Traffic from ALB to Kong proxy"
    from_port       = var.kong_proxy_port
    to_port         = var.kong_proxy_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-kong-sg" }
}

resource "aws_security_group" "frontend" {
  name        = "${var.project_name}-frontend-sg"
  description = "SG for frontend tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Traffic from ALB to frontend"
    from_port       = var.frontend_container_port
    to_port         = var.frontend_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-frontend-sg" }
}

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg"
  description = "SG for private backend tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Traffic from internal backend ALB"
    from_port       = var.backend_container_port
    to_port         = var.backend_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-backend-sg" }
}

resource "aws_security_group" "backend_alb" {
  name        = "${var.project_name}-backend-alb-sg"
  description = "SG for private backend Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Traffic from Kong to private backend ALB"
    from_port       = var.backend_container_port
    to_port         = var.backend_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.kong.id]
  }

  ingress {
    description     = "Traffic from frontend service to private backend ALB"
    from_port       = var.backend_container_port
    to_port         = var.backend_container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-backend-alb-sg" }
}

resource "aws_security_group" "ecs_instances" {
  name        = "${var.project_name}-ecs-instances-sg"
  description = "SG for ECS EC2 container instances"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-ecs-instances-sg" }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "SG for MySQL database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from backend tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  tags = { Name = "${var.project_name}-rds-sg" }
}

# ------------------------------------------------------------------------------
# ECR REPOSITORIES
# ------------------------------------------------------------------------------
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "kong" {
  name                 = "${var.project_name}-kong"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ------------------------------------------------------------------------------
# RDS MYSQL EN SUBREDES PRIVADAS
# ------------------------------------------------------------------------------
resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = local.private_subnet_ids
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_db_instance" "mysql" {
  identifier              = "${var.project_name}-db"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  storage_type            = "gp2"
  storage_encrypted       = false
  db_name                 = var.db_name
  username                = var.db_username
  password                = random_password.db_password.result
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
  publicly_accessible     = false
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  tags = {
    Name = "${var.project_name}-mysql"
  }
}

# ------------------------------------------------------------------------------
# ECS CLUSTER Y AUTO SCALING GROUP
# ------------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3.micro"
  key_name      = null

  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  vpc_security_group_ids = [aws_security_group.ecs_instances.id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    systemctl enable ecs
    systemctl --no-block start ecs
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-ecs-instance"
    }
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = local.private_subnet_ids
  desired_capacity    = 3
  min_size            = 3
  max_size            = 3

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-instance"
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "main" {
  name = "${var.project_name}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.main.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main.name
    weight            = 1
    base              = 1
  }
}

# ------------------------------------------------------------------------------
# TASK DEFINITIONS
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "384"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  task_role_arn            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "MYSQL_USER", value = var.db_username },
        { name = "MYSQL_PASSWORD", value = random_password.db_password.result },
        { name = "MYSQL_DATABASE", value = var.db_name },
        { name = "MYSQL_HOST", value = aws_db_instance.mysql.address }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-backend"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "kong" {
  family                   = "${var.project_name}-kong"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "768"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  task_role_arn            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  container_definitions = jsonencode([
    {
      name      = "kong"
      image     = "${aws_ecr_repository.kong.repository_url}:${var.kong_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.kong_proxy_port
          hostPort      = var.kong_proxy_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "KONG_DATABASE", value = "off" },
        { name = "KONG_DECLARATIVE_CONFIG_STRING", value = local.kong_declarative_config },
        { name = "KONG_LOG_LEVEL", value = "info" },
        { name = "KONG_PROXY_ACCESS_LOG", value = "/dev/stdout" },
        { name = "KONG_ADMIN_ACCESS_LOG", value = "/dev/stdout" },
        { name = "KONG_PROXY_ERROR_LOG", value = "/dev/stderr" },
        { name = "KONG_ADMIN_ERROR_LOG", value = "/dev/stderr" },
        { name = "KONG_ADMIN_LISTEN", value = "127.0.0.1:8001" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-kong"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "256"
  execution_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  task_role_arn            = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${aws_ecr_repository.frontend.repository_url}:${var.frontend_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.frontend_container_port
          hostPort      = var.frontend_container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "BACKEND_INTERNAL_URL"
          value = "${aws_lb.backend_internal.dns_name}:${var.backend_container_port}"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-frontend"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-backend"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "kong" {
  name              = "/ecs/${var.project_name}-kong"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-frontend"
  retention_in_days = 30
}

# ------------------------------------------------------------------------------
# LOAD BALANCER PUBLICO: INTERNET -> FRONTEND Y /gateway -> KONG
# ------------------------------------------------------------------------------
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.public_subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "kong" {
  name                 = "${var.project_name}-kong-tg"
  port                 = var.kong_proxy_port
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"
  deregistration_delay = 10

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/gateway/alive"
    port                = "traffic-port"
  }

  tags = { Name = "${var.project_name}-kong-tg" }
}

resource "aws_lb_target_group" "frontend" {
  name                 = "${var.project_name}-frontend-tg"
  port                 = var.frontend_container_port
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"
  deregistration_delay = 10

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    port                = "traffic-port"
  }

  tags = { Name = "${var.project_name}-frontend-tg" }
}

resource "aws_lb" "backend_internal" {
  name               = "${var.project_name}-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.backend_alb.id]
  subnets            = local.private_subnet_ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "backend" {
  name                 = "${var.project_name}-backend-tg"
  port                 = var.backend_container_port
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id
  target_type          = "ip"
  deregistration_delay = 10

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = var.backend_health_check_path
    port                = "traffic-port"
  }

  tags = { Name = "${var.project_name}-backend-tg" }
}

resource "aws_lb_listener" "backend_internal" {
  load_balancer_arn = aws_lb.backend_internal.arn
  port              = var.backend_container_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "gateway_to_kong" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kong.arn
  }

  condition {
    path_pattern {
      values = ["/gateway", "/gateway/*"]
    }
  }
}

# ------------------------------------------------------------------------------
# SERVICIOS ECS SEPARADOS
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    subnets         = local.private_subnet_ids
    security_groups = [aws_security_group.backend.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = var.backend_container_port
  }

  depends_on = [
    aws_ecs_cluster_capacity_providers.main,
    aws_db_instance.mysql,
    aws_lb_listener.backend_internal
  ]
}

resource "aws_ecs_service" "kong" {
  name            = "${var.project_name}-kong-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.kong.arn
  desired_count   = 1
  launch_type     = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  health_check_grace_period_seconds = 30

  network_configuration {
    subnets         = local.public_subnet_ids
    security_groups = [aws_security_group.kong.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.kong.arn
    container_name   = "kong"
    container_port   = var.kong_proxy_port
  }

  depends_on = [
    aws_ecs_service.backend,
    aws_lb_listener_rule.gateway_to_kong,
    aws_lb_listener.http,
    aws_ecs_cluster_capacity_providers.main
  ]
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.project_name}-frontend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "EC2"

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  health_check_grace_period_seconds = 30

  network_configuration {
    subnets         = local.private_subnet_ids
    security_groups = [aws_security_group.frontend.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = var.frontend_container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_ecs_cluster_capacity_providers.main
  ]
}
