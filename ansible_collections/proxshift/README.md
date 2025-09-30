# ProxShift Ansible Collections

This directory contains the ProxShift Ansible collections, organized by functional area for modular usage and maintenance.

## 📦 Collection Structure

```
ansible_collections/proxshift/
├── openshift/              # OpenShift cluster management (8 roles)
│   ├── roles/
│   │   ├── acm_import/     # ACM cluster import operations
│   │   ├── cluster_auth/   # Cluster authentication
│   │   ├── cluster_credentials/ # Credential management
│   │   ├── node_labeling/  # Node labeling operations
│   │   ├── oc_kubeadmin/   # Kubeadmin authentication
│   │   ├── ocp_manifests/  # OpenShift manifest generation
│   │   ├── secret_management/ # Secret backup/restore
│   │   └── vault_credentials/ # Vault credential storage
│   └── README.md          # OpenShift collection documentation
├── hashi_vault/           # HashiCorp Vault integration (1 role)
│   ├── roles/
│   │   └── hashicorp_vault/ # Secret retrieval from Vault
│   └── README.md          # Vault collection documentation
├── proxmox/               # Proxmox infrastructure management (2 roles)
│   ├── roles/
│   │   ├── proxmox_vm/     # VM lifecycle management
│   │   └── vm_lifecycle/   # VM start/stop operations
│   └── README.md          # Proxmox collection documentation
└── README.md              # This file
```

## 🚀 Quick Start

### Installation

Install all collections from the ProxShift root directory:

```bash
cd /path/to/proxshift
ansible-galaxy collection install -r collections/requirements.yml
```

### Individual Collection Installation

Install specific collections as needed:

```bash
# OpenShift management only
ansible-galaxy collection install ./ansible_collections/proxshift/openshift

# Vault integration only  
ansible-galaxy collection install ./ansible_collections/proxshift/hashi_vault

# Proxmox infrastructure only
ansible-galaxy collection install ./ansible_collections/proxshift/proxmox
```

## 🧪 Testing Individual Roles

ProxShift includes a comprehensive test driver playbook for testing roles individually or in combination.

### Test Playbook: `roles_test.yaml`

**Location:** `/path/to/proxshift/roles_test.yaml`

This playbook demonstrates usage of all ProxShift collection roles with:

- Mock/fallback configurations for environments without full infrastructure
- Individual role testing capabilities
- Comprehensive examples and documentation
- Safe execution with check mode and error handling

### Running Role Tests

#### Test All Roles (Demo Mode)

```bash
cd /path/to/proxshift
ansible-playbook roles_test.yaml
```

#### Test with Real Infrastructure

```bash
# Configure your environment variables
export VAULT_TOKEN="your-vault-token"
export VAULT_ADDR="https://vault.example.com:8200"

# Run with real credentials
ansible-playbook roles_test.yaml \
  -e vault_token="$VAULT_TOKEN" \
  -e vault_addr="$VAULT_ADDR" \
  -e proxmox_host="proxmox.example.com" \
  -e proxmox_user="api-user@pve" \
  -e proxmox_password="your-password"
```

#### Test Individual Collections

**HashiCorp Vault Collection:**

```bash
ansible-playbook roles_test.yaml --tags "vault"
```

**OpenShift Collection:**

```bash
ansible-playbook roles_test.yaml --tags "openshift"
```

**Proxmox Collection:**

```bash
ansible-playbook roles_test.yaml --tags "proxmox"
```

### Test Configuration

The test playbook includes configurable variables at the top:

```yaml
vars:
  # Test configuration - modify these for your environment
  test_cluster_name: "test-sno"
  test_vmid: 999
  test_node_name: "test-sno-master"
  
  # Vault configuration
  vault_config:
    address: "{{ vault_addr | default('https://vault.example.com:8200') }}"
    token: "{{ vault_token | default('your-vault-token') }}"
    path: "{{ vault_path | default('secret/data/openshift/clusters') }}"
  
  # Proxmox configuration  
  proxmox_config:
    host: "{{ proxmox_host | default('proxmox.example.com') }}"
    user: "{{ proxmox_user | default('api-user@pve') }}"
    password: "{{ proxmox_password | default('your-proxmox-password') }}"
```

## 🔧 Individual Role Usage

### OpenShift Collection Examples

#### Authenticate to Cluster

