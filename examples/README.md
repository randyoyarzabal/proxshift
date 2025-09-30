# ProxShift Configuration Templates

This directory contains **template files** for users to copy and customize for their environment.

## 📋 Setup Process

1. **Copy templates to your config directory:**
   ```bash
   # From your ProxShift root directory
   mkdir -p config inventory
   
   # Copy site configuration
   cp examples/site-config.yaml config/site-config.yaml
   
   # Copy vault credentials  
   cp examples/vault-credentials.yml config/vault-credentials.yml
   
   # Copy inventory template
   cp examples/clusters.yml.template inventory/clusters.yml
   ```

2. **Customize for your environment:**
   ```bash
   # Edit site settings (paths, network, etc.)
   vim config/site-config.yaml
   
   # Edit your vault server and token
   vim config/vault-credentials.yml 
   
   # Encrypt the vault credentials file (IMPORTANT!)
   ansible-vault encrypt config/vault-credentials.yml
   
   # Define your clusters and network
   vim inventory/clusters.yml
   ```

## 🔒 Security Note

Your actual configuration files (`config/` and `inventory/`) are **gitignored** and will never be committed to your repository. Only these sanitized templates are tracked by git.

**Important**: Always encrypt your vault credentials:
```bash
# Create vault password file
echo "your-secure-password" > config/.vault_pass

# Encrypt the vault credentials
ansible-vault encrypt config/vault-credentials.yml --vault-password-file config/.vault_pass
```

ProxShift will automatically decrypt this file at runtime using `config/.vault_pass`.

## 📁 Template Files

- **`site-config.yaml`** - Global ProxShift settings
- **`vault-credentials.yml`** - HashiCorp Vault connection
- **`clusters.yml.template`** - Cluster definitions and network layout
- **`README.md`** - This file

## 🚀 Quick Start

After copying templates:

```bash
export PROXSHIFT_ROOT="/path/to/proxshift"
source proxshift.sh
ps.provision ocp-sno1
```