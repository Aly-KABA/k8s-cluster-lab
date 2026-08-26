# K8s Cluster Lab — Cluster Kubernetes from scratch sur AWS

Construction d'un cluster Kubernetes complet avec `kubeadm` sur AWS, déploiement d'une application, CI/CD et monitoring — projet réalisé en préparation de la certification **CKA (Certified Kubernetes Administrator)**.

> Ce projet fait suite à mon expérience en tant qu'ingénieur DevOps junior chez TELE2 (mise en place d'environnements techniques, automatisation de tâches, documentation), montée en compétence avec les outils Kubernetes/Cloud actuels.

## Objectif

Monter un cluster Kubernetes "à la main" avec `kubeadm` (et non un service managé type EKS), pour comprendre en profondeur l'architecture d'un cluster — exactement ce qui est évalué à l'examen CKA — puis y déployer une vraie application avec un pipeline CI/CD complet.

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

*(Diagramme détaillé : voir `diagrams/`)*

## Stack technique

| Catégorie | Technologie |
|---|---|
| Cloud | AWS (EC2, VPC) |
| IaC | Terraform |
| Configuration | Ansible |
| Orchestration | Kubernetes (kubeadm) |
| CNI | Calico |
| Conteneurisation | Docker |
| CI/CD | GitHub Actions |
| Ingress | NGINX Ingress Controller |
| Monitoring | Prometheus + Grafana (Helm) |
| Documentation | MkDocs + GitHub Pages |

## Application déployée : API Supervision KPIs Réseau

Une API simulant un outil de supervision de KPIs réseau (latence, débit, taux de perte), en lien avec mon expérience d'étude de KPIs MCx durant mon parcours académique.

- **API** : FastAPI (Python) — endpoints `/health`, `/kpi`, `/kpi/alerts`
- **Base de données** : PostgreSQL
- **Déploiement** : 2 réplicas de l'API (répartition de charge), 1 instance PostgreSQL
- **Config** : seuils d'alerte et paramètres non-sensibles via ConfigMap, identifiants DB via Secret
- **Fiabilité** : `readinessProbe` et `livenessProbe` Kubernetes sur l'API

Guide complet de déploiement : `docs/03-deploy-app.md`

## Structure du repo

```
├── terraform/          # Provisioning des 3 EC2 (control-plane + 2 workers)
├── scripts/             # Script de préparation des nœuds (prérequis kubeadm)
├── ansible/              # Playbooks de configuration (à venir)
├── manifests/           # Manifests Kubernetes de l'app de démo (à venir)
├── .github/workflows/  # Pipelines CI/CD (à venir)
├── docs/                 # Documentation MkDocs (à venir)
└── diagrams/            # Schémas d'architecture
```

## État d'avancement

- [x] **Jour 1** — Terraform : provisioning des 3 EC2 + préparation automatique (containerd, kubeadm, kubelet, kubectl)
- [ ] **Jour 2** — Initialisation du cluster (`kubeadm init` + `kubeadm join`) + CNI Calico
- [x] **Jour 3-4** — Application "API Supervision KPIs Réseau" (FastAPI + PostgreSQL) : code, Dockerfile, manifests Kubernetes (Deployments, Services, ConfigMaps, Secrets, probes)
- [ ] **Jour 5** — Ansible pour la préparation des nœuds
- [ ] **Jour 6** — Ingress + NetworkPolicy
- [ ] **Jour 7** — RBAC + exemple de troubleshooting documenté
- [ ] **Jour 8** — Monitoring Prometheus/Grafana via Helm
- [ ] **Jour 9** — Documentation MkDocs + GitHub Pages
- [ ] **Jour 10** — Relecture, nettoyage, vérification finale

## Utilisation

### 1. Provisionner les 3 machines

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Édite terraform.tfvars avec ta Key Pair et ton IP publique

terraform init
terraform plan
terraform apply
```

### 2. Récupérer les IPs

```bash
terraform output
```

⚠️ **Toujours détruire l'infra après une session de travail** pour ne pas consommer de budget inutilement :
```bash
terraform destroy
```

## Coût

Budget maîtrisé : 3 instances `t3.small` sans NAT Gateway, allumées uniquement pendant les sessions de travail. Coût estimé sur l'ensemble du projet (10 jours) : **5 à 10 €**.

## Auteur

Aly Kaba — Ingénieur DevOps/Cloud & Réseaux
[LinkedIn](#) · kaba4380@gmail.com
