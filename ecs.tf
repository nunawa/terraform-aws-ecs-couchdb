resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.project_name}-ecs-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = {
    Name = "${var.project_name}-ecs-instance-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
  tags = {
    Name = "${var.project_name}-ecs-instance-profile"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# SSM parameter for ECS-optimized AMI
# docs: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/retrieve-ecs-optimized_AMI.html
data "aws_ssm_parameter" "ecs_optimized_ami_arm64" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"
}

resource "aws_instance" "ecs_host" {
  ami                  = data.aws_ssm_parameter.ecs_optimized_ami_arm64.value
  instance_type        = "t4g.small"
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name

  private_ip                  = cidrhost(aws_subnet.public.cidr_block, 10)
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ecs_instance_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
              
              mkdir -p /opt/couchdb/data
              EOF

  user_data_replace_on_change = true

  # Require the use of IMDSv2 for security
  # docs: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-IMDS-new-instances.html
  metadata_options {
    http_tokens = "required"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"
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
  tags = {
    Name = "${var.project_name}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "couchdb_logs" {
  name              = "${var.project_name}-couchdb-logs"
  retention_in_days = 7
  tags = {
    Name = "${var.project_name}-couchdb-logs"
  }
}

resource "aws_ecs_task_definition" "couchdb" {
  family                   = "${var.project_name}-couchdb-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  volume {
    name      = "couchdb-data-volume"
    host_path = "/opt/couchdb/data"
  }

  container_definitions = jsonencode([
    {
      name      = "couchdb-container"
      image     = "couchdb:3"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 5984
          hostPort      = var.couchdb_access_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "COUCHDB_USER", value = var.couchdb_admin_user },
        { name = "COUCHDB_PASSWORD", value = var.couchdb_admin_password }
      ]
      mountPoints = [
        {
          sourceVolume  = "couchdb-data-volume"
          containerPath = "/opt/couchdb/data"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.couchdb_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "couchdb"
        }
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-couchdb-task"
  }
}

resource "aws_ecs_service" "couchdb_service" {
  name            = "${var.project_name}-couchdb-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.couchdb.arn
  launch_type     = "EC2"
  desired_count   = 1

  tags = {
    Name = "${var.project_name}-couchdb-service"
  }
}
