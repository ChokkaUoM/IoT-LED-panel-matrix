variable "project_id" {
  type = string
  default = "iot-led-matrix"
}

variable "topic_retention_time" {
  type = string
  default = "600s"
}

variable "subscription_expiration_time" {
  type = string
  default = "2592000s"
}

variable "subscription_retry_backoff_time" {
  type = string
  default = "10s"
}

