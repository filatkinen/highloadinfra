variable "yc_cloud_id" {
  description = "Yandex Cloud Cloud ID"
  type        = string
  default     = "b1g3d6e73c5fbb1so2ad"
}

variable "yc_folder_id" {
  description = "Yandex Cloud "
  type        = string
  default     = "b1g1d9hkg1h8bh48ddj8"
}

variable "yc_zone" {
  description = "Yandex Cloud Zone"
  type        = string
  default     = "ru-central1-a"
}

variable "yc_service_account_key_file" {
  description = "Path to the Yandex Cloud service account"
  type        = string
  default     = "./key-hliuser-api.json"
}

variable "ssh_key" {
  type    = string
  default = "./id_rsa.pub"
}