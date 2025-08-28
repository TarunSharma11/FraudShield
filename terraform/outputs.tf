output "alb_dns_name" {
  description = "ALB DNS name for FastAPI"
  value       = aws_lb.alb.dns_name
}

output "redis_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "msk_bootstrap_brokers" {
  value = aws_msk_cluster.this.bootstrap_brokers
}

output "timestream_db" {
  value = aws_timestreamwrite_database.tsdb.database_name
}
