# 🔐 Monitoring Security Evolution - Level 5

**Complete Kubernetes monitoring stack with HashiCorp Vault and External Secrets Operator**

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.34-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![Vault](https://img.shields.io/badge/Vault-Dev%20Mode-000000?logo=vault)](https://www.vaultproject.io/)
[![Zabbix](https://img.shields.io/badge/Zabbix-7.0-D40000?logo=zabbix)](https://www.zabbix.com/)
[![Prometheus](https://img.shields.io/badge/Prometheus-Latest-E6522C?logo=prometheus)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-Latest-F46800?logo=grafana)](https://grafana.com/)

## 📋 Overview

This project demonstrates a **production-ready monitoring infrastructure** deployed on Kubernetes with:

- 🔐 **Centralized Secret Management** using HashiCorp Vault
- 🔄 **Automatic Secret Synchronization** via External Secrets Operator
- 📊 **Comprehensive Monitoring** with Zabbix, Prometheus, and Grafana
- 🚀 **One-command Deployment** with automated setup scripts
- ✅ **Full Automation** including configuration of dashboards and templates

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kubernetes Cluster                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   Monitoring Namespace                │  │
│  │                                                       │  │
│  │  ┌──────────┐    ┌─────────────────┐                │  │
│  │  │  Vault   │◄───┤ External Secrets│                │  │
│  │  │  (KV v2) │    │    Operator     │                │  │
│  │  └──────────┘    └────────┬────────┘                │  │
│  │       │                   │                          │  │
│  │       │          ┌────────▼──────────┐              │  │
│  │       │          │ Kubernetes Secrets│              │  │
│  │       │          └────────┬──────────┘              │  │
│  │       │                   │                          │  │
│  │  ┌────▼────┐    ┌─────────▼────────┐    ┌────────┐ │  │
│  │  │  MySQL  │◄───┤  Zabbix Server   │───►│Zabbix  │ │  │
│  │  │   8.3   │    │  + Web + Agent2  │    │ Web UI │ │  │
│  │  └─────────┘    └──────────────────┘    └────────┘ │  │
│  │                                                      │  │
│  │  ┌────────────┐    ┌──────────────┐    ┌────────┐  │  │
│  │  │ Prometheus │◄───┤ Node Exporter│───►│Grafana │  │  │
│  │  │            │    │              │    │   UI   │  │  │
│  │  └────────────┘    └──────────────┘    └────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## ✨ Features

### Security
- ✅ **Zero hardcoded secrets** - All credentials managed by Vault
- ✅ **Automatic rotation ready** - External Secrets sync every hour
- ✅ **Encrypted storage** - Vault KV v2 engine
- ✅ **Least privilege** - ServiceAccounts with minimal permissions

### Monitoring
- ✅ **Zabbix 7.0** - Agent-based monitoring with active checks
- ✅ **Prometheus** - Metrics collection from Kubernetes nodes
- ✅ **Grafana** - Unified dashboards for both Zabbix and Prometheus
- ✅ **Node Exporter** - System-level metrics (CPU, Memory, Disk, Network)

### Automation
- ✅ **One-command deployment** - `./setup.sh` deploys everything
- ✅ **Idempotent scripts** - Can be run multiple times safely
- ✅ **Auto-recovery** - Detects and fixes common issues (corrupted volumes, sync errors)
- ✅ **Pre-flight checks** - Validates environment before deployment

## 🚀 Quick Start

### Prerequisites

- **Docker** - Running and accessible
- **kind** v0.30.0+
- **kubectl** v1.28+
- **helm** v3.0+
- **Minimum Resources**: 4GB RAM, 2 CPU cores, 10GB disk

### Installation

```bash
# 1. Clone the repository
git clone <your-repo-url>
cd monitoring-security-level5

# 2. Run pre-flight checks
./scripts/check-environment.sh

# 3. Deploy everything (15-20 minutes)
./setup.sh
```

### Access Services

Once deployment completes:

```bash
# View credentials
./scripts/show-credentials.sh
```

**Services:**

| Service | URL | Default User | Password |
|---------|-----|--------------|----------|
| Grafana | http://localhost:30300 | admin | (from Vault) |
| Zabbix | http://localhost:30080 | Admin | (from Vault) |
| Prometheus | http://localhost:30900 | - | - |

**Get passwords:**

```bash
# Grafana
kubectl get secret grafana-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d

# Zabbix
kubectl get secret zabbix-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d
```

## 📁 Project Structure

```
monitoring-security-level5/
├── README.md                    # This file
├── setup.sh                     # Main deployment script
├── kind-config.yaml            # Kind cluster configuration
│
├── scripts/                     # Automation scripts
│   ├── cleanup.sh              # Complete cleanup
│   ├── deploy.sh               # Infrastructure deployment
│   ├── check-environment.sh    # Pre-flight validation
│   ├── configure-zabbix.sh     # Zabbix templates setup
│   ├── configure-grafana.sh    # Grafana dashboards import
│   └── show-credentials.sh     # Display access credentials
│
├── kubernetes/                  # Kubernetes manifests
│   ├── 01-namespace/           # Namespace definition
│   ├── 02-vault/               # Vault StatefulSet + init job
│   ├── 03-external-secrets/    # ESO SecretStore + ExternalSecrets
│   ├── 04-storage/             # StorageClass for Kind
│   ├── 05-mysql/               # MySQL 8.3 + schema init
│   ├── 06-zabbix/              # Zabbix server, web, agent2
│   ├── 07-prometheus/          # Prometheus + RBAC
│   ├── 08-grafana/             # Grafana + datasources
│   └── 09-node-exporter/       # Node Exporter DaemonSet
│
├── grafana/                     # Grafana assets
│   └── dashboards/             # JSON dashboard definitions
│
└── docs/                        # Documentation
    ├── guides/                  # Setup and usage guides
    └── troubleshooting/         # Common issues and solutions
```

## 🔧 Configuration

### Vault Secrets

All secrets are automatically created during deployment in Vault at:

```
secret/mysql       - MySQL root password and database
secret/zabbix      - Zabbix admin password and DB credentials
secret/grafana     - Grafana admin credentials
secret/prometheus  - Prometheus configuration
```

### External Secrets

The External Secrets Operator automatically syncs secrets from Vault to Kubernetes:

```bash
# Check sync status
kubectl get externalsecrets -n monitoring

# Should show all with STATUS=SecretSynced, READY=True
```

### Zabbix Configuration

Automatically configured by `scripts/configure-zabbix.sh`:

- ✅ Template: "Linux by Zabbix agent active"
- ✅ Host: "Zabbix server"
- ✅ Interface: DNS (zabbix-agent2-service:10050)
- ✅ Admin password changed to Vault value

### Grafana Configuration

Automatically configured by `scripts/configure-grafana.sh`:

- ✅ Datasources: Prometheus + Zabbix
- ✅ Dashboards: Node Exporter + Zabbix Overview
- ✅ All using Vault credentials

## 🛠️ Troubleshooting

### External Secrets Not Syncing

```bash
# Restart ESO to clear cache
kubectl rollout restart deployment/external-secrets -n external-secrets-system

# Wait 30 seconds
sleep 30

# Verify sync
kubectl get externalsecrets -n monitoring
```

### MySQL CrashLoopBackOff

The deployment script automatically detects and fixes corrupted volumes. If you encounter this manually:

```bash
# Delete StatefulSet and PVC
kubectl delete statefulset mysql -n monitoring
kubectl delete pvc mysql-data-mysql-0 -n monitoring

# Reapply
kubectl apply -f kubernetes/05-mysql/mysql-statefulset.yaml
```

### Complete Reset

```bash
# Clean everything
./scripts/cleanup.sh

# Redeploy
./setup.sh
```

For more troubleshooting tips, see [docs/troubleshooting/](docs/troubleshooting/)

## 📊 Validation

```bash
# 1. Check all pods are Running
kubectl get pods -n monitoring

# Expected: 10-11 pods Running/Completed

# 2. Verify External Secrets synced
kubectl get externalsecrets -n monitoring

# Expected: 4/4 with SecretSynced status

# 3. Test web UIs
curl -s http://localhost:30300 > /dev/null && echo "✅ Grafana OK"
curl -s http://localhost:30080 > /dev/null && echo "✅ Zabbix OK"
curl -s http://localhost:30900 > /dev/null && echo "✅ Prometheus OK"
```

## 🎯 Use Cases

- **Learning Environment** - Understand Kubernetes secret management
- **Development** - Test applications with production-like monitoring
- **Proof of Concept** - Demonstrate Vault + K8s integration
- **Training** - Teach DevOps best practices

## ⚠️ Important Notes

### Security

- ⚠️ **Development Mode Only** - Vault runs in dev mode (NOT for production)
- ⚠️ **Root Token** - Uses fixed token `vault-dev-root-token`
- ⚠️ **No TLS** - All communication is unencrypted
- ⚠️ **No High Availability** - Single instance of each component

### Production Readiness

To use in production, you MUST:

1. Deploy Vault in production mode with proper unsealing
2. Enable TLS/SSL for all services
3. Use proper authentication (OIDC, LDAP, etc.)
4. Implement backup strategies
5. Configure high availability
6. Use real certificates (Let's Encrypt, internal CA)
7. Implement network policies
8. Configure resource limits

## 📚 Documentation

- [Quick Start Guide](docs/guides/GUIA-RAPIDO.md) - Essential commands
- [Clean Install Testing](docs/guides/TESTE-CLEAN-INSTALL.md) - Full test procedure
- [Deployment Checklist](docs/guides/CHECKLIST-DEPLOYMENT.md) - Step-by-step validation
- [Troubleshooting Guide](docs/troubleshooting/VALIDACAO-DEPLOY.md) - Common issues

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly (run `./scripts/cleanup.sh && ./setup.sh`)
5. Submit a pull request

## 📝 License

This project is provided as-is for educational purposes.

## 🙏 Acknowledgments

- **HashiCorp Vault** - Secret management
- **External Secrets Operator** - Kubernetes integration
- **Zabbix** - Monitoring platform
- **Prometheus** - Metrics collection
- **Grafana** - Visualization
- **Kind** - Kubernetes in Docker

## 📧 Support

For issues and questions:

- Open an issue on GitHub
- Check the [troubleshooting guide](docs/troubleshooting/)
- Review the [deployment logs](docs/guides/)

---

**⭐ If this project helped you, please give it a star!**

Built with ❤️ for the Kubernetes community
