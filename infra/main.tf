data "null_data_source" "env_name" {
  inputs = {
    name = join("-", [lower(var.region_short_name[data.aws_region.current.id]), "${var.env}${var.customer}", var.product])
  }
}

locals {
  common_tags = {
    Env     = data.null_data_source.env_name.outputs["name"]
    Region  = data.aws_region.current.id
    Owner   = var.owner
    Product = var.product
  }
}

module "network" {
  source      = "./modules/network"
  env_name    = data.null_data_source.env_name.outputs["name"]
  region      = data.aws_region.current.id
  logs_bucket = module.prerequisites.logs_bucket.id
  common_tags = local.common_tags
  owner       = var.owner
  vpc_cidr    = var.vpc_cidr
}

module "prerequisites" {
  source      = "./modules/prerequisites"
  env_name    = data.null_data_source.env_name.outputs["name"]
  region      = data.aws_region.current.id
  common_tags = local.common_tags
}

module "ecs" {
  source          = "./modules/ecs"
  env_name        = data.null_data_source.env_name.outputs["name"]
  region          = data.aws_region.current.id
  private_subnets = module.network.subnets_private.*.id
  common_tags     = local.common_tags
}

module "frontend" {
  source      = "./modules/service"
  service     = "frontend"
  ecs_cluster = module.ecs.ecs_cluster
  env_name    = data.null_data_source.env_name.outputs["name"]
  region      = data.aws_region.current.id
  common_tags = local.common_tags
  app_version = var.frontend_version
  subnets     = module.network.subnets_public.*.id
  access_cidr = module.network.subnets_public.*.cidr_block
  vpc_id      = module.network.vpc.id
  logs_bucket = module.prerequisites.logs_bucket.id
}

module "backend" {
  source      = "./modules/service"
  service     = "backend"
  ecs_cluster = module.ecs.ecs_cluster
  env_name    = data.null_data_source.env_name.outputs["name"]
  region      = data.aws_region.current.id
  common_tags = local.common_tags
  app_version = var.backend_version
  subnets     = module.network.subnets_private.*.id
  access_cidr = module.network.subnets_private.*.cidr_block
  vpc_id      = module.network.vpc.id
  logs_bucket = module.prerequisites.logs_bucket.id
}

module "rds" {
  source            = "./modules/rds"
  env_name          = data.null_data_source.env_name.outputs["name"]
  region            = data.aws_region.current.id
  vpc_id            = module.network.vpc.id
  subnets           = module.network.subnets_private.*.id
  common_tags       = local.common_tags
  db_engine_version = var.db_engine_version
  username          = var.db_username
  allowed_cidr      = module.network.subnets_private.*.cidr_block
}