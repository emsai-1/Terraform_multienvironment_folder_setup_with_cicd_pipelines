variable "bucket_name_prefix" {
  description = "A prefix for the S3 bucket name. The final name will be 'prefix-environment'."
  type        = string
}

variable "environment" {
  description = "The environment name (e.g., dev, qa, prod), appended to the bucket name."
  type        = string
}

variable "enable_versioning" {
  description = "If true, versioning will be enabled on the bucket."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}
