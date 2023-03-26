provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "us-east-1"  # or your preferred AWS region
}
resource "aws_vpc" "demo_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "demo_vpc"
  }
}
resource "aws_ecs_cluster" "demo-app-cluster" {
  name = "demo-app-cluster"
}
resource "aws_ecr_repository" "demo_repo" {
  name = "demo-repo"
}
variable "image_uri" {
  type = string
}

resource "aws_ecs_task_definition" "demo-app-task" {
  family                   = "demo-app-task"
  container_definitions    = jsonencode([{
    name      = "demo-app-container"
    image     = var.image_uri
    portMappings = [{
      containerPort = 3000
      hostPort      = 0
      protocol      = "tcp"
    }]
  }])
   network_configuration {
    subnets         = aws_subnet.private.*.id
    security_groups = [aws_security_group.sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "demo-app-container"
    container_port   = 3000
  }
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
}
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"
  assume_role_policy = jsonencode({
  })
}
