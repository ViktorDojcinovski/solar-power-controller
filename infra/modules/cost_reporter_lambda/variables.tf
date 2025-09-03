variable "project" { type = string }
variable "env" { type = string }
variable "slack_webhook_url" { type = string }
variable "schedule_expression" {
  type    = string
  default = "rate(1 day)"
}