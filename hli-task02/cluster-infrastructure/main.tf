provider "virtualbox" {
  host = "127.0.0.1"
}

# Определение iSCSI сервера
resource "virtualbox_vm" "iscsi_server" {
  name      = "iscsi-server"
  image     = var.vm_image
  cpus      = var.vm_cpu
  memory    = var.vm_memory
  network_adapter {
    type           = "bridged"
    bridge_adapter = "eth0"
  }
}

# Определение виртуальных машин для кластера
resource "virtualbox_vm" "cluster_node" {
  count     = 3
  name      = "cluster-node-${count.index + 1}"
  image     = var.vm_image
  cpus      = var.vm_cpu
  memory    = var.vm_memory
  network_adapter {
    type           = "bridged"
    bridge_adapter = "eth0"
  }
  storage {
    name   = "shared_disk"
    size   = 10
    device = "sda"
  }
}

# Вывод информации о виртуальных машинах
output "iscsi_server_ip" {
  value = virtualbox_vm.iscsi_server.network_adapter.0.ipv4_address
}

output "cluster_nodes_ip" {
  value = [for node in virtualbox_vm.cluster_node: node.network_adapter.0.ipv4_address]
}