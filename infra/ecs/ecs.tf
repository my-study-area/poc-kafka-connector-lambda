# ECS

## cluster
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 4.1.3"

  cluster_name = "pkcl-cluster"

  # * Allocate 20% capacity to FARGATE and then split
  # * the remaining 80% capacity 50/50 between FARGATE
  # * and FARGATE_SPOT.
  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        base   = 20
        weight = 50
      }
    }
    FARGATE_SPOT = {
      default_capacity_provider_strategy = {
        weight = 50
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "zookeeper" {
  name              = "/aws/ecs/${local.name}-zookeeper"
  retention_in_days = 7

  tags = {
    Name = "${local.name}-zookeeper"
  }
}

resource "aws_cloudwatch_log_group" "kafka" {
  name              = "/aws/ecs/${local.name}-kafka"
  retention_in_days = 7

  tags = {
    Name = "${local.name}-kafka"
  }
}

## task definition
resource "aws_ecs_task_definition" "pkcl-td" {
  container_definitions = <<DEFINITION
    [
      {
        "name": "${local.name}-zookeeper-td",
        "image": "confluentinc/cp-zookeeper:latest",
        "essential": true,
        "environment": [
          {"name": "ZOOKEEPER_CLIENT_PORT", "value": "2181"}
        ],
        "health_check": {
          "command": [
            "CMD-SHELL",
            "curl -f http://localhost:2181 || exit 1"
          ]
        },
        "portMappings": [
          {
            "containerPort": 2181,
            "hostPort": 2181
          }
        ],
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.zookeeper.name}",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "ecs"
          }
        }
      },
      {
        "name": "${local.name}-kafka-td",
        "image": "confluentinc/cp-kafka:latest",
        "essential": true,
            "environment": [
          {"name": "KAFKA_BROKER_ID", "value": "1"},
          {"name": "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR", "value": "1"},
          {"name": "KAFKA_ZOOKEEPER_CONNECT", "value": "localhost:2181"},
          {"name": "KAFKA_INTER_BROKER_LISTENER_NAME", "value": "INTERNAL"},
          {"name": "KAFKA_LISTENERS", "value": "INTERNAL://:9092,OUTSIDE://:9094"},
          {"name": "KAFKA_ADVERTISED_LISTENERS", "value": "INTERNAL://localhost:9092,OUTSIDE://host.docker.internal:9094"},
          {"name": "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP", "value": "INTERNAL:PLAINTEXT,OUTSIDE:PLAINTEXT"}
        ],
        "portMappings": [
          {
            "containerPort": 9094,
            "hostPort": 9094
          }
        ],
        "dependsOn": [
          {
            "condition": "START",
            "containerName": "${local.name}-zookeeper-td"
          }
        ],
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.kafka.name}",
            "awslogs-region": "us-east-1",
            "awslogs-stream-prefix": "ecs"
          }
        }
      }
    ]
    DEFINITION
  cpu = 1024
  execution_role_arn = resource.aws_iam_role.this.arn
  family = "family-of-pkcl-tasks"
  memory = 3072
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}

## ECS Service
resource "aws_ecs_service" "service-ecs" {
  cluster = module.ecs.cluster_arn
  desired_count = 2
  launch_type = "FARGATE"
  name = "pkcl-service"
  task_definition = aws_ecs_task_definition.pkcl-td.arn

  lifecycle {
    ignore_changes = [desired_count] # Allow external changes to happen without Terraform conflicts, particularly around auto-scaling.
  }

  network_configuration {
    security_groups = [aws_security_group.pkcl-ecs-service-sg.id]
    subnets = [aws_subnet.pkcl-private-a.id, aws_subnet.pkcl-private-b.id]
    assign_public_ip = true
  }
}
