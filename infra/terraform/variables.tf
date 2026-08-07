
variable "aws_region" {
  description = "AWS region to deploy CloudCart infrastructure into"
  type        = string
  default     = "eu-west-1"
}

variable "project_name" {
  description = "Name prefix used for tagging and naming all resources"
  type        = string
  default     = "cloudcart"
}

variable "instance_type" {
  description = "EC2 instance type, must remain within AWS Free Tier"
  type        = string
  default     = "t3.small"
}

variable "my_ip" {
  description = "Your public IP address in CIDR notation, allowed to SSH into the instance"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the AWS EC2 key pair used for SSH access"
  type        = string
}
