resource "aws_timestreamwrite_database" "tsdb" {
  database_name = "${var.project_name}_db"
  tags          = { Name = "${var.project_name}-timestream" }
}

resource "aws_timestreamwrite_table" "decisions" {
  database_name = aws_timestreamwrite_database.tsdb.database_name
  table_name    = "decisions"

  retention_properties {
    magnetic_store_retention_period_in_days = 3650
    memory_store_retention_period_in_hours  = 24
  }

  tags = { Name = "${var.project_name}-decisions" }
}
