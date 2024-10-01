output "iscsi_server_ip" {
  description = "IP-адрес iSCSI сервера"
  value       = virtualbox_vm.iscsi_server.network_adapter.0.ipv4_address
}

output "cluster_nodes_ip" {
  description = "IP-адреса узлов кластера"
  value       = [for node in virtualbox_vm.cluster_node: node.network_adapter.0.ipv4_address]
}