# ☁️ Guia de Deploy Multi-Cloud

## 📋 Resumo Executivo

Este projeto **JÁ ESTÁ PRONTO** para deploy em AWS, Azure e GCP!

**O que funciona sem alteração (95% do projeto):**
- ✅ Todos os manifestos Kubernetes
- ✅ HashiCorp Vault
- ✅ External Secrets Operator
- ✅ Zabbix, Prometheus, Grafana
- ✅ MySQL StatefulSet

**O que precisa adaptar:**
- 🔄 Storage Class (1 arquivo por cloud - **já incluído**)
- 🔄 Service type (NodePort → LoadBalancer - opcional)

---

## 🎯 Compatibilidade

| Componente | Kind Local | AWS EKS | Azure AKS | GCP GKE |
|------------|------------|---------|-----------|---------|
| Vault | ✅ | ✅ | ✅ | ✅ |
| External Secrets | ✅ | ✅ | ✅ | ✅ |
| MySQL | ✅ | ✅ | ✅ | ✅ |
| Zabbix | ✅ | ✅ | ✅ | ✅ |
| Prometheus | ✅ | ✅ | ✅ | ✅ |
| Grafana | ✅ | ✅ | ✅ | ✅ |

---
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/manifests/external-secrets.yaml
```

5. **Deploy Monitoring Stack**
```bash
kubectl apply -f kubernetes/01-namespace/
kubectl apply -f kubernetes/02-vault/
kubectl wait --for=condition=Ready pod -l app=vault -n monitoring --timeout=120s

kubectl apply -f kubernetes/02-vault/vault-init-job.yaml
kubectl wait --for=condition=complete job/vault-init -n monitoring --timeout=180s

kubectl apply -f kubernetes/03-external-secrets/
sleep 10

kubectl apply -f kubernetes/05-mysql/
kubectl apply -f kubernetes/06-zabbix/
kubectl apply -f kubernetes/07-prometheus/
kubectl apply -f kubernetes/08-grafana/
kubectl apply -f kubernetes/09-node-exporter/
```

6. **Create LoadBalancer Services** (optional)
```bash
# Expose Zabbix Web
kubectl expose deployment zabbix-web -n monitoring \
  --type=LoadBalancer \
  --name=zabbix-web-lb \
  --port=80 \
  --target-port=8080

# Expose Grafana
kubectl expose deployment grafana -n monitoring \
  --type=LoadBalancer \
  --name=grafana-lb \
  --port=80 \
  --target-port=3000

# Get LoadBalancer URLs
kubectl get svc -n monitoring | grep LoadBalancer
```

---

## 📗 GCP GKE Deployment

### Prerequisites
- gcloud CLI configured
- kubectl installed

### Step-by-Step

1. **Create GKE Cluster**
```bash
gcloud container clusters create monitoring-cluster \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type n1-standard-2 \
  --disk-size 50 \
  --enable-autoscaling \
  --min-nodes 2 \
  --max-nodes 5
```

2. **Get Cluster Credentials**
```bash
gcloud container clusters get-credentials monitoring-cluster --zone us-central1-a
```

3. **Apply Storage Class**
```bash
kubectl apply -f kubernetes/04-storage/gcp/storage-class.yaml
```

4. **Install External Secrets Operator**
```bash
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/manifests/external-secrets.yaml
```

5. **Deploy Monitoring Stack** (same as EKS)

---

## 📙 Azure AKS Deployment

### Prerequisites
- Azure CLI configured
- kubectl installed

### Step-by-Step

1. **Create Resource Group**
```bash
az group create --name monitoring-rg --location eastus
```

2. **Create AKS Cluster**
```bash
az aks create \
  --resource-group monitoring-rg \
  --name monitoring-cluster \
  --node-count 3 \
  --node-vm-size Standard_DS2_v2 \
  --enable-managed-identity \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 5
```

3. **Get Cluster Credentials**
```bash
az aks get-credentials --resource-group monitoring-rg --name monitoring-cluster
```

4. **Apply Storage Class**
```bash
kubectl apply -f kubernetes/04-storage/azure/storage-class.yaml
```

5. **Install External Secrets Operator**
```bash
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/manifests/external-secrets.yaml
```

6. **Deploy Monitoring Stack** (same as EKS)

---

## 🔧 Common Post-Deployment Steps

### Configure Ingress (Optional)

For production, use Ingress instead of NodePort:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: monitoring
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - zabbix.example.com
    - grafana.example.com
    - prometheus.example.com
    secretName: monitoring-tls
  rules:
  - host: zabbix.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: zabbix-web
            port:
              number: 8080
  - host: grafana.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
  - host: prometheus.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus
            port:
              number: 9090
```

### Configure Vault for Production

1. **Use Production Mode** (instead of dev mode)
2. **Enable TLS**
3. **Configure Auto-Unseal** (AWS KMS, GCP KMS, Azure Key Vault)
4. **Setup Backup Strategy**
5. **Enable Audit Logging**

---

## 💰 Cost Optimization

### AWS EKS
- Use Spot Instances for worker nodes
- Enable Cluster Autoscaler
- Use Fargate for stateless workloads

### GCP GKE
- Use Preemptible VMs
- Enable Node Auto-Provisioning
- Use GKE Autopilot mode

### Azure AKS
- Use Spot VMs
- Enable Cluster Autoscaler
- Use Azure Container Instances for burst workloads

---

## 🔒 Security Hardening

1. **Enable Pod Security Standards**
2. **Configure Network Policies**
3. **Use Private Clusters**
4. **Enable Encryption at Rest**
5. **Configure IAM Roles for Service Accounts**
6. **Enable Audit Logging**
7. **Use Secrets Encryption in etcd**

---

## 📊 Monitoring & Alerting

Configure CloudWatch (AWS), Cloud Monitoring (GCP), or Azure Monitor for:
- Cluster health
- Pod metrics
- Storage usage
- Network traffic
- Cost tracking
