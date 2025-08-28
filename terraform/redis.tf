resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnets"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${var.project_name}-redis"
  replication_group_description = "FraudShield Redis for features/decisions"
  engine                        = "redis"
  engine_version                = "7.1"
  node_type                     = var.redis_node_type
  number_cache_clusters         = var.redis_num_nodes
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  subnet_group_name             = aws_elasticache_subnet_group.redis.name
  security_group_ids            = [aws_security_group.redis_sg.id]
  at_rest_encryption_enabled    = true
  transit_encryption_enabled    = false  # set true if you prefer TLS
  port                          = 6379
  tags = { Name = "${var.project_name}-redis" }
}
