#!/bin/bash
# node-setup.sh
# Prépare une instance Ubuntu pour kubeadm (control-plane ou worker)
# Exécuté automatiquement au démarrage de l'EC2 via user_data.
set -euxo pipefail

# --- 1. Désactiver le swap (obligatoire pour kubelet) ---
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# --- 2. Charger les modules kernel nécessaires ---
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# --- 3. Paramètres sysctl requis pour le networking Kubernetes ---
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# --- 4. Installer containerd (runtime de conteneurs) ---
apt-get update
apt-get install -y containerd apt-transport-https ca-certificates curl gpg

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
# Activer SystemdCgroup, requis par kubelet
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# --- 5. Installer kubeadm, kubelet, kubectl (version figée pour la cohérence du cluster) ---
K8S_VERSION="1.30"

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_VERSION}/deb/ /" | \
  tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

echo "Node prêt pour kubeadm init / kubeadm join"
