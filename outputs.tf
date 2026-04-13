output "alb_dns_name" {
  description = "DNS del balanceador para acceder al backend"
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
