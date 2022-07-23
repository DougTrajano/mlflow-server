module "s3" {
  source                  = "./s3"
  name                    = local.name
  tags                    = local.tags
  create_dedicated_bucket = local.create_dedicated_bucket
}
