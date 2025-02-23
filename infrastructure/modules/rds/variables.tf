variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  type        = string
}

variable "db_name" {
  description = "Name of the db"
  type        = string
}

variable "db_subnet_group" {
  description = "Subnet group of the db"
  type        = string
}

variable "db_multi_az" {
  description = "Bool to setup multi az for db"
  type        = bool
}

variable "db_master_password" {
  description = "Master password of the db"
  type        = string
  sensitive   = true
}

variable "db_master_username" {
  description = "Master username of the db"
  type        = string
}

variable "db_instance_class" {
  description = "Instance class of the db"
  default     = "db.t4g.small"
  type        = string
}