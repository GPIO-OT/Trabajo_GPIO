#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Obtener cuenta y región desde el contexto AWS
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
REPO_NAME="backend-web-backend"  # Debe coincidir con var.project_name + "-backend"
IMAGE_TAG="latest"

# Autenticarse en ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Construir la imagen para las EC2 de ECS, que son linux/amd64.
docker buildx build --platform linux/amd64 -t $REPO_NAME "$PROJECT_ROOT/Backend" --load

# Etiquetar y subir
docker tag $REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

echo "Imagen subida correctamente"
