# K8s Cluster Lab — Cluster Kubernetes from scratch sur AWS

Je voulais comprendre Kubernetes en profondeur avant de passer le CKA, donc plutôt que de partir sur un cluster managé (EKS), j'ai tout monté à la main avec `kubeadm` sur 3 instances AWS — control-plane, workers, réseau, tout.

Ça part de mon stage chez TELE2 où j'avais déjà touché à l'automatisation et au cloud privé, en beaucoup plus basique. Ici je voulais aller plus loin : un vrai cluster fonctionnel, une appli dessus, et tout le pipeline CI/CD autour.

## État du projet

Je documente ici précisément ce qui fonctionne réellement, testé, versus ce qui est écrit mais pas encore validé, versus ce qui n'est pas commencé. L'objectif : que ce README reflète toujours l'état réel du code, pas des intentions.

### Fonctionnel et testé
- Infrastructure AWS provisionnée avec Terraform (VPC, subnet, security group, 3 EC2)
- Cluster Kubernetes opérationnel : 1 control-plane + 2 workers, initialisé avec `kubeadm`
- CNI Calico installé, les 3 nœuds sont `Ready`
- Capture d'écran de preuve : `screenshots/`

- Application "API Supervision KPIs Réseau" déployée et testée : PostgreSQL + 2 réplicas FastAPI, endpoints /health, /kpi, /kpi/alerts fonctionnels via NodePort

###  Pas commencé
- Playbooks Ansible pour la préparation des nœuds
- Pipeline CI/CD (GitHub Actions)
- Ingress + NetworkPolicy
- RBAC et exemple de troubleshooting documenté
- Monitoring Prometheus/Grafana via Helm
- Documentation MkDocs + GitHub Pages


## Architecture

```
                    ┌─────────────────────┐
                    │   Internet Gateway    │
                    └──────────┬───────────┘
                               │
                    ┌──────────┴───────────┐
                    │   Subnet public (VPC)  │
                    │                        │
     ┌──────────────┼────────────────────────┼──────────────┐
     │              │                        │              │
┌────▼─────┐   ┌────▼─────┐            ┌─────▼────┐
│  control-  │   │ worker-1  │            │ worker-2  │
│  plane     │◄─►│           │◄──────────►│           │
│ (t3.small) │   │(t3.small) │            │(t3.small) │
└────────────┘   └───────────┘            └───────────┘
     Cluster Kubernetes monté avec kubeadm
```

## Stack technique

| Catégorie | Technologie | Statut |
|---|---|---|
| Cloud | AWS (EC2, VPC) | ✅ |
| IaC | Terraform | ✅ |
| Orchestration | Kubernetes (kubeadm) | ✅ |
| CNI | Calico | ✅ |
| Conteneurisation | Docker | 🔧 |
| Base de données | PostgreSQL | 🔧 |
| Configuration | Ansible | ⏳ |
| CI/CD | GitHub Actions | ⏳ |
| Ingress | NGINX Ingress Controller | ⏳ |
| Monitoring | Prometheus + Grafana (Helm) | ⏳ |
| Documentation | MkDocs + GitHub Pages | ⏳ |

## Structure du repo
```
├── terraform/ # Provisioning des 3 EC2 (fonctionnel)
├── scripts/ # Script de préparation des nœuds kubeadm (fonctionnel)
├── app/ # Code API KPI + Dockerfile (écrit, pas déployé)
├── manifests/ # Manifests Kubernetes de l'app (écrits, pas appliqués)
├── docs/ # Guides d'installation détaillés
├── screenshots/ # Captures d'écran du cluster fonctionnel
├── ansible/ # Vide pour l'instant
└── diagrams/ # Vide pour l'instant
```

## Utilisation

### Provisionner les 3 machines

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Édite terraform.tfvars avec ta Key Pair et ton IP publique

terraform init
terraform plan
terraform apply
```
### Initialiser le cluster

Suis le guide détaillé : `docs/02-init-cluster.md`

Toujours détruire l'infra après une session de travail pour ne pas consommer de budget inutilement :
```bash
terraform destroy
```

## Auteur

Aly Kaba — Ingénieur DevOps/Cloud & Réseaux
[LinkedIn](https://www.linkedin.com/in/aly-kaba-/) · kaba4380@gmail.com
