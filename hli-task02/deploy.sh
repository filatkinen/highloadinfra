#!/bin/bash

# Остановка выполнения скрипта при любой ошибке
set -e

# Параметры проекта
TERRAFORM_DIR="cluster-infrastructure"
ANSIBLE_INVENTORY_FILE="${TERRAFORM_DIR}/inventory"

# Параметры Ansible
ANSIBLE_PLAYBOOK_ISCSI="${TERRAFORM_DIR}/iscsi.yml"
ANSIBLE_PLAYBOOK_CLUSTER="${TERRAFORM_DIR}/cluster.yml"
ANSIBLE_PLAYBOOK_FENCING="${TERRAFORM_DIR}/fencing.yml"

# Шаг 1. Установка Terraform (если вдруг не установлен)
if ! command -v terraform &> /dev/null
then
    echo "Terraform не найден. Устанавливаю Terraform..."
    sudo apt-get update
    sudo apt-get install -y wget unzip
    wget https://releases.hashicorp.com/terraform/1.9.6/terraform_1.9.6_linux_amd64.zip
    unzip terraform_1.9.6_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    rm terraform_1.9.6_linux_amd64.zip
fi

# Шаг 2. Установка Ansible (если вдруг не установлен)
if ! command -v ansible &> /dev/null
then
    echo "Ansible не найден. Устанавливаю Ansible..."
    sudo apt update
    sudo apt install -y ansible
fi

# Шаг 3. Инициализация и развертывание инфраструктуры с помощью Terraform
echo "Инициализация Terraform..."
cd ${TERRAFORM_DIR}
terraform init

echo "Применение конфигурации Terraform для создания инфраструктуры..."
terraform apply -auto-approve

# Шаг 4. Получение IP-адресов виртуальных машин
echo "Получение IP-адресов созданных виртуальных машин..."
ISCSI_SERVER_IP=$(terraform output -raw iscsi_server_ip)
CLUSTER_NODES_IP=$(terraform output -json cluster_nodes_ip | jq -r '.[]')

echo "IP-адрес iSCSI сервера: $ISCSI_SERVER_IP"
echo "IP-адреса узлов кластера: $CLUSTER_NODES_IP"

# Шаг 5. Обновление файла inventory для Ansible
echo "Обновление файла inventory..."
cat <<EOF > ${ANSIBLE_INVENTORY_FILE}
[iscsi_server]
iscsi-server ansible_host=${ISCSI_SERVER_IP} ansible_user=vagrant

[cluster_nodes]
EOF

i=1
for ip in ${CLUSTER_NODES_IP}
do
    echo "cluster-node-${i} ansible_host=${ip} ansible_user=vagrant" >> ${ANSIBLE_INVENTORY_FILE}
    i=$((i+1))
done

cat <<EOF >> ${ANSIBLE_INVENTORY_FILE}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

# Шаг 6. Установка и настройка iSCSI сервера
echo "Запуск Ansible playbook для настройки iSCSI сервера..."
ansible-playbook -i ${ANSIBLE_INVENTORY_FILE} ${ANSIBLE_PLAYBOOK_ISCSI}

# Шаг 7. Настройка кластера и GFS2
echo "Запуск Ansible playbook для настройки кластера и GFS2..."
ansible-playbook -i ${ANSIBLE_INVENTORY_FILE} ${ANSIBLE_PLAYBOOK_CLUSTER}

# Шаг 8. Настройка fencing
echo "Запуск Ansible playbook для настройки fencing..."
ansible-playbook -i ${ANSIBLE_INVENTORY_FILE} ${ANSIBLE_PLAYBOOK_FENCING}

# Шаг 9. Проверка статуса кластера
echo "Проверка статуса кластера..."
ansible -i ${ANSIBLE_INVENTORY_FILE} cluster_nodes -a "pcs status"

echo "Готово"
