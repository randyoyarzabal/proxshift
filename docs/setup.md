# ProxShift Setup Guide

Complete installation and configuration guide for ProxShift.

## Prerequisites

### Required Software

| Component | Version | Purpose | Notes |
|-----------|---------|---------|-------|
| **Python** | 3.8+ | Ansible runtime | Virtual environment recommended |
| **Ansible** | 2.15+ | Automation engine | Installed via pip in venv |
| **Git** | Any recent | Repository management | System package |
| **OpenShift CLI** | 4.16+ | Cluster management | Binary download |

### Required Infrastructure

| Service | Requirement | Purpose |
|---------|-------------|---------|
| **Proxmox VE** | 7.0+ | Virtual machine hosting |
| **HashiCorp Vault** | Any version | Secret management |
| **DNS Server** | Internal/External | Cluster name resolution |
| **Network** | Static IPs available | Cluster networking |

### Access Requirements

- **Proxmox API access** with VM management permissions
- **Vault access** with KV secrets engine enabled
- **Network access** to OpenShift image registries
- **SSH access** to Proxmox nodes (for troubleshooting)

## Installation

### Step 1: Clone Repository

```bash
# Clone ProxShift
git clone https://github.com/randyoyarzabal/proxshift.git
cd proxshift

# Set environment variable
export PROXSHIFT_ROOT="$(pwd)"
echo 'export PROXSHIFT_ROOT="/path/to/proxshift"' >> ~/.bashrc
```

### Step 2: Setup Python Virtual Environment

**Recommended approach to avoid "pip externally managed" errors:**

```bash
cd $PROXSHIFT_ROOT

# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install Python dependencies
pip install -r requirements.txt

# Install Ansible collections
ansible-galaxy collection install -r collections/requirements.yml

# Verify installation
ansible --version
ansible-galaxy collection list | grep -E "(community|kubernetes|proxshift)"
```

### Step 2a: Environment Setup

ProxShift requires environment variables and manual activation:

```bash
# Set required environment variables (examples only - adjust paths)
export PROXSHIFT_ROOT=$HOME/dev/proxshift
export PROXSHIFT_VAULT_PASS=${PROXSHIFT_ROOT}/config/.vault_pass

# Load ProxShift functions
source proxshift.sh

# Activate environment (this replaces old automatic activation)
ps.activate
# Activating ProxShift environment...
# ✓ Virtual environment activated: Python 3.13.7
# ✓ Ansible available: ansible [core 2.19.2]

# All ProxShift functions are now available
ps.clusters
ps.provision --help
```

**Note**: If `PROXSHIFT_VAULT_PASS` is not defined or the file doesn't exist, Ansible will prompt for the vault password interactively during playbook execution.

### Step 3: Install OpenShift Tools

#### OpenShift Installer Binary Naming Convention

**Important**: ProxShift expects OpenShift installer binaries to be named with version suffixes and automatically creates symlinks for the Ansible process.

**Required naming format**:

```text
openshift-install-{VERSION}
```

**Examples**:

- `openshift-install-4.17.1`
- `openshift-install-4.16.5`
- `openshift-install-4.15.12`

#### Download OpenShift Installer

```bash
# Create tools directory
mkdir -p ~/bin

# Download latest OpenShift installer (example for 4.17.1)
OCP_VERSION="4.17.1"
curl -L "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux.tar.gz" | tar -xz -C ~/bin/

# Rename to versioned format (REQUIRED)
mv ~/bin/openshift-install ~/bin/openshift-install-${OCP_VERSION}

# Download OpenShift CLI
curl -L "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux.tar.gz" | tar -xz -C ~/bin/

# Make executable and add to PATH
chmod +x ~/bin/{openshift-install-${OCP_VERSION},oc}
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
~/bin/openshift-install-${OCP_VERSION} version
oc version --client
```

#### How ProxShift Uses Versioned Binaries

ProxShift automatically:

1. **Detects the required version** from your cluster inventory (`ocp_version` field)
2. **Looks for the versioned binary** at `{ocp_installer_path}/openshift-install-{version}`
3. **Creates a symlink** from `openshift-install-{version}` → `openshift-install`
4. **Uses the symlinked binary** for all Ansible operations

**Example workflow**:

```bash
# Your inventory specifies: ocp_version: "4.17.1"
# ProxShift looks for: /Users/royarzab/bin/openshift-install-4.17.1
# ProxShift creates: /Users/royarzab/bin/openshift-install -> openshift-install-4.17.1
# Ansible uses: openshift-install (the symlink)
```

**Multiple versions support**:

```bash
# You can have multiple versions installed simultaneously
~/bin/openshift-install-4.16.5
~/bin/openshift-install-4.17.1
~/bin/openshift-install-4.18.0

# ProxShift will symlink the correct version based on cluster configuration
```

## Configuration

### Step 1: Copy Configuration Templates

