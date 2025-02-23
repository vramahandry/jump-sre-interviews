locals {
  name                  = var.db_name
  vpc_id                = var.vpc_id
  vpc_cidr_block        = var.vpc_cidr_block
  database_subnet_group = var.db_subnet_group
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "Complete PostgreSQL security group"
  vpc_id      = local.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = local.vpc_cidr_block
    },
  ]
}


module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier = local.name

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine                   = "postgres"
  engine_version           = "14"
  engine_lifecycle_support = "open-source-rds-extended-support-disabled"
  family                   = "postgres14" # DB parameter group
  major_engine_version     = "14"         # DB option group
  instance_class           = var.db_instance_class

  apply_immediately = true

  allocated_storage     = 20
  max_allocated_storage = 100


  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name  = "postgres"
  username = var.db_master_username
  port     = 5432

  manage_master_user_password = false
  password                    = var.db_master_password

  # # Setting manage_master_user_password_rotation to false after it
  # # has previously been set to true disables automatic rotation
  # # however using an initial value of false (default) does not disable
  # # automatic rotation and rotation will be handled by RDS.
  # # manage_master_user_password_rotation allows users to configure
  # # a non-default schedule and is not meant to disable rotation
  # # when initially creating / enabling the password management feature
  # manage_master_user_password_rotation              = true
  # master_user_password_rotate_immediately           = false
  # master_user_password_rotation_schedule_expression = "rate(15 days)"

  multi_az               = var.db_multi_az
  db_subnet_group_name   = local.database_subnet_group
  vpc_security_group_ids = [module.security_group.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

}