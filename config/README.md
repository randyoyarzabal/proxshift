# 📋 ProxShift Configuration Directory

This directory contains **user-specific configuration files** that must be created before using ProxShift.

## 🚨 Important Notes

- **These files are excluded from git** (see `.gitignore`)
- **Copy templates and customize** for your environment
- **Never commit sensitive information**

## 📁 Required Files

### 1. `site-config.yaml`

**Your homelab-specific settings**
```bash
cp ../examples/site-config.yaml site-config.yaml
# Edit with your paths, domain, network settings
```

### 2. `vault-credentials.yml`

**HashiCorp Vault connection details**
```bash
cp ../examples/vault-credentials.yml vault-credentials.yml
# Add your vault server and token
```

## 🎯 Quick Setup

```bash
# Copy templates
cd config/
cp ../examples/site-config.yaml site-config.yaml
cp ../examples/vault-credentials.yml vault-credentials.yml

# Edit with your specific settings
vim site-config.yaml      # Update network, paths, domain
vim vault-credentials.yml # Add vault server and token
```

## ✅ Validation

Run this to verify your configuration:
```bash
# Test template generation (safe, no provisioning)
ocp.generate_manifests ocp-sno1 --dry-run
```
