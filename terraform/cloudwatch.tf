# General-purpose CW Log group for the producer or other lambda/containers (optional)
resource "aws_cloudwatch_log_group" "general" {
  name              = "/aws/${var.project_name}/general"
  retention_in_days = 14
}
