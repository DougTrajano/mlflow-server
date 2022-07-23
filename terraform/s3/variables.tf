variable "name" {
  type        = string
  description = "(Optional) A name for the application (e.g. mlflow)."
  default     = "mlflow"
}

variable "tags" {
  type        = map(string)
  description = "(Optional) AWS Tags common to all the resources created."
  default     = {}
}

variable "create_dedicated_bucket" {
  type        = bool
  description = "(Optional) Whether to create a dedicated S3 bucket for the application."
  default     = true
}
