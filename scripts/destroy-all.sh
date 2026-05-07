#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
CLUSTER="${ECS_CLUSTER:-backend-web-cluster}"
ASG_NAME="${ASG_NAME:-backend-web-asg}"
SERVICES=(
  "backend-web-kong-service"
  "backend-web-frontend-service"
  "backend-web-backend-service"
)

cd "$PROJECT_ROOT"

aws_safe() {
  aws "$@" 2>/dev/null || true
}

wait_until_no_tasks() {
  local service="$1"
  local deadline=$((SECONDS + 900))

  while (( SECONDS < deadline )); do
    local running pending
    running="$(aws ecs describe-services \
      --cluster "$CLUSTER" \
      --services "$service" \
      --region "$REGION" \
      --query 'services[0].runningCount' \
      --output text 2>/dev/null || echo 0)"
    pending="$(aws ecs describe-services \
      --cluster "$CLUSTER" \
      --services "$service" \
      --region "$REGION" \
      --query 'services[0].pendingCount' \
      --output text 2>/dev/null || echo 0)"

    if [[ "$running" == "0" && "$pending" == "0" ]]; then
      return 0
    fi

    echo "    $service still has running=$running pending=$pending"
    sleep 15
  done

  echo "    Timed out waiting for $service tasks to stop"
  return 1
}

wait_until_asg_empty() {
  local deadline=$((SECONDS + 900))

  while (( SECONDS < deadline )); do
    local count
    count="$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "$ASG_NAME" \
      --region "$REGION" \
      --query 'length(AutoScalingGroups[0].Instances)' \
      --output text 2>/dev/null || echo 0)"

    if [[ "$count" == "0" || "$count" == "None" ]]; then
      return 0
    fi

    echo "    ASG $ASG_NAME still has $count instance(s)"
    complete_asg_termination_lifecycle_hooks
    sleep 20
  done

  return 1
}

complete_asg_termination_lifecycle_hooks() {
  local hook_names instance_ids hook_name instance_id

  hook_names="$(aws autoscaling describe-lifecycle-hooks \
    --auto-scaling-group-name "$ASG_NAME" \
    --region "$REGION" \
    --query 'LifecycleHooks[?LifecycleTransition==`autoscaling:EC2_INSTANCE_TERMINATING`].LifecycleHookName' \
    --output text 2>/dev/null || true)"

  [[ -n "$hook_names" && "$hook_names" != "None" ]] || return 0

  instance_ids="$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$ASG_NAME" \
    --region "$REGION" \
    --query 'AutoScalingGroups[0].Instances[?starts_with(LifecycleState, `Terminating:Wait`)].InstanceId' \
    --output text 2>/dev/null || true)"

  for hook_name in $hook_names; do
    [[ -n "$hook_name" ]] || continue
    for instance_id in $instance_ids; do
      [[ -n "$instance_id" ]] || continue
      echo "    completing lifecycle hook $hook_name for $instance_id"
      aws_safe autoscaling complete-lifecycle-action \
        --auto-scaling-group-name "$ASG_NAME" \
        --lifecycle-hook-name "$hook_name" \
        --lifecycle-action-result CONTINUE \
        --instance-id "$instance_id" \
        --region "$REGION" >/dev/null
    done
  done
}

delete_available_enis_in_vpc() {
  local vpc_id="$1"
  local enis eni

  if [[ -z "$vpc_id" || "$vpc_id" == "None" ]]; then
    return 0
  fi

  echo "==> Deleting leftover available ENIs in $vpc_id"
  enis="$(aws ec2 describe-network-interfaces \
    --filters "Name=vpc-id,Values=$vpc_id" "Name=status,Values=available" \
    --region "$REGION" \
    --query 'NetworkInterfaces[].NetworkInterfaceId' \
    --output text 2>/dev/null || true)"

  for eni in $enis; do
    [[ -n "$eni" ]] || continue
    echo "    deleting ENI $eni"
    aws_safe ec2 delete-network-interface --network-interface-id "$eni" --region "$REGION"
  done
}

echo "==> Checking AWS credentials"
aws sts get-caller-identity >/dev/null

echo "==> Scaling ECS services to zero"
for service in "${SERVICES[@]}"; do
  if aws ecs describe-services --cluster "$CLUSTER" --services "$service" --region "$REGION" --query 'services[0].status' --output text >/dev/null 2>&1; then
    echo "    $service -> desired-count 0"
    aws_safe ecs update-service --cluster "$CLUSTER" --service "$service" --desired-count 0 --region "$REGION" >/dev/null
  fi
done

echo "==> Waiting for ECS tasks to stop"
for service in "${SERVICES[@]}"; do
  wait_until_no_tasks "$service" || true
done

echo "==> Scaling Auto Scaling Group to zero"
if aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names "$ASG_NAME" --region "$REGION" --query 'AutoScalingGroups[0].AutoScalingGroupName' --output text >/dev/null 2>&1; then
  aws_safe autoscaling update-auto-scaling-group \
    --auto-scaling-group-name "$ASG_NAME" \
    --min-size 0 \
    --desired-capacity 0 \
    --region "$REGION"

  if ! wait_until_asg_empty; then
    echo "==> ASG did not drain in time; terminating remaining ASG instances"
    instances="$(aws autoscaling describe-auto-scaling-groups \
      --auto-scaling-group-names "$ASG_NAME" \
      --region "$REGION" \
      --query 'AutoScalingGroups[0].Instances[].InstanceId' \
      --output text 2>/dev/null || true)"

    for instance_id in $instances; do
      [[ -n "$instance_id" ]] || continue
      echo "    terminating $instance_id"
      aws_safe autoscaling terminate-instance-in-auto-scaling-group \
        --instance-id "$instance_id" \
        --should-decrement-desired-capacity \
        --region "$REGION" >/dev/null
    done

    wait_until_asg_empty || true
  fi
fi

VPC_ID="$(terraform state show aws_vpc.main 2>/dev/null | sed -n 's/^[[:space:]]*id[[:space:]]*= "\(.*\)"/\1/p' | head -1 || true)"
delete_available_enis_in_vpc "$VPC_ID"

echo "==> Running Terraform destroy with retries"
for attempt in 1 2 3; do
  echo "    terraform destroy attempt $attempt"
  if terraform destroy -auto-approve; then
    echo "==> Destroy completed"
    exit 0
  fi

  echo "==> Terraform destroy failed; waiting and cleaning retryable leftovers"
  sleep 45
  delete_available_enis_in_vpc "$VPC_ID"
done

echo "Destroy did not complete after retries. Check remaining AWS dependencies above."
exit 1
