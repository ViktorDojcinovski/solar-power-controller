variable "name" { type = string }
variable "project" { type = string }
variable "env" { type = string }


resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = { Project = var.project, Env = var.env }
}


resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = jsonencode({ rules = [{ rulePriority = 1, description = "Keep last 10", selection = { tagStatus = "any", countType = "imageCountMoreThan", countNumber = 10 }, action = { type = "expire" } }] })
}


output "repository_url" { value = aws_ecr_repository.this.repository_url }