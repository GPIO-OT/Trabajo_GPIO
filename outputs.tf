output "alb_dns_name" {
  description = "DNS del balanceador publico para acceder a Kong"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "Endpoint de la base de datos MySQL"
  value       = aws_db_instance.mysql.address
  sensitive   = true
}

output "ecr_repository_url" {
  description = "URL del repositorio ECR para subir la imagen del backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "kong_ecr_repository_url" {
  description = "URL del repositorio ECR para subir la imagen de Kong"
  value       = aws_ecr_repository.kong.repository_url
}

output "frontend_ecr_repository_url" {
  description = "URL del repositorio ECR para subir la imagen del frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_private_dns_name" {
  description = "DNS privado del balanceador interno del backend"
  value       = aws_lb.backend_internal.dns_name
}
