variable "project_name" {
  type        = string
  description = "Project prefix used for names"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster short name"
}

variable "aws_region" {
  type        = string
  description = "AWS region for all resources"
}
