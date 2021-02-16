variable "env_name" {
  type        = string
  description = "The environment name"
}

variable "region" {
  type        = string
  description = "Region in which the environment is deployed"
}

variable "common_tags" {
  type = map
}

variable "vpc_id" {
  type        = string
  description = "The VPC in which the DB will be created"
}

variable "subnets" {
  type        = list
  description = "The private subnets where the DB will be created."
}

variable "port" {
  type        = number
  description = "The DB port"
  default = null
}

variable "allowed_cidr" {
  type        = list
  default     = [""]
  description = "The CIDR ranges from where the DB can be accessed."
}

# List of available engines: https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html
variable "db_engine" {
  description = "The database engine to use: aurora, aurora-mysql, aurora-postgresql"
  type        = string
  default     = "aurora-postgresql"
}

# Read about limitations of serverless: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless.html
variable "db_engine_mode" {
  description = "The database engine mode. Valid values: global, multimaster, parallelquery, provisioned, serverless"
  type        = string
  default     = "serverless"
}

# List of engines for Postgres: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts.General.DBVersions
# or aws rds describe-db-engine-versions --engine aurora-postgresql --output text
variable "db_engine_version" {
  description = "The engine version to use: 10.5, 10.6, 10.7, etc"
  type        = string
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = false
}

# List of avalable DB instances https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html
variable "instance_class" {
  description = "The instance type of the RDS instance: db.t2, db.t3, db.r4, db.r5, db.x1, db.m4, db.m5, etc"
  type        = string
  default     = ""
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN. If storage_encrypted is set to true and kms_key_id is not specified the default KMS key created in your account will be used"
  type        = string
  default     = ""
}

variable "name" {
  description = "The DB name to create. If omitted, no database is created initially"
  type        = string
  default     = ""
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
}

variable "aurora_password_parameter_name" {
  description = "Name of the parameter from ParameterStore with password for the master DB user"
  type        = string
  default     = ""
}

variable "db_cluster_parameter_group_name" {
  description = "A cluster parameter group to associate with the cluster."
  type        = string
  default     = ""
}

variable "iam_database_authentication_enabled" {
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  type        = bool
  default     = false
}

variable "snapshot_identifier" {
  description = "Specifies whether or not to create this database from a snapshot. This correlates to the snapshot ID you'd find in the RDS console, e.g: rds:production-2015-06-26-06-05."
  type        = string
  default     = ""
}

variable "availability_zones" {
  description = "A list of EC2 Availability Zones for the DB cluster storage where DB cluster instances can be created."
  type        = list(string)
  default     = [""]
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created. If false is specified, a DB snapshot is created before the DB instance is deleted, using the value from final_snapshot_identifier"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "On delete, copy all Instance tags to the final snapshot (if final_snapshot_identifier is specified)"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 1
}

variable "final_snapshot_identifier" {
  description = "The name of your final DB snapshot when this DB instance is deleted."
  type        = string
  default     = null
}

variable "backtrack_window" {
  description = "The target backtrack window, in seconds. To disable backtracking, set to 0. Must be between 0 and 259200 (72 hours)"
  type        = number
  default     = 0
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance_window"
  type        = string
  default     = "03:00-06:00"
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL), upgrade (PostgreSQL)."
  type        = list(string)
  default     = []
}

variable "timeouts" {
  description = "(Optional) Updated Terraform resource management timeouts. Applies to `aws_db_instance` in particular to permit resource management times"
  type        = map(string)
  default = {
    create = "40m"
    update = "80m"
    delete = "40m"
  }
}

variable "deletion_protection" {
  description = "The database can't be deleted when this value is set to true."
  type        = bool
  default     = false
}

variable "scaling_configuration" {
  description = "Map of nested attributes with scaling properties. Only valid when engine_mode is set to `serverless`"
  type        = map(string)
  default     = {}
}

variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60."
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs. Must be specified if monitoring_interval is non-zero."
  type        = string
  default     = ""
}

variable "monitoring_role_name" {
  description = "Name of the IAM role which will be created when create_monitoring_role is enabled."
  type        = string
  default     = "rds-monitoring-role"
}

variable "create_monitoring_role" {
  description = "Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs."
  type        = bool
  default     = false
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = false
}