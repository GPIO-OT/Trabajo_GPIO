# Trabajo_GPIO

Repositorio para subir las prácticas de la asignatura GPIO.

## Despliegue en AWS con Terraform
### Requisitos:
- Tener instalado Terraform.
- Tener instalado Docker
- Tener cuenta de AWS y configurar las credenciales en ~/.aws/credentials.

## Pasos a seguir:

En la carpeta raíz del proyecto ejecutamos el script de despliegue:
```bash
./scripts/deploy-all.sh                    
```

En enlace lo obtenemos en la salida de este comando:
```bash
terraform output alb_dns_name
```

Esperamos unos segundos y ya podremos acceder a la web:
| Recurso | URL                         |
|----------|-----------------------------|
| Web      | http://url.com/             |
| Gateway  | http://url/gateway/ruta     |

Si queremos borrar el despliegue para que no consuma recursos, ejecutamos el script de borrado:
```bash
./scripts/destroy-all.sh                 
```

## Despliegue continuo con GitHub Actions

El proyecto incluye un flujo de CD que se ejecuta automaticamente al hacer `push` sobre la rama `main`.

Este flujo:
- Construye las imagenes Docker de `backend`, `frontend` y `Kong`.
- Publica las imagenes en Amazon ECR.
- Fuerza un nuevo despliegue de los servicios en Amazon ECS.
- Espera a que los servicios queden estables antes de finalizar.

Importante: este flujo no ejecuta Terraform, por lo que solo actualiza la aplicacion desplegada y no modifica la infraestructura.

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



