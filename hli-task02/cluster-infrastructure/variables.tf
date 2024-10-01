variable "vm_cpu" {
  description = "Количество процессоров для каждой ВМ"
  default     = 2
}

variable "vm_memory" {
  description = "Объем оперативной памяти (в МБ) для каждой ВМ"
  default     = 2048
}

variable "vm_image" {
  description = "Путь к образу операционной системы для ВМ"
  default     = "/media/ubuntu.iso"
}