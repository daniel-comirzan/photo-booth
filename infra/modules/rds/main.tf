resource "random_password" "aurora_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "aurora_password" {
  name  = join("/", ["", var.env_name, "db_password"])
  type  = "SecureString"
  value = random_password.aurora_password.result

  overwrite = true

  tags = var.common_tags
}

resource "aws_db_subnet_group" "aurora_subnet_group" {

  name_prefix = var.env_name
  description = "Database subnet group for ${var.env_name}"
  subnet_ids  = var.subnets

  tags = merge(
    var.common_tags,
    {
      "Name" = format("%s", var.env_name)
    },
  )
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier = var.env_name

  engine         = var.db_engine
  engine_mode    = var.db_engine_mode
  engine_version = var.db_engine_version

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  database_name                       = var.name
  master_username                     = var.username
  master_password                     = aws_ssm_parameter.aurora_password.value
  port                                = coalesce(var.port, local.port)
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  snapshot_identifier = var.snapshot_identifier

  vpc_security_group_ids          = [aws_security_group.aurora.id]
  db_subnet_group_name            = aws_db_subnet_group.aurora_subnet_group.name
  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name

  availability_zones = var.availability_zones

  apply_immediately            = var.apply_immediately
  preferred_maintenance_window = var.maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot
  final_snapshot_identifier    = var.final_snapshot_identifier

  backtrack_window        = var.backtrack_window
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.backup_window

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  deletion_protection = var.deletion_protection

  dynamic "scaling_configuration" {
    for_each = length(keys(var.scaling_configuration)) == 0 ? [] : [var.scaling_configuration]

    content {
      auto_pause               = lookup(scaling_configuration.value, "auto_pause", null)
      max_capacity             = lookup(scaling_configuration.value, "max_capacity", null)
      min_capacity             = lookup(scaling_configuration.value, "min_capacity", null)
      seconds_until_auto_pause = lookup(scaling_configuration.value, "seconds_until_auto_pause", null)
      timeout_action           = lookup(scaling_configuration.value, "timeout_action", null)
    }
  }

  tags = merge(
    var.common_tags,
    {
      "Name" = var.env_name
    },
  )

  timeouts {
    create = lookup(var.timeouts, "create", null)
    delete = lookup(var.timeouts, "delete", null)
    update = lookup(var.timeouts, "update", null)
  }

  lifecycle {
    ignore_changes = [availability_zones]
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                        = var.db_engine_mode == "serverless" ? 0 : 1
  identifier                   = join("-", [var.env_name, "db"])
  engine                       = var.db_engine
  cluster_identifier           = aws_rds_cluster.aurora_cluster.id
  instance_class               = var.instance_class
  monitoring_interval          = var.monitoring_interval
  monitoring_role_arn          = coalesce(var.monitoring_role_arn, aws_iam_role.enhanced_monitoring.*.arn, null)
  performance_insights_enabled = var.performance_insights_enabled

  tags = var.common_tags
}