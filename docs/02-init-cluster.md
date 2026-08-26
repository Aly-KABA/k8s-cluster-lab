# Initialisation du cluster kubeadm — Guide Jour 2

Ce guide s'exécute **après** `terraform apply` (Jour 1), une fois que les 3 EC2 sont prêtes
(le script `scripts/node-setup.sh` a déjà installé containerd, kubeadm, kubelet, kubectl automatiquement).

Récupère d'abord les IPs :
```bash
cd terraform
terraform output
```

## 1. Sur le nœud control-plane uniquement

Connecte-toi en SSH :
```bash
ssh -i <ta-clé.pem> ubuntu@<IP_PUBLIQUE_CONTROL_PLANE>
```

Initialise le cluster (remplace `<IP_PRIVEE_CONTROL_PLANE>` par la valeur de `terraform output all_private_ips`) :
```bash
sudo kubeadm init \
  --apiserver-advertise-address=<IP_PRIVEE_CONTROL_PLANE> \
  --pod-network-cidr=192.168.0.0/16
```

⚠️ Garde précieusement la commande `kubeadm join ...` affichée à la fin de la sortie — elle contient le token nécessaire pour connecter les workers.

Configure `kubectl` pour ton utilisateur :
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Vérifie :
```bash
kubectl get nodes
# Le control-plane doit apparaître, en statut "NotReady" (normal, en attendant le CNI)
```

## 2. Installer le CNI Calico (toujours sur le control-plane)

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml
```

Attends quelques minutes puis vérifie :
```bash
kubectl get pods -n kube-system
# Tous les pods calico-* doivent passer en "Running"
```

## 3. Sur chaque worker (worker-1 et worker-2)

Connecte-toi en SSH à chaque worker et exécute la commande `kubeadm join` récupérée à l'étape 1 :
```bash
ssh -i <ta-clé.pem> ubuntu@<IP_PUBLIQUE_WORKER>

sudo kubeadm join <IP_PRIVEE_CONTROL_PLANE>:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>
```

## 4. Vérification finale (depuis le control-plane)

```bash
kubectl get nodes -o wide
```

Tu dois voir les 3 nœuds en statut `Ready` :
```
NAME             STATUS   ROLES           AGE   VERSION
control-plane    Ready    control-plane   5m    v1.30.x
worker-1         Ready    <none>          2m    v1.30.x
worker-2         Ready    <none>          2m    v1.30.x
```

🎉 Le cluster est opérationnel. Passe au Jour 3-4 pour déployer l'app de démo.

## Récupérer le kubeconfig en local (optionnel mais pratique)

Pour piloter le cluster depuis ton propre PC plutôt que depuis le control-plane :
```bash
scp -i <ta-clé.pem> ubuntu@<IP_PUBLIQUE_CONTROL_PLANE>:~/.kube/config ./kubeconfig
export KUBECONFIG=./kubeconfig
# Remplace ensuite l'IP privée par l'IP publique dans ce fichier kubeconfig
kubectl get nodes
```

## Régénérer un token de join (si expiré, valable 24h par défaut)

```bash
kubeadm token create --print-join-command
```