```bash
cd $PROXSHIFT_ROOT
cp examples/site-config.yaml config/site-config.yaml
cp examples/vault-credentials.yml config/vault-credentials.yml
cp examples/clusters.yml.template inventory/clusters.yml
```

### Step 2: Configure Site Settings

Edit `config/site-config.yaml`:

```yaml
# Network configuration
network_defaults:
  base_domain: "homelab.local"              # Your DNS domain
  subnet: "192.168.1.0/24"                  # Cluster subnet
  gateway: "192.168.1.1"                    # Network gateway
  dns_servers:                              # DNS servers
    - "192.168.1.1"
    - "8.8.8.8"
  interface_name: "eno1"                     # Network interface
  cluster_cidr: "10.128.0.0/14"            # Pod network
  service_cidr: "172.30.0.0/16"            # Service network

# OpenShift installer binary location
ocp_installer_path: "/usr/local/bin"        # Path where versioned binaries are stored

# Proxmox configuration
proxmox_api_user: "api-user@pve"            # Proxmox API user
proxmox_api_password: "{{ vault_proxmox_password }}"  # From vault

# Hub cluster for ACM
hub_cluster: "ocp"                          # Hub cluster name
hub_cluster_api_url: "https://api.ocp.homelab.local:6443"

# Backup settings
backup_dir: "/tmp/proxshift-backups"
backup_secrets:
  - name: "homelab-ca-tls"
    namespace: "cert-manager"
  - name: "homelab-io-tls"
    namespace: "istio-system"
```

### Step 3: Configure Vault Credentials

Edit `config/vault-credentials.yml`:

```yaml
# HashiCorp Vault configuration
vault_addr: "https://vault.homelab.local:8200"
vault_token: "{{ lookup('env', 'VAULT_TOKEN') }}"  # Use environment variable
vault_path: "secret/data/openshift/clusters"

# Define secrets to retrieve
vault_items:
  - name: "pull-secret"
    path: "secret/data/openshift/registry"
    key: "pull_secret"
  - name: "ssh-key"
    path: "secret/data/openshift/access"
    key: "public_key"
  - name: "cert-bundle"
    path: "secret/data/certificates"
    key: "ca_bundle"

# Proxmox credentials (stored in vault)
vault_proxmox_password: "{{ lookup('community.hashi_vault.vault_read', 'secret/data/proxmox/api', 'password') }}"
```

### Step 4: Define Your Clusters

Edit `inventory/clusters.yml`:

```yaml
# Single Node OpenShift
ocp-sno1:
  hosts:
    ocp-sno1-master:
      ip: 192.168.1.100
      mac: "00:50:56:12:34:56"
      role: master
      vmid: 100
      memory: 16384
      cores: 4
      node: pve-node1
      ocp_version: "4.17.1"

# Compact 3-node cluster
ocp3:
  hosts:
    ocp3-master-1:
      ip: 192.168.1.110
      mac: "00:50:56:11:11:11"
      role: master
      vmid: 110
      memory: 16384
      cores: 4
      node: pve-node1
      ocp_version: "4.17.1"
    ocp3-master-2:
      ip: 192.168.1.111
      mac: "00:50:56:11:11:12"
      role: master
      vmid: 111
      memory: 16384
      cores: 4
      node: pve-node2
      ocp_version: "4.17.1"
    ocp3-master-3:
      ip: 192.168.1.112
      mac: "00:50:56:11:11:13"
      role: master
      vmid: 112
      memory: 16384
      cores: 4
      node: pve-node3
      ocp_version: "4.17.1"

# Full production cluster
ocp:
  hosts:
    # Masters
    ocp-master-1:
      ip: 192.168.1.120
      mac: "00:50:56:10:10:11"
      role: master
      vmid: 120
      memory: 16384
      cores: 4
      node: pve-node1
      ocp_version: "4.17.1"
    ocp-master-2:
      ip: 192.168.1.121
      mac: "00:50:56:10:10:12"
      role: master
      vmid: 121
      memory: 16384
      cores: 4
      node: pve-node2
      ocp_version: "4.17.1"
    ocp-master-3:
      ip: 192.168.1.122
      mac: "00:50:56:10:10:13"
      role: master
      vmid: 122
      memory: 16384
      cores: 4
      node: pve-node3
      ocp_version: "4.17.1"
    # Workers
    ocp-worker-1:
      ip: 192.168.1.130
      mac: "00:50:56:20:20:21"
      role: worker
      vmid: 130
      memory: 32768
      cores: 8
      node: pve-node1
      ocp_version: "4.17.1"
    ocp-worker-2:
      ip: 192.168.1.131
      mac: "00:50:56:20:20:22"
      role: worker
      vmid: 131
      memory: 32768
      cores: 8
      node: pve-node2
      ocp_version: "4.17.1"
    ocp-worker-3:
      ip: 192.168.1.132
      mac: "00:50:56:20:20:23"
      role: worker
      vmid: 132
      memory: 32768
      cores: 8
      node: pve-node3
      ocp_version: "4.17.1"
```

