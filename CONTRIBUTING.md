# 🤝 Contributing to Monitoring Security Evolution - Level 5

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## 🎯 How to Contribute

### Reporting Issues

1. **Check existing issues** - Search to avoid duplicates
2. **Use issue templates** - Provide all requested information
3. **Be specific** - Include error messages, logs, and environment details

### Suggesting Features

1. Open an issue with the "Feature Request" label
2. Describe the feature and its benefits
3. Provide examples or mockups if applicable

### Code Contributions

#### Before You Start

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/monitoring-security-level5.git`
3. Create a feature branch: `git checkout -b feature/your-feature-name`

#### Development Workflow

1. **Make changes** in your feature branch
2. **Test thoroughly**:
   ```bash
   # Clean environment
   ./scripts/cleanup.sh
   
   # Fresh deployment
   ./setup.sh
   
   # Verify all pods Running
   kubectl get pods -n monitoring
   
   # Check ExternalSecrets synced
   kubectl get externalsecrets -n monitoring
   
   # Test web UIs
   ./scripts/test-urls.sh
   ```

3. **Follow code style**:
   - Use 2 spaces for YAML indentation
   - Use 4 spaces for Bash scripts
   - Add comments for complex logic
   - Use meaningful variable names

4. **Update documentation**:
   - Update README.md if adding new features
   - Add troubleshooting entries if fixing bugs
   - Update docs/ as needed

5. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: Add new feature description"
   ```

#### Commit Message Guidelines

Use conventional commits:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

Examples:
```
feat: Add PostgreSQL support for Zabbix
fix: Resolve MySQL CrashLoopBackOff issue
docs: Update troubleshooting guide
refactor: Improve deploy.sh error handling
```

#### Pull Request Process

1. **Push to your fork**: `git push origin feature/your-feature-name`
2. **Open a Pull Request** on GitHub
3. **Fill out the PR template** completely
4. **Wait for review** - Address any feedback
5. **Ensure CI passes** (if configured)

### Testing Guidelines

#### Minimum Testing Requirements

All contributions MUST pass:

```bash
# 1. Environment check
./scripts/check-environment.sh

# 2. Clean deployment
./scripts/cleanup.sh
./setup.sh

# 3. Validation
kubectl get pods -n monitoring
# All pods must be Running/Completed

kubectl get externalsecrets -n monitoring
# All must show SecretSynced and Ready=True

# 4. Web UI tests
curl -s http://localhost:30300 | grep -q "Grafana" && echo "✅ Grafana OK"
curl -s http://localhost:30080 | grep -q "Zabbix" && echo "✅ Zabbix OK"
curl -s http://localhost:30900 | grep -q "Prometheus" && echo "✅ Prometheus OK"
```

#### What to Test

- **Fresh install** - Clean environment deployment
- **Idempotency** - Run `./setup.sh` twice without errors
- **Recovery** - Test auto-recovery features (e.g., corrupted volumes)
- **Configuration** - Verify Zabbix and Grafana configs apply correctly
- **Web UIs** - Ensure all services are accessible

### Code Quality Standards

#### Bash Scripts

```bash
#!/bin/bash

# Use strict mode
set -e  # Exit on error

# Add descriptive comments
# This function deploys the monitoring stack
deploy_monitoring() {
    echo "📊 Deploying monitoring components..."
    
    # Check prerequisites
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl not found"
        exit 1
    fi
    
    # Deploy with error handling
    kubectl apply -f kubernetes/monitoring/ || {
        echo "❌ Deployment failed"
        return 1
    }
}
```

#### Kubernetes Manifests

```yaml
# Use proper labels
apiVersion: v1
kind: Service
metadata:
  name: monitoring-service
  labels:
    app: monitoring
    component: frontend
    managed-by: monitoring-security-level5
spec:
  # Add comments for non-obvious configurations
  # ClusterIP for internal-only access
  type: ClusterIP
```

#### Documentation

- Use clear headings
- Add code examples
- Include expected outputs
- Provide troubleshooting steps

## 🔒 Security

### Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities.

Instead:
1. Email the maintainers privately
2. Provide detailed description
3. Include reproduction steps
4. Wait for confirmation before disclosure

### Security Best Practices

- Never commit secrets or credentials
- Use Vault for all sensitive data
- Follow principle of least privilege
- Keep dependencies updated

## 📋 Project Structure

```
monitoring-security-level5/
├── scripts/                # Automation scripts
│   ├── deploy.sh          # Main deployment logic
│   ├── cleanup.sh         # Cleanup script
│   └── configure-*.sh     # Configuration scripts
├── kubernetes/            # K8s manifests (numbered for deploy order)
│   ├── 01-namespace/
│   ├── 02-vault/
│   └── ...
├── docs/                  # Documentation
│   ├── guides/           # User guides
│   └── troubleshooting/  # Troubleshooting docs
└── README.md             # Main documentation
```

### Adding New Components

1. Create directory in `kubernetes/` with appropriate number
2. Add deployment logic to `scripts/deploy.sh`
3. Update `README.md` architecture diagram
4. Add configuration script if needed
5. Document in `docs/guides/`

## 🎓 Learning Resources

### Understanding the Stack

- [Vault Documentation](https://www.vaultproject.io/docs)
- [External Secrets Operator](https://external-secrets.io/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Zabbix Documentation](https://www.zabbix.com/documentation/current/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

### Development Environment

Recommended tools:
- VS Code with YAML and Kubernetes extensions
- kubectl with auto-completion
- k9s for cluster management
- Docker Desktop or Podman

## ❓ Questions?

- Open a discussion on GitHub
- Check existing issues and PRs
- Review documentation in `docs/`

## 🌟 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in relevant documentation

---

Thank you for contributing! 🙏

Every contribution, no matter how small, helps improve this project for everyone.
