locals { name = "${var.project}-${var.env}-svc" }

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.env}-cluster"
}

# Security groups
resource "aws_security_group" "alb_sg" {
  name        = "${local.name}-alb-sg"
  description = "ALB inbound"
  vpc_id      = var.vpc_id
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


resource "aws_security_group" "svc_sg" {
  name        = "${local.name}-svc-sg"
  description = "Service inbound from ALB"
  vpc_id      = var.vpc_id
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "aws_lb" "alb" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
}


resource "aws_lb_target_group" "tg" {
  name        = "${local.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path                = var.health_check_path
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
  }
}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# IAM roles for tasks
resource "aws_iam_role" "task_execution" {
  name               = "${local.name}-exec"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
}


data "aws_iam_policy_document" "task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


resource "aws_iam_role_policy_attachment" "task_exec_attach" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task definition
resource "aws_ecs_task_definition" "task" {
  family                   = local.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn


  container_definitions = jsonencode([
    {
      name         = "app"
      image        = var.image_uri
      essential    = true
      portMappings = [{ containerPort = var.container_port, hostPort = var.container_port }]
      environment = [
        { name = "NODE_ENV", value = var.env }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${local.name}"
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"]
        interval    = 10
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}


data "aws_region" "current" {}


resource "aws_cloudwatch_log_group" "lg" {
  name              = "/ecs/${local.name}"
  retention_in_days = 14
}

# Service
resource "aws_ecs_service" "svc" {
  name            = local.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"


  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.svc_sg.id]
    assign_public_ip = false
  }


  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "app"
    container_port   = var.container_port
  }


  lifecycle { ignore_changes = [task_definition] } # allow rollouts by updating task def
}