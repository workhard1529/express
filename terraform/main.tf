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
resource "aws_ecr_repository" "demo_repo" {
  name = "demo-repo"
}
resource "aws_ecs_task_definition" "my_task_def" {
  family                   = "my_task_def"
  container_definitions    = jsonencode([{
    name      = "demo-container"
    image     = "${aws_ecr_repository.demo_repo.repository_url}:latest"
    memory    = 128
    cpu       = 128
  }])
}
resource "aws_ecs_service" "demo_ecs" {
  name            = "demo_ecs"
  task_definition = aws_ecs_task_definition.my_task_def.arn
  desired_count   = 1

  network_configuration {
    subnets         = aws_subnet.private.*.id
    security_groups = [aws_security_group.sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "demo-container"
    container_port   = 80
  }

  depends_on = [
    aws_iam_role.ecs_task_execution_role,
    aws_iam_role_policy.ecs_task_execution_role,
  ]
}
