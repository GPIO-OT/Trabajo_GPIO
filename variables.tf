variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto para recursos"
  type        = string
  default     = "backend-web"
}

variable "backend_image_tag" {
  description = "Tag de la imagen del backend en ECR"
  type        = string
  default     = "latest"
}

variable "kong_image_tag" {
  description = "Tag de la imagen de Kong en ECR"
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "Tag de la imagen del frontend en ECR"
  type        = string
  default     = "latest"
}

variable "vpc_cidr" {
  description = "CIDR principal de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_name" {
  description = "Nombre de la base de datos"
  type        = string
  default     = "OT_BD"
}

variable "db_username" {
  description = "Usuario administrador de MySQL"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña de MySQL (si no se proporciona, se genera aleatoria)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "backend_health_check_path" {
  description = "Ruta para health check del backend"
  type        = string
  default     = "/alive" # cámbiala si tu backend usa /alive u otra
}

variable "backend_container_port" {
  description = "Puerto interno del contenedor backend"
  type        = number
  default     = 5000
}

variable "kong_proxy_port" {
  description = "Puerto proxy HTTP de Kong"
  type        = number
  default     = 8000
}

variable "frontend_container_port" {
  description = "Puerto interno del contenedor frontend"
  type        = number
  default     = 80
}
