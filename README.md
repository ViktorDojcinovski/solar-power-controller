# Quickstart

## 0) Prereqs

- AWS account + admin to create: S3 state bucket, DynamoDB lock table, OIDC-deploy role.
- GitHub repo secrets: `AWS_ROLE_ARN`, optionally `SLACK_WEBHOOK_URL`.

## 1) Terraform state backend

Update `infra/backend.tf` with your state bucket + lock table.

## 2) OIDC role (least-privilege)

- Trust policy: GitHub OIDC provider + your repo.
- Permissions: ECR (login/push), ECS, ALB, CloudWatch, IAM PassRole for the ECS exec role, Lambda for cost reporter, CE read-only.

## 3) First apply (local)

```bash
cd infra
terraform init
terraform workspace new dev || true
terraform plan -var "image_uri=<any-public-image>" -var-file envs/dev.tfvars
terraform apply -auto-approve -var "image_uri=<any-public-image>" -var-file envs/dev.tfvars
```

## 4) Push image via CI

- Commit backend changes → CI builds, scans, pushes to ECR, runs `plan/apply` with the pushed `IMAGE_URI`.

## 5) Access

- Output `alb_dns` → open in browser.

## 6) Cost Reporter

- Set `slack_webhook_url` (var or secret) → daily cost message in Slack.

## Notes

- Blue/Green: module is rolling-update by default; integrate CodeDeploy later if needed.
- WAF/TLS: add ACM + `aws_lb_listener` 443 listener; optionally attach AWS WAF managed rules.
- Scale-to-zero: set desired_count=0 in off-hours via a scheduled TF/CLI job or Application Auto Scaling schedules.
