variable "region" {
  type    = string
  default = "eu-central-1"
}
variable "project" {
  type    = string
  default = "power-controller-app"
}
variable "env" {
  type    = string
  default = "dev"
}

variable "image_uri" {
  description = "ECR image URI for backend"
  type        = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}