resource "aws_msk_cluster" "this" {
  cluster_name           = "${var.project_name}-msk"
  kafka_version          = var.msk_kafka_version
  number_of_broker_nodes = var.msk_broker_nodes

  broker_node_group_info {
    instance_type   = var.ec2_broker_instance_type
    client_subnets  = aws_subnet.private[*].id
    security_groups = [aws_security_group.msk_sg.id]
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "PLAINTEXT"   # For dev simplicity; switch to TLS or TLS_PLAINTEXT for prod
      in_cluster    = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk_lg.name
      }
    }
  }

  tags = { Name = "${var.project_name}-msk" }
}

resource "aws_cloudwatch_log_group" "msk_lg" {
  name              = "/aws/msk/${var.project_name}"
  retention_in_days = 14
}