## Vault Setup

### Create Required Secrets

```bash
# Set Vault environment
export VAULT_ADDR="https://vault.homelab.local:8200"
export VAULT_TOKEN="your-vault-token"

# Store OpenShift pull secret
vault kv put secret/openshift/registry \
  pull_secret='{"auths":{"your-registry":{"auth":"base64-token"}}}'

# Store SSH public key
vault kv put secret/openshift/access \
  public_key="ssh-rsa AAAAB3... your-key@example.com"

# Store Proxmox credentials
vault kv put secret/proxmox/api \
  password="your-proxmox-password"

# Store CA bundle (if needed)
vault kv put secret/certificates \
  ca_bundle="-----BEGIN CERTIFICATE-----..."
```

## Verification

### Test Configuration

```bash
# Load ProxShift environment (auto-activates venv)
source proxshift.sh

# List available clusters
ps.clusters

# Test dry run
ps.provision ocp-sno1 --dry-run

# Generate templates only
ps.generate_manifests ocp-sno1
```

### Validate Prerequisites

```bash
# Check Ansible collections
ansible-galaxy collection list | grep proxshift

# Check OpenShift tools
openshift-install version
oc version --client

# Test Vault access
vault kv get secret/openshift/registry

# Test Proxmox API (replace with your details)
curl -k -X GET "https://proxmox.example.com:8006/api2/json/version" \
  -H "Authorization: PVEAPIToken=api-user@pve!token-id=token-secret"
```

## First Cluster

### Provision Single Node OpenShift

```bash
# Load environment (auto-activates venv)
cd /path/to/proxshift
source proxshift.sh

# Preview before provisioning
ps.provision ocp-sno1 --dry-run

# Provision the cluster
ps.provision ocp-sno1

# Monitor progress
tail -f ocp_install/ocp-sno1/.openshift_install.log
```

### Post-Installation

```bash
# Check cluster status
export KUBECONFIG=$PROXSHIFT_ROOT/ocp_install/ocp-sno1/auth/kubeconfig
oc get nodes
oc get clusterversion

# Access web console
oc whoami --show-console

# Get kubeadmin password
cat ocp_install/ocp-sno1/auth/kubeadmin-password
```

## Troubleshooting

### Common Issues

#### Ansible Collection Not Found

```bash
# Ensure virtual environment is activated
source .venv/bin/activate

# Reinstall collections
ansible-galaxy collection install -r collections/requirements.yml --force
```

#### Virtual Environment Issues

```bash
# If virtual environment is missing
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# If pip externally managed error
# Use virtual environment instead of system pip
deactivate  # Exit any current venv
rm -rf .venv  # Remove broken venv
python3 -m venv .venv  # Recreate
source .venv/bin/activate
pip install -r requirements.txt
```

#### Vault Connection Failed

```bash
# Check Vault status
vault status
export VAULT_SKIP_VERIFY=true  # For self-signed certificates
```

#### Proxmox API Errors

```bash
# Test API access
curl -k "https://your-proxmox:8006/api2/json/version"

# Check user permissions in Proxmox UI
# Ensure API user has VM.* permissions
```

#### OpenShift Installation Stuck

```bash
# Monitor installation logs
tail -f ocp_install/cluster-name/.openshift_install.log

# Check VM console in Proxmox
# Verify network connectivity from VMs
```

#### OpenShift Installer Binary Issues

**Error**: `refusing to convert from file to symlink for /path/to/openshift-install`

**Cause**: A file named `openshift-install` already exists instead of the expected versioned binary.

**Solution**:

```bash
# Check what's at the installer path
ls -la ~/bin/openshift-install*

# If you have a file instead of versioned binaries:
rm ~/bin/openshift-install  # Remove the file

# Download and rename properly
OCP_VERSION="4.17.1"
curl -L "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux.tar.gz" | tar -xz -C ~/bin/
mv ~/bin/openshift-install ~/bin/openshift-install-${OCP_VERSION}
chmod +x ~/bin/openshift-install-${OCP_VERSION}
```

**Error**: `The OpenShift installer binary for version X.X.X does not exist`

**Cause**: The versioned binary `openshift-install-{VERSION}` is missing.

**Solution**:

```bash
# Download the specific version needed
OCP_VERSION="4.17.1"  # Replace with your cluster's version
curl -L "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux.tar.gz" | tar -xz -C ~/bin/
mv ~/bin/openshift-install ~/bin/openshift-install-${OCP_VERSION}
chmod +x ~/bin/openshift-install-${OCP_VERSION}
```

## Next Steps

1. **[Environment Variables](environment.md)** - Advanced configuration
2. **[Template Generation](template-generation.md)** - Preview manifests
3. **[Architecture](architecture.md)** - How ProxShift works
4. **[Vault Guide](vault-guide.md)** - Advanced secret management

---

**ProxShift** - Where Proxmox meets OpenShift
