variable "project_name" {
  description = "Project name (used as prefix for resource names)"
  type        = string
  default     = "ecs-couchdb"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-northeast-1"
}

variable "ssh_access_cidr" {
  description = "List of CIDR blocks allowed for SSH access to EC2 instances"
  type        = list(string)
  sensitive   = true
  # No default, should be provided via .tfvars or command line
}

variable "ssh_access_ipv6_cidr" {
  description = "List of IPv6 CIDR blocks allowed for SSH access to EC2 instances"
  type        = list(string)
  sensitive   = true
  # No default, should be provided via .tfvars or command line
}

variable "couchdb_access_cidr" {
  description = "List of CIDR blocks allowed to access CouchDB"
  type        = list(string)
  sensitive   = true
  # No default, should be provided via .tfvars or command line
}

variable "couchdb_access_ipv6_cidr" {
  description = "List of IPv6 CIDR blocks allowed to access CouchDB"
  type        = list(string)
  sensitive   = true
  # No default, should be provided via .tfvars or command line
}

variable "couchdb_admin_user" {
  description = "CouchDB administrator username"
  type        = string
  sensitive   = true
  # No default, should be provided via .tfvars or command line
}

variable "couchdb_admin_password" {
  description = "CouchDB administrator password"
  type        = string
  sensitive   = true
  # No default, should be provided via .tfvars or command line
}
