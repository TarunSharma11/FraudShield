# FraudShield on AWS


This repository bootstraps an AWS deployment for the FraudShield architecture using **Terraform**, **Amazon MSK (Kafka)**, **Amazon Managed Service for Apache Flink**, **ElastiCache Redis**, **Amazon Timestream**, and **ECS Fargate** for a FastAPI sync API.

## Architecture:

<img width="2568" height="944" alt="image" src="https://github.com/user-attachments/assets/0d98b255-f6bd-435c-8b8a-a352ed0f89ef" />

## What it creates
- **VPC** with public/private subnets, NAT, IGW
- **MSK (Kafka)** cluster
- **ElastiCache Redis** replication group
- **Amazon Timestream** database & table
- **ECS Fargate** service for FastAPI (ALB exposed on port 80)
- **S3 bucket** for Flink job artifacts
- **KDA v2 (Managed Flink)** application scaffold (expects a JAR in S3)
- **CloudWatch Logs** groups/streams
- Sample **FastAPI** app and **Kafka producer**

## Prerequisites
- Terraform >= 1.6
- AWS credentials configured
- Docker (to build and push the FastAPI image to ECR)

## Quickstart

1) **Build & push FastAPI image** (to ECR or any registry) and set `var.fastapi_image`.
   ```bash
   cd apps/fastapi
   docker build -t fraudshield-fastapi:latest .
   # (Optional) Tag & push to ECR
   ```

2) **Terraform apply**
   ```bash
   cd terraform
   terraform init
   terraform apply -auto-approve \
     -var="project_name=fraudshield" \
     -var="aws_region=us-east-1" \
     -var="fastapi_image=<your-ecr-repo>:tag"
   ```

3) **Outputs**
   - `alb_dns_name` — call `http://<alb_dns_name>/health`
   - `msk_bootstrap_brokers` — use in the producer
   - `redis_endpoint` — used by FastAPI & job
   - `timestream_db` — Timestream database name

4) **Run the producer** (local or in VPC):
   ```bash
   cd apps/producer
   pip install -r requirements.txt
   export KAFKA_BOOTSTRAP=<msk_bootstrap_brokers_from_output>
   python producer.py
   ```

5) **Flink job**
   - Build your Flink job JAR and upload to S3 `fraudshield-flink-artifacts-<region>/jobs/fraudshield-job.jar`.
   - Start the KDA app (Managed Flink) in the AWS Console or via Terraform updates.

## Notes
- MSK is configured with client_broker `PLAINTEXT` for dev simplicity inside VPC. For prod, switch to TLS/SASL and restrict SGs.
- Redis transit encryption is off for dev. Turn on TLS in production and rotate auth tokens.
- The FastAPI here is a simple cache/lookup façade. Real-time scoring happens in Flink; API returns cached decisions.
- Replace Timestream with TimescaleDB on RDS if you prefer Postgres-native timeseries and SQL.
- Consider Amazon Managed Grafana + AMP for metrics. This starter uses CloudWatch Logs.

## Cleaning up
```bash
cd terraform
terraform destroy -auto-approve
```
