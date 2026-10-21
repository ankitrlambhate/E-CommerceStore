variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used for resource names and tags"
  type        = string
  default     = "ecommerce"
}

variable "dockerhub_username" {
  description = "Docker Hub account (or org) that hosts the 5 public images"
  type        = string
}

variable "image_tag" {
  description = "Tag of the images to deploy"
  type        = string
  default     = "latest"
}

variable "instance_type" {
  description = "EC2 instance type (MongoDB + 4 Node services + nginx need ~2 GB RAM)"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "Optional name of an existing EC2 key pair, for SSH access. Leave null to skip."
  type        = string
  default     = null
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH (port 22). Restrict this to your own IP, e.g. 203.0.113.7/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block of the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}
