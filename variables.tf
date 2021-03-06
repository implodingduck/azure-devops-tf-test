variable "project" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "key" {
  type = string
}

variable "container_name" {
  type = string
}


variable "subscription_name" {
  type = string
  sensitive = true
}

variable "serviceprincipalkey" {
  type = string
  sensitive = true
}