variable "project_name" {
  description = "Project slug used for the repository name."
  type        = string
}

variable "environment" {
  description = "Environment name used for the repository name."
  type        = string
}

variable "retained_image_count" {
  description = "Number of recent images retained by the ECR lifecycle policy."
  type        = number
  default     = 10

  validation {
    condition     = var.retained_image_count >= 1 && var.retained_image_count <= 100
    error_message = "retained_image_count must be between 1 and 100."
  }
}

variable "tags" {
  description = "Additional tags applied to registry resources."
  type        = map(string)
  default     = {}
}
