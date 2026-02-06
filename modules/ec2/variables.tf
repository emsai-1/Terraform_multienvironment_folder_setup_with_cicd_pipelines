variable "environment" {
  description = "The environment name (e.g., dev, qa, prod)."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet to launch the instance in."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type (e.g., t2.micro, m5.large)."
  type        = string
}

variable "ami_id" {
  description = "The ID of the Amazon Machine Image to use."
  type        = string
}

variable "app_port" {
  description = "The port the application will listen on."
  type        = number
  default     = 80
}
