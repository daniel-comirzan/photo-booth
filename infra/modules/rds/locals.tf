locals {
  port = contains(split("-", var.db_engine ), "postgresql" ) ? 5432 : contains(split("-", var.db_engine ), "mysql" ) ? 3306 : 0
}