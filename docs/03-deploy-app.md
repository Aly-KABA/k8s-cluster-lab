# Déployer l'API KPI sur le cluster — Guide Jour 3-4

## 1. Créer un compte Docker Hub (gratuit)

Si tu n'en as pas déjà un : https://hub.docker.com/signup
Note bien ton pseudo, on en aura besoin partout ensuite.

## 2. Construire l'image Docker

Depuis ton PC (pas besoin d'être sur le cluster pour cette étape) :

```bash
cd app
docker build -t TON-PSEUDO-DOCKERHUB/kpi-api:v1 .
```

Teste-la en local avant de la pousser (optionnel mais recommandé) :
```bash
docker run -p 8000:8000 -e DB_HOST=localhost TON-PSEUDO-DOCKERHUB/kpi-api:v1
```
(Elle plantera si tu n'as pas de PostgreSQL en local — c'est normal, c'était juste pour vérifier qu'elle démarre.)

## 3. Pousser l'image sur Docker Hub

```bash
docker login
docker push TON-PSEUDO-DOCKERHUB/kpi-api:v1
```

## 4. Remplacer le pseudo dans le manifest

Ouvre `manifests/api-deployment.yaml` et remplace `TON-PSEUDO-DOCKERHUB` par ton vrai pseudo Docker Hub, ligne `image:`.

## 5. Déployer sur le cluster

Connecte-toi au control-plane (ou utilise ton kubeconfig local, voir Jour 2) puis :

```bash
kubectl apply -f manifests/postgres-secret.yaml
kubectl apply -f manifests/postgres-configmap.yaml
kubectl apply -f manifests/postgres-deployment.yaml
kubectl apply -f manifests/postgres-service.yaml

kubectl apply -f manifests/api-configmap.yaml
kubectl apply -f manifests/api-deployment.yaml
kubectl apply -f manifests/kpi-api-service.yaml
```

## 6. Vérifier que tout tourne

```bash
kubectl get pods
# Tu dois voir postgres-deployment-xxx (Running) et 2x kpi-api-deployment-xxx (Running)

kubectl get svc
# Note l'IP publique d'un de tes nœuds (control-plane ou worker) via `terraform output`
```

## 7. Tester l'API depuis l'extérieur

```bash
curl http://<IP_PUBLIQUE_D_UN_NOEUD>:30080/health
# {"status":"ok"}

curl -X POST http://<IP_PUBLIQUE_D_UN_NOEUD>:30080/kpi \
  -H "Content-Type: application/json" \
  -d '{"site_name": "Site-Paris-01", "latency_ms": 25, "throughput_mbps": 120, "packet_loss_percent": 0.2}'

curl http://<IP_PUBLIQUE_D_UN_NOEUD>:30080/kpi

curl http://<IP_PUBLIQUE_D_UN_NOEUD>:30080/kpi/alerts
```

🎉 Si tu vois des résultats JSON, ton application tourne sur ton cluster Kubernetes fait maison.

## Debug si un pod ne démarre pas

```bash
kubectl describe pod <nom-du-pod>     # Voir les événements et erreurs
kubectl logs <nom-du-pod>              # Voir les logs de l'application
```