```yaml
- name: Login to OpenShift cluster
  ansible.builtin.include_role:
    name: proxshift.openshift.oc_kubeadmin
  vars:
    oc_kubeadmin_cluster_name: "my-cluster"
    oc_kubeadmin_vault_addr: "https://vault.example.com:8200"
    oc_kubeadmin_vault_token: "{{ vault_token }}"
    oc_kubeadmin_vault_path: "secret/data/openshift/clusters"
```

#### Generate OpenShift Manifests

```yaml
- name: Generate installation manifests
  ansible.builtin.include_role:
    name: proxshift.openshift.ocp_manifests
  vars:
    ocp_manifests_cluster:
      name: "production-cluster"
      version: "4.17.1"
    ocp_manifests_network:
      base_domain: "example.com"
      subnet: "10.0.0.0/24"
      gateway: "10.0.0.1"
      dns_servers: ["10.0.0.1", "8.8.8.8"]
    ocp_manifests_nodes: "{{ cluster_nodes }}"
    ocp_manifests_credentials:
      pull_secret: "{{ pull_secret }}"
      ssh_key: "{{ ssh_public_key }}"
    ocp_manifests_output_dir: "/tmp/manifests"
```

### Vault Collection Examples

#### Retrieve Secrets

```yaml
- name: Get secrets from Vault
  ansible.builtin.include_role:
    name: proxshift.hashi_vault.hashicorp_vault
  vars:
    hashicorp_vault_api:
      url: "https://vault.example.com:8200"
      token: "{{ vault_token }}"
    hashicorp_vault_secrets:
      - name: "pull_secret"
        path: "secret/data/openshift/registry"
        key: "pull_secret"
      - name: "ssh_key"
        path: "secret/data/openshift/access"
        key: "public_key"
    hashicorp_vault_output_var: "retrieved_secrets"
```

### Proxmox Collection Examples

#### Create VM

```yaml
- name: Create Proxmox VM
  ansible.builtin.include_role:
    name: proxshift.proxmox.proxmox_vm
  vars:
    proxmox_vm_api:
      host: "proxmox.example.com"
      user: "api-user@pve"
      password: "{{ proxmox_password }}"
    proxmox_vm_config:
      node: "pve-node1"
      vmid: 101
      name: "openshift-master"
      memory: 16384
      cores: 4
      disks:
        scsi0:
          size: "120G"
          storage: "local-lvm"
      nics:
        net0:
          bridge: "vmbr0"
          model: "virtio"
    proxmox_vm_state: "present"
```

## 📚 Documentation

Each collection includes comprehensive documentation:

- **[OpenShift Collection](openshift/README.md)** - OpenShift cluster management
- **[HashiCorp Vault Collection](hashi_vault/README.md)** - Vault integration
- **[Proxmox Collection](proxmox/README.md)** - Infrastructure management

Individual roles include:
- Detailed README files with usage examples
- Argument specifications in `meta/argument_specs.yml`
- Complete parameter documentation and examples

## 🏗️ Development

### Adding New Roles

Place new roles in the appropriate collection:

```bash
# OpenShift-related functionality
ansible_collections/proxshift/openshift/roles/new_openshift_role/

# Vault-related functionality  
ansible_collections/proxshift/hashi_vault/roles/new_vault_role/

# Proxmox-related functionality
ansible_collections/proxshift/proxmox/roles/new_proxmox_role/
```

Each role should include:

- `tasks/main.yml` - Main role tasks
- `defaults/main.yml` - Default variables
- `meta/main.yml` - Role metadata
- `meta/argument_specs.yml` - Parameter specifications
- `README.md` - Usage documentation

### Testing New Roles

Add new role tests to `roles_test.yaml`:

```yaml
- name: "TEST: New Role"
  block:
    - name: "Test new role"
      ansible.builtin.include_role:
        name: proxshift.collection.new_role
      vars:
        # role variables
```

## 🔗 Integration

These collections are designed to work together as part of the complete ProxShift system:

1. **Vault** retrieves secrets for cluster operations
2. **OpenShift** manages cluster lifecycle and configuration  
3. **Proxmox** provides infrastructure and VM management

For complete cluster provisioning workflows, see the main ProxShift documentation.

## ⚡ ProxShift

**ProxShift** - Where Proxmox meets OpenShift

🔗 **GitHub:** [https://github.com/randyoyarzabal/proxshift](https://github.com/randyoyarzabal/proxshift)
