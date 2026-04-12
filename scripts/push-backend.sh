#!/bin/bash
set -e

# Obtener cuenta y región desde el contexto AWS
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
REPO_NAME="backend-web-backend"  # Debe coincidir con var.project_name + "-backend"
IMAGE_TAG="latest"

# Autenticarse en ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Construir la imagen (cambia la ruta si es necesario)
docker build -t $REPO_NAME ../Backend

# Etiquetar y subir
docker tag $REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

echo "Imagen subida correctamente"
