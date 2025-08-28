# Placeholder for Amazon Managed Service for Apache Flink (Kinesis Analytics v2)
# You will build your Flink app jar and upload to S3, then reference it below.
# The app can connect to MSK (Kafka) using VPC connectivity.
resource "aws_s3_bucket" "flink_artifacts" {
  bucket = "${var.project_name}-flink-artifacts-${var.aws_region}"
}

resource "aws_kinesisanalyticsv2_application" "flink" {
  name                   = "${var.project_name}-flink-app"
  runtime_environment    = "FLINK-1_15"
  service_execution_role = aws_iam_role.flink_role.arn

  application_configuration {
    application_code_configuration {
      code_content {
        s3_content_location {
          bucket_arn = aws_s3_bucket.flink_artifacts.arn
          file_key   = "jobs/fraudshield-job.jar"   # upload your Flink JAR here
        }
      }
      code_content_type = "ZIPFILE" # or "PLAINTEXT" when using SQL; ZIPFILE when using JAR
    }
    environment_properties {
      property_group {
        property_group_id = "appProps"
        properties = {
          "KAFKA_BOOTSTRAP" = aws_msk_cluster.this.bootstrap_brokers
          "INPUT_TOPIC"     = "transactions.raw"
          "OUTPUT_TOPIC"    = "fraud.decisions"
          "REDIS_HOST"      = aws_elasticache_replication_group.redis.primary_endpoint_address
          "REDIS_PORT"      = "6379"
          "TIMESTREAM_DB"   = aws_timestreamwrite_database.tsdb.database_name
          "AWS_REGION"      = var.aws_region
        }
      }
    }
  }

  cloud_watch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink_logs.arn
  }
}

resource "aws_iam_role" "flink_role" {
  name = "${var.project_name}-flink-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "kinesisanalytics.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "flink_role_policy" {
  name = "${var.project_name}-flink-policy"
  role = aws_iam_role.flink_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"], Resource = "*" },
      { Effect = "Allow", Action = ["kafka:GetBootstrapBrokers","kafka:DescribeCluster"], Resource = "*" },
      { Effect = "Allow", Action = ["s3:GetObject","s3:ListBucket"], Resource = ["${aws_s3_bucket.flink_artifacts.arn}", "${aws_s3_bucket.flink_artifacts.arn}/*"] },
      { Effect = "Allow", Action = ["timestream:WriteRecords","timestream:DescribeEndpoints"], Resource = "*" }
    ]
  })
}

resource "aws_cloudwatch_log_group" "flink_lg" {
  name = "/aws/kinesis-analytics/${var.project_name}"
}

resource "aws_cloudwatch_log_stream" "flink_logs" {
  name           = "${var.project_name}-flink"
  log_group_name = aws_cloudwatch_log_group.flink_lg.name
}
