module "network" {
  source   = "./modules/network"
  project  = var.project
  env      = var.env
  vpc_cidr = var.vpc_cidr
}

module "ecr" {
  source  = "./modules/ecr"
  name    = "power-controller-app"
  project = var.project
  env     = var.env
}

module "ecs_service" {
  source             = "./modules/ecs_service"
  project            = var.project
  env                = var.env
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids
  image_uri          = var.image_uri
  container_port     = 3000
  desired_count      = 1
  cpu                = 256
  memory             = 512
  health_check_path  = "/health"
  enable_waf         = true
}

module "cost_reporter" {
  source              = "./modules/cost_reporter_lambda"
  project             = var.project
  env                 = var.env
  slack_webhook_url   = "<SLACK_WEBHOOK_URL>"
  schedule_expression = "cron(0 7 * * ? *)" # 07:00 UTC daily
}