terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  service_account_key_file = var.yc_service_account_key_file
  cloud_id                 = var.yc_cloud_id
  folder_id                = var.yc_folder_id
  zone                     = var.yc_zone
}


resource "yandex_vpc_network" "default" {
  name = "default-network"
}

resource "yandex_vpc_subnet" "default" {
  name           = "default-subnet"
  zone           = var.yc_zone
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_compute_instance" "vm" {
  name                      = "fenych-hli01-01"
  allow_stopping_for_update = true
  platform_id               = "standard-v1"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_key)}"
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd88bokmvjups3o0uqes"
      size     = 20 # Размер диска в ГБ
      type     = "network-hdd"

    }
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.default.id
    nat        = true # Включаем NAT для публичного IP
    ip_address = "10.0.0.9"
  }

  network_interface {
    subnet_id  = yandex_vpc_subnet.default.id
    ip_address = "10.0.0.10" # Локальный IP-адрес
  }


}

resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 5"
  }

  depends_on = [yandex_compute_instance.vm]
}

resource "null_resource" "ansible_provisioner" {
  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu -i '${yandex_compute_instance.vm.network_interface[0].nat_ip_address},' --private-key ${var.ssh_key} nginx-playbook.yml --ssh-extra-args='-o StrictHostKeyChecking=no  -o UserKnownHostsFile=/dev/null'"

  }
  depends_on = [null_resource.delay]
}