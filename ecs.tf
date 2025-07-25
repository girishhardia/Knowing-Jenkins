# ecs.tf
# This file defines the core ECS resources, including the cluster,
# task definition, service, and load balancer.

# --- ECS Cluster ---
# A logical grouping of tasks or services.
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# --- Load Balancer (ALB) ---
# Distributes incoming application traffic across multiple targets,
# such as ECS tasks, in multiple Availability Zones.

# Security group for the load balancer. Allows inbound HTTP traffic.
resource "aws_security_group" "lb_sg" {
  name        = "${var.project_name}-lb-sg"
  description = "Allow HTTP inbound traffic for the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-lb-sg"
  }
}

# The load balancer itself.
resource "aws_lb" "main" {
  name               = "${var.project_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public[*].id # Place LB in public subnets

  tags = {
    Name = "${var.project_name}-lb"
  }
}

# The target group for the load balancer.
resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # Required for Fargate

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# The listener for the load balancer. Listens on port 80 (HTTP).
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


# --- ECS Task Definition and Service ---

# Security group for the ECS tasks. Allows traffic from the load balancer.
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "${var.project_name}-tasks-sg"
  description = "Allow inbound traffic from the ALB to the ECS tasks"
  vpc_id      = aws_vpc.main.id

  # Only allow inbound traffic from our load balancer's security group
  ingress {
    from_port       = 5000 # The port our Flask app runs on
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-tasks-sg"
  }
}

# IAM Role that ECS tasks will assume to run.
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach the required policy for ECS tasks to the role.
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# The blueprint for our application task.
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256  # 0.25 vCPU
  memory                   = 512  # 512MB
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  # The container definition.
  container_definitions = jsonencode([{
    name      = "${var.project_name}-container"
    # This is a placeholder image. We will update this later.
    image     = "nginx:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
    }]
  }])
}

# The ECS Service. This maintains the desired count of tasks and
# handles networking and load balancing.
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1 # Run one instance of our task
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.private[*].id # Run tasks in private subnets
    security_groups = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false # Do not assign public IPs to tasks
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "${var.project_name}-container"
    container_port   = 5000
  }

  # This dependency ensures the listener is created before the service
  # tries to register with it.
  depends_on = [aws_lb_listener.http]
}
