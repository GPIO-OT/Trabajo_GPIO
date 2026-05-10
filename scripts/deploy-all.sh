#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"

cd "$PROJECT_ROOT"

echo "==> Checking AWS credentials"
aws sts get-caller-identity >/dev/null
aws ec2 describe-vpcs --region "$REGION" --query 'Vpcs[0].VpcId' --output text >/dev/null

echo "==> Initializing and validating Terraform"
terraform init
terraform fmt -check
terraform validate

echo "==> Creating ECR repositories first"
terraform apply -auto-approve \
  -target=aws_ecr_repository.backend \
  -target=aws_ecr_repository.kong \
  -target=aws_ecr_repository.frontend

echo "==> Building and pushing Docker images"
"$SCRIPT_DIR/push-backend.sh"
"$SCRIPT_DIR/push-kong.sh"
"$SCRIPT_DIR/push-frontend.sh"

echo "==> Applying full infrastructure"
terraform apply -auto-approve

echo "==> Waiting for ECS services to stabilize"
if ! aws ecs wait services-stable \
  --cluster backend-web-cluster \
  --services backend-web-backend-service backend-web-kong-service backend-web-frontend-service \
  --region "$REGION"; then
  echo "==> ECS services did not stabilize. Recent service events:"
  aws ecs describe-services \
    --cluster backend-web-cluster \
    --services backend-web-backend-service backend-web-kong-service backend-web-frontend-service \
    --region "$REGION" \
    --query 'services[].{service:serviceName,desired:desiredCount,running:runningCount,pending:pendingCount,events:events[0:5].message}' \
    --output table
  exit 1
fi

ALB_DNS="$(terraform output -raw alb_dns_name)"
echo "==> Deployment ready"
echo "Frontend: http://${ALB_DNS}/"
echo "Gateway health: http://${ALB_DNS}/gateway/alive"
