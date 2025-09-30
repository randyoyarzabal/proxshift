# ProxShift Prerequisites

Essential requirements for running ProxShift successfully.

## 🐍 Python Environment (Required)

### Virtual Environment Setup

**Recommended approach** to avoid "pip externally managed" errors:

```bash
cd /path/to/proxshift

# Create virtual environment
python3 -m venv .venv

# Activate and install dependencies
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# Install Ansible collections
ansible-galaxy collection install -r collections/requirements.yml
```

### Automatic Activation

ProxShift automatically activates the virtual environment:

```bash
# Simply source proxshift.sh
source proxshift.sh
# 🔧 Activating ProxShift virtual environment...
# ✅ Virtual environment activated: Python 3.13.7
```

## 💻 System Packages

### macOS (Homebrew)

```bash
# Install Python (if not already installed)
brew install python3

# NFS and SMB support are built into macOS
# No additional packages needed!
```

### Linux (Ubuntu/Debian)

```bash
# Install system packages
sudo apt update
sudo apt install python3 python3-venv python3-pip
sudo apt install nfs-common cifs-utils

# Git (usually pre-installed)
sudo apt install git
```

### Linux (RHEL/CentOS/Fedora)

```bash
# Install system packages
sudo dnf install python3 python3-pip
sudo dnf install nfs-utils cifs-utils

# Git (usually pre-installed)
sudo dnf install git
```

## 🔧 OpenShift Tools

### Download OpenShift Installer

```bash
# Create tools directory
mkdir -p ~/bin

# Download latest OpenShift installer (update version as needed)
OCP_VERSION="4.17.1"
curl -L "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux.tar.gz" | tar -xz -C ~/bin/

# Download OpenShift CLI
curl -L "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux.tar.gz" | tar -xz -C ~/bin/

# Make executable and add to PATH
chmod +x ~/bin/{openshift-install,oc}
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
openshift-install version
oc version --client
```

## 🏗️ Infrastructure Requirements

### Proxmox VE

- **Version**: 7.0 or higher
- **API Access**: User with VM management permissions
- **Network**: VLAN configuration for cluster isolation
- **Storage**: Sufficient space for VM disks and ISOs

### HashiCorp Vault

- **Version**: Any recent version
- **KV Secrets Engine**: v2 enabled
- **Authentication**: Token or other auth method
- **Network Access**: Reachable from ProxShift execution environment

### Network Infrastructure

- **DNS**: Internal DNS server or external DNS with A records
- **IP Allocation**: Static IP addresses for cluster nodes
- **Firewall**: Appropriate ports open for OpenShift
- **Load Balancer**: For multi-node clusters (external or integrated)

## 🔐 Access Requirements

### Required Permissions

| Service | Permissions | Purpose |
|---------|-------------|---------|
| **Proxmox** | VM.Allocate, VM.Config, VM.Monitor | Create and manage VMs |
| **Vault** | KV read/write | Store and retrieve secrets |
| **DNS** | A record creation | Cluster name resolution |
| **Network** | Static IP assignment | Node connectivity |

### API Credentials

```bash
# Proxmox API User (create in Proxmox UI)
# Path: Datacenter → Permissions → Users
# Permissions: VM.*, Datastore.Allocate

# Vault Token (create via vault CLI)
vault auth
vault token create -policy=proxshift-policy

# Store in environment or config files
export VAULT_TOKEN="your-vault-token"
export VAULT_ADDR="https://vault.example.com:8200"
```

## ✅ Verification Checklist

### Environment Check

```bash
# Python virtual environment
source .venv/bin/activate
python --version          # Should show Python 3.8+
pip list | grep ansible    # Should show ansible-core

# OpenShift tools
openshift-install version  # Should show 4.16+
oc version --client        # Should show 4.16+

# Network tools (Linux only)
mount.nfs --help          # Should show NFS mount options
mount.cifs --help         # Should show CIFS mount options
```

### ProxShift Environment

```bash
# Load ProxShift
source proxshift.sh        # Should auto-activate venv

# Test functions
ps.clusters               # Should list available clusters
ansible --version         # Should show Ansible from venv

# Test collections
ansible-galaxy collection list | grep -E "(community|kubernetes|proxshift)"
```

### Connectivity Check

```bash
# Vault connectivity
vault status              # Should show vault status
vault kv list secret/     # Should show secrets (if accessible)

# Proxmox connectivity
curl -k "https://proxmox.example.com:8006/api2/json/version"

# DNS resolution
nslookup api.cluster.example.com
ping cluster-node.example.com
```

## 🐛 Common Issues

### "pip externally managed" Error

**Solution**: Use virtual environment (already covered above)

```bash
# Don't use system pip
pip install something     # ❌ Fails on modern systems

# Use virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install something     # ✅ Works in venv
```

### Ansible Collection Not Found

**Solution**: Install collections in virtual environment

```bash
source .venv/bin/activate
ansible-galaxy collection install -r collections/requirements.yml --force
```

### Mount Permission Denied

**Solution**: Ensure user has access to mount operations

```bash
# For NFS/SMB mounts, ensure the user can write to mount points
ls -la .tmpmount/         # Should be writable by user

# Check network share permissions
# SMB: User must have read/write access to share
# NFS: Export must allow user access
```

## 📋 Pre-Installation Summary

Before running ProxShift, ensure you have:

- ✅ **Python 3.8+** with virtual environment support
- ✅ **Virtual environment** created and activated
- ✅ **All Python dependencies** installed via pip
- ✅ **OpenShift tools** downloaded and in PATH
- ✅ **System packages** for NFS/SMB mounting
- ✅ **Proxmox API access** with VM permissions
- ✅ **Vault access** with KV secrets
- ✅ **Network connectivity** to all required services
- ✅ **DNS resolution** for cluster domains

Once all prerequisites are met, proceed to the [Setup Guide](setup.md) for configuration and first cluster deployment.

---

**ProxShift** - Production-ready OpenShift on Proxmox ⚡
