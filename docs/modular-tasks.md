# ProxShift Modular Task Structure

## Overview

ProxShift has been restructured with modular tasks for better granular control over the cluster deployment workflow. This allows you to run specific parts of the deployment process independently.

## Task Files

### Preparation and Validation

#### `tasks/install_prep.yml`
**Purpose**: Validation and preparation
- Validates cluster name and OpenShift installer version
- Checks if cluster is already provisioned
- Handles directory cleanup when `force_install=true`
- Sets up necessary variables and state

**Tags**: `always`, `manifests`, `create_iso`

### Manifest and ISO Creation

#### `tasks/generate_manifests.yml`
**Purpose**: OpenShift manifest generation only
- Generates `install-config.yaml` and `agent-config.yaml`
- No ISO creation or other operations

**Tags**: `manifests`

#### `tasks/create_iso.yml`

**Purpose**: Bootable ISO creation only
- Validates that manifests exist
- Creates bootable ISO from existing manifests
- Handles NFS sharing and notifications

**Tags**: `create_iso`

### Installation Process

#### `tasks/installation.yml`
**Purpose**: Installation orchestration
- Coordinates the complete installation process
- Calls modular subtasks in sequence

**Tags**: `install`, `vault`, `cluster_login`

#### `tasks/wait_for_installation.yml`

**Purpose**: Installation waiting only
- Waits for OpenShift installation completion
- Validates installation success
- Rich progress information and troubleshooting

**Tags**: `install`

#### `tasks/store_credentials.yml`

**Purpose**: Vault credential storage
- Stores kubeconfig and kubeadmin password in Vault
- Validates credential files exist
- Clear success/failure feedback

**Tags**: `vault`

#### `tasks/cluster_login.yml`

**Purpose**: Reusable cluster authentication
- Can login to any OpenShift cluster (newly provisioned, ACM hub, etc.)
- Supports multiple authentication methods
- Returns authentication tokens for downstream tasks
- **Reusable across different scenarios**

**Tags**: `cluster_login`, `eso`, `gitops`, `acm_import`

## Usage Examples

### Generate Manifests Only

```bash
# Using ps.* functions
source proxshift.sh
ps.generate_manifests my-cluster

# Using ansible directly
ansible-playbook site.yaml -e cluster_name=my-cluster --tags=manifests
```

### Create ISO Only (manifests must exist)

```bash
# Using ansible directly  
ansible-playbook site.yaml -e cluster_name=my-cluster --tags=create_iso
```

### Installation Only (VMs already running)

```bash
# Wait for installation + store credentials + login
ansible-playbook site.yaml -e cluster_name=my-cluster --tags=install,vault,cluster_login
```

### Store Credentials Only

```bash
# Store existing credentials in Vault
ansible-playbook site.yaml -e cluster_name=my-cluster --tags=vault
```

### Full Workflow (traditional)

```bash
# Using ps.* functions
source proxshift.sh
ps.provision my-cluster

# Using ansible directly
ansible-playbook site.yaml -e cluster_name=my-cluster
```

### Custom Workflow

```bash
# 1. Generate manifests
ansible-playbook site.yaml -e cluster_name=my-cluster --tags=manifests

# 2. Customize manifests manually
# Edit files in ocp_install/my-cluster/

# 3. Create ISO with customized manifests  
ansible-playbook site.yaml -e cluster_name=my-cluster --tags=create_iso

# 4. Continue with VM provisioning
ansible-playbook site.yaml -e cluster_name=my-cluster --tags=vm_create,vm_start

# 5. Wait for installation
ansible-playbook site.yaml -e cluster_name=my-cluster --tags=install,vault,cluster_login
```

## Reusable Cluster Login

### Login to Newly Provisioned Cluster

```yaml
- name: "Login to newly provisioned cluster"
  ansible.builtin.include_tasks:
    file: tasks/cluster_login.yml
  vars:
    login_cluster_name: "{{ cluster_name }}"
    login_cluster_api_url: "{{ cluster_api_url }}"
    login_auth_method: "kubeadmin"
```

### Login to ACM Hub Cluster

```yaml
- name: "Login to ACM hub for import operations"
  ansible.builtin.include_tasks:
    file: tasks/cluster_login.yml
  vars:
    login_cluster_name: "{{ hub_cluster }}"
    login_cluster_api_url: "{{ hub_cluster_api_url }}"
    login_auth_method: "kubeadmin"
```

## Benefits

### **Granular Control**

- Generate manifests without creating ISO
- Customize manifests before ISO creation
- Skip steps you don't need
- Run only installation waiting without full deployment

### **Development Workflow**

- Test manifest generation independently
- Iterate on configuration without full deployment
- Debug specific parts of the process
- Store credentials separately from installation

### 📝 **Customization**

- Edit generated manifests before ISO creation
- Add custom configurations or patches
- Review generated files before proceeding
- Use custom authentication for cluster access

### **Efficiency**

- Skip expensive operations when not needed
- Faster iteration during development
- Better resource utilization
- Reuse authentication logic across operations

### 🔄 **Reusability**

- `cluster_login.yml` can be used for any cluster authentication
- Eliminates duplicate login logic in ACM operations
- Consistent authentication handling across workflows
- Easy integration into custom playbooks

## Workflow Diagram

```
┌─────────────────┐
│  install_prep   │ ← Always runs (validation & setup)
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│generate_manifests│ ← --tags=manifests
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│   create_iso    │ ← --tags=create_iso  
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│   VM Creation   │ ← Continue with rest of workflow
└─────────┬───────┘
          │
          ▼
┌─────────────────┐
│  installation   │ ← Installation orchestration
└─────────┬───────┘
          │
          ├─→ wait_for_installation
          ├─→ store_credentials  
          └─→ cluster_login
```

## Migration from Previous Version

**Before** (monolithic):
- `install_prep.yml` did validation + manifests + ISO
- `installation.yml` did waiting + vault + login in one file

**After** (modular):
- `install_prep.yml`: validation and setup only
- `generate_manifests.yml`: manifest generation only  
- `create_iso.yml`: ISO creation only
- `wait_for_installation.yml`: installation waiting only
- `store_credentials.yml`: vault operations only
- `cluster_login.yml`: reusable authentication

**No Breaking Changes**: Existing `ps.provision` workflow remains identical.

## Error Handling

### Missing Manifests

If you try to create ISO without manifests:
```
TASK [Fail if required manifest files are missing] ***
fatal: [localhost]: FAILED! => 
  msg: |
    Required manifest file 'install-config.yaml' not found.
    
    Generate manifests first:
      - Run with 'manifests' tag: --tags=manifests  
      - Or use ps.generate_manifests function
```

### Installation Timeout

```
TASK [Check installation status] ***
fatal: [localhost]: FAILED! => 
  msg: |
    ✗ Installation timed out after 3600 seconds.
    
    Troubleshooting:
      - Check logs in: ocp_install/my-cluster
      - Review agent.x86_64.iso boot process
      - Verify network connectivity and DNS
      - Check Proxmox VM console for errors
```

### Failed Cluster Login

```
TASK [Verify cluster login success] ***
  msg: |
    ✗ Login failed for cluster: my-cluster
    Check cluster status and credentials
```

This provides clear guidance on what steps are needed and how to troubleshoot issues.