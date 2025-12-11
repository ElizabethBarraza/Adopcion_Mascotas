############################################
# PROVEEDOR
############################################
provider "aws" {
  region = var.aws_region
}

############################################
# CLOUDWATCH LOG GROUP (NUEVO)
############################################
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/mascotas"
  retention_in_days = 7
}

############################################
# VPC
############################################
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "mascotas-vpc"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = {
    Name = "public-subnet-2"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

############################################
# SECURITY GROUP
############################################
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow ALB"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
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
}


############################################
# LOAD BALANCER (ALB)
############################################
resource "aws_lb" "app_lb" {
  name               = "mascotas-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_subnet.id,
    aws_subnet.public_subnet_2.id
  ]
}


resource "aws_lb_target_group" "tg" {
  name        = "mascotas-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
  path                = "/api/pets"
  port                = "8080"
  protocol            = "HTTP"
  matcher             = "200"
  interval            = 30
  timeout             = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

############################################
# ECS CLUSTER
############################################
resource "aws_ecs_cluster" "cluster" {
  name = "mascotas-cluster"
}

############################################
# ECS TASK DEFINITION
############################################
resource "aws_ecs_task_definition" "task" {
  family                   = "mascotas-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "mascotas"
      image     = var.docker_image
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/mascotas"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }

      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}
############################################
# IAM ROLE PARA ECS FARGATE (EXECUTION ROLE)
############################################
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

############################################
# ECS SERVICE
############################################
resource "aws_ecs_service" "service" {
  name            = "mascotas-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
  subnets = [
    aws_subnet.public_subnet.id,
    aws_subnet.public_subnet_2.id,
  ]
  security_groups  = [aws_security_group.ecs_sg.id]
  assign_public_ip = true
}

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "mascotas"
    container_port   = 8080
  }
}

############################################
# OUTPUTS
############################################
output "load_balancer_url" {
  value = aws_lb.app_lb.dns_name
}
