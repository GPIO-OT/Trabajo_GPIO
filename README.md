# Trabajo_GPIO

Repositorio para subir las prácticas de la asignatura GPIO.

## Despliegue en AWS con Terraform
### Requisitos:
- Tener instalado Terraform.
- Tener instalado Docker
- Tener cuenta de AWS y configurar las credenciales en ~/.aws/credentials.

## Pasos a seguir:

En la carpeta raíz del proyecto ejecutamos:
```bash
terraform init
```

Creamos los repositorios ECR:
```bash
terraform apply \
  -target=aws_ecr_repository.backend \
  -target=aws_ecr_repository.kong \
  -target=aws_ecr_repository.frontend
```

Subimos las imágenes Docker:
```bash
./scripts/push-backend.sh
./scripts/push-kong.sh
./scripts/push-frontend.sh
```

Desplegamos la infraestructura:
```bash
terraform apply
```

En enlace lo obtenemos en la salida de este comando:
```bash
terraform output alb_dns_name
```

Esperamos unos segundos y ya podremos acceder a la web:
- Frontend: http://backend-web-alb-412722026.us-east-1.elb.amazonaws.com/
- API Gateway: http://backend-web-alb-412722026.us-east-1.elb.amazonaws.com/gateway/ -> Hay que pasarle el API Key (probar con curl).



## Depliegue en Local

### Requisitos
- Docker Desktop instalado y corriendo

### Poner en marcha la primera vez

En la carpeta raíz del proyecto, ejecutar:

```bash
docker compose build --no-cache
docker compose up -d
```

si no funciona, probar con sudo

```bash
sudo docker compose build --no-cache
sudo docker compose up -d
```

### Acceder a la aplicación

| Recurso  | URL                            |
| -------- | ------------------------------ |
| API      | http://localhost:5001/         |
| Swagger  | http://localhost:5001/swagger/ |
| Frontend | http://localhost:5002/         |

## Consultar logs del Frontend y Backend

```bash
docker-compose logs backend
docker-compose logs frontend
```

## Parar la aplicación

```bash
docker compose down
```

## Despliegue en AWS
### Requisitos
- Terraform instalado y conexión con la cuenta AWS (

### Poner en marcha la primera vez
En la carpeta raíz del proyecto, ejecutar:
- cd scripts
- ./push-backend.sh
- cd ../
- Terraform init
- terraform apply -auto-approve

### Acceder a la aplicación

| Recurso  | URL                            |
| -------- | ------------------------------ |
| Web     | http://backend-web-alb-1833745434.us-east-1.elb.amazonaws.com/         |
