variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "confluent_csp" {
  description = "Confluent Cloud Service Provider"
  type        = string
  default     = "AWS"
}

variable "confluent_csp_region" {
  description = "Confluent Cloud Service Provider Region"
  type        = string
  default     = "eu-central-1"
}

variable "resources_prefix" {
  description = "prefix used for Org level sub resources (e.g. Service Accounts, Environment) to avoid clashes in the case multiple instances target the same Organization"
  type        = string
  default     = ""
}



