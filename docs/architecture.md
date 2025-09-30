# ProxShift Architecture

Deep dive into how ProxShift works under the hood.

## 🏗️ System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        ProxShift Architecture                │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │
│  │   User      │    │  Ansible    │    │  HashiCorp  │       │
│  │ Interface   │───▶│  Playbooks  │───▶│    Vault    │       │
│  │             │    │             │    │             │       │
│  └─────────────┘    └─────────────┘    └─────────────┘       │
│         │                    │                    │          │
│         ▼                    ▼                    ▼          │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐       │
│  │ proxshift.sh│    │ Collection  │    │  Secrets    │       │
│  │  Commands   │    │   Roles     │    │ Management  │       │
│  │             │    │             │    │             │       │
│  └─────────────┘    └─────────────┘    └─────────────┘       │
│         │                    │                    │          │
│         ▼                    ▼                    ▼          │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                  Proxmox Infrastructure                 │ │
│  │                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │ │
│  │  │  VM Node 1  │  │  VM Node 2  │  │  VM Node 3  │      │ │
│  │  │             │  │             │  │             │      │ │
│  │  │ OpenShift   │  │ OpenShift   │  │ OpenShift   │      │ │
│  │  │   Master    │  │   Master    │  │   Worker    │      │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │ │
│  └─────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

## 🎯 Core Components

### 1. User Interface Layer

#### Command Line Interface (`proxshift.sh`)

- **Purpose**: Provides easy-to-use commands for cluster operations

- **Key Functions**:
  - `ps.provision` - Full cluster provisioning
  - `ps.generate_manifests` - Template generation only
  - `ps.clusters` - Show available clusters
  - `ps.start/ps.deprovision` - VM lifecycle management

#### Environment Management

- **Portable Design**: Works from any directory via `PROXSHIFT_ROOT`

- **Configuration Loading**: Automatic config discovery and validation
- **Dry-Run Support**: Preview operations before execution

### 2. Automation Engine (Ansible)

#### Main Playbook (`site.yaml`)

```yaml
Workflow:
1. Pre-tasks: Vault secret retrieval
2. Install Preparation: Directory setup, validation
3. Manifest Generation: OpenShift install/agent configs
4. VM Provisioning: Proxmox VM creation
5. Cluster Installation: OpenShift bootstrap
6. Post-Installation: ACM import, GitOps setup
```

#### Collection Structure (ProxShift Collections)

```
ansible_collections/proxshift/
├── openshift/              # OpenShift management
│   ├── roles/
│   │   ├── acm_import/     # ACM integration
│   │   ├── cluster_auth/   # Cluster authentication
│   │   ├── oc_kubeadmin/   # Kubeadmin authentication
│   │   ├── ocp_manifests/  # OpenShift manifests
│   │   └── secret_management/ # Secret operations
│   └── README.md          # OpenShift collection docs
├── hashi_vault/           # Vault integration
│   ├── roles/
│   │   └── hashicorp_vault/ # Secret retrieval
│   └── README.md          # Vault collection docs
└── proxmox/               # Infrastructure management
    ├── roles/
    │   ├── proxmox_vm/     # VM lifecycle
    │   └── vm_lifecycle/   # VM operations
    └── README.md          # Proxmox collection docs
```

### 3. Configuration Management

#### Inventory-Driven Design

```yaml
# inventory/clusters.yml
cluster_name:
  hosts:
    node_name:
      ip: "x.x.x.x"          # Static IP assignment
      mac: "xx:xx:xx:xx"     # MAC address
      role: "master|worker"   # Node role
      vmid: 100              # Proxmox VM ID
      memory: 16384          # RAM in MB
      cores: 4               # CPU cores
      node: "pve-node1"      # Proxmox node
```

#### Universal Templates

- **Jinja2 Templates**: Dynamic content generation
- **Auto-Detection**: SNO vs multi-node based on inventory
- **Role Assignment**: Automatic master/worker detection
- **Network Calculation**: IP ranges and subnet assignment

### 4. Secret Management

#### HashiCorp Vault Integration

```
Vault Structure:
secret/data/openshift/
├── registry/
│   └── pull_secret        # Container registry credentials
├── access/
│   └── public_key        # SSH public key
└── clusters/
    ├── cluster1/
    │   ├── kubeadmin     # Admin password
    │   ├── kubeconfig    # Cluster access config
    │   └── api          # API URL
    └── cluster2/
        └── ...
```

#### Secret Retrieval Flow

1. **Pre-task**: Retrieve secrets using `hashicorp_vault` role
2. **Storage**: Store in `vault_values` dictionary
3. **Usage**: Pass to roles requiring credentials
4. **Security**: Never log sensitive values

### 5. Infrastructure Layer

#### Proxmox VE Integration

- **API-Based**: Uses Proxmox REST API for all operations
- **Multi-Node Support**: Distributes VMs across cluster nodes
- **Resource Management**: Memory, CPU, disk, and network allocation
- **Lifecycle Operations**: Create, start, stop, delete VMs

#### VM Configuration Template

```yaml
VM Specifications:
- CPU: Host passthrough for optimal performance
- Memory: Configurable per node role
- Storage: Thin-provisioned disks
- Network: Bridge networking with static IPs
- Boot: UEFI with secure boot
- OS: RHCOS via ISO mounting
```

## 🔄 Provisioning Workflow

### Phase 1: Preparation

```
1. Environment Validation
   ├── Check PROXSHIFT_ROOT
   ├── Validate Ansible collections
   ├── Verify Vault connectivity
   └── Test Proxmox API access

2. Secret Retrieval
   ├── Connect to HashiCorp Vault
   ├── Retrieve pull secret
   ├── Get SSH public key
   └── Fetch certificates (if configured)

3. Configuration Preparation
   ├── Load site configuration
   ├── Parse cluster inventory
   ├── Validate node specifications
   └── Create output directories
```

### Phase 2: Manifest Generation

```
1. Template Processing
   ├── Detect cluster type (SNO/multi-node)
   ├── Generate install-config.yaml
   ├── Create agent-config.yaml
   └── Backup previous configs

2. Network Configuration
   ├── Calculate IP assignments
   ├── Configure DNS settings
   ├── Set up cluster networking
   └── Define node interfaces
```

### Phase 3: Infrastructure Provisioning

```
1. VM Creation (per node)
   ├── Create VM on Proxmox
   ├── Configure CPU/Memory
   ├── Attach storage disks
   ├── Setup network interfaces
   └── Mount OpenShift ISO

2. VM Lifecycle
   ├── Start VMs in sequence
   ├── Monitor boot process
   ├── Verify network connectivity
   └── Confirm OpenShift agent startup
```

### Phase 4: OpenShift Installation

```
1. Cluster Bootstrap
   ├── Monitor installation progress
   ├── Wait for API availability
   ├── Validate cluster readiness
   └── Extract credentials

2. Credential Storage
   ├── Store kubeconfig in Vault
   ├── Save kubeadmin password
   ├── Record API endpoint
   └── Set cluster metadata
```

### Phase 5: Post-Installation

```
1. ACM Integration (if configured)
   ├── Connect to hub cluster
   ├── Create ManagedCluster resource
   ├── Apply cluster labels
   └── Import to hub

2. GitOps Setup
   ├── Configure External Secrets Operator
   ├── Setup ArgoCD applications
   ├── Apply cluster policies
   └── Enable monitoring

3. Cluster Finalization
   ├── Apply node labels
   ├── Configure storage classes
   ├── Setup ingress routes
   └── Validate cluster health
```

## 🔧 Key Design Principles

### 1. Idempotent Operations

- **Safe Re-runs**: All operations can be safely repeated
- **State Detection**: Automatically detect existing resources
- **Incremental Updates**: Only change what's necessary
- **Error Recovery**: Resume from failure points

### 2. Portable Configuration

- **Environment Variables**: Runtime configuration override
- **No Hard-coded Paths**: All paths relative to `PROXSHIFT_ROOT`
- **Multi-Environment**: Same code works dev/staging/prod
- **User Agnostic**: Works for any user on any system

### 3. Modular Architecture

- **Role-Based**: Each function isolated in dedicated role
- **Collection Pattern**: Reusable across projects
- **Clear Interfaces**: Well-defined input/output contracts
- **Dependency Management**: Explicit role dependencies

### 4. Security by Design

- **Vault Integration**: All secrets stored securely
- **No Plaintext**: Credentials never stored in files
- **Access Control**: Vault policies control secret access
- **Audit Trail**: All secret access logged

## 🎨 Template System

### Universal Template Design

```jinja2
{# install-config.yaml.j2 #}
{% if cluster_type == 'sno' %}
  # Single Node OpenShift configuration
  compute:
  - name: worker
    replicas: 0
  controlPlane:
    name: master
    replicas: 1
{% else %}
  # Multi-node configuration
  compute:
  - name: worker
    replicas: {{ worker_count }}
  controlPlane:
    name: master
    replicas: {{ master_count }}
{% endif %}
```

### Dynamic Content Generation
- **Cluster Type Detection**: SNO vs multi-node
- **Node Role Assignment**: Master/worker based on inventory
- **Network Calculation**: Subnet and IP allocation
- **Resource Scaling**: Memory/CPU based on node count

## 🔍 Monitoring and Observability

### Installation Monitoring

```bash
# Real-time log monitoring
tail -f ocp_install/cluster-name/.openshift_install.log

# Progress tracking
watch "oc get nodes --kubeconfig ocp_install/cluster-name/auth/kubeconfig"

# Cluster readiness
oc get clusterversion,nodes,co
```

### Health Checks

- **VM Status**: Proxmox VM power state and resource usage
- **Network Connectivity**: API endpoint accessibility
- **Cluster Health**: OpenShift cluster operator status
- **ACM Status**: Hub cluster import verification

## 🚀 Performance Characteristics

### Typical Provisioning Times

| Cluster Type | VM Creation | OpenShift Install | Total Time |
|--------------|-------------|------------------|------------|
| **SNO** | 2-3 minutes | 45-60 minutes | ~1 hour |
| **Compact (3 nodes)** | 3-5 minutes | 60-75 minutes | ~1.5 hours |
| **Full (6 nodes)** | 5-8 minutes | 75-90 minutes | ~2 hours |

### Resource Requirements

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| **Master Node** | 4 cores | 16 GB | 120 GB |
| **Worker Node** | 8 cores | 32 GB | 500 GB |
| **SNO Node** | 8 cores | 32 GB | 120 GB |

### Scaling Considerations
- **Proxmox Cluster**: Distribute VMs across nodes for HA
- **Network Bandwidth**: Consider cluster networking requirements
- **Storage Performance**: SSD recommended for etcd workloads
- **DNS Resolution**: Ensure proper DNS configuration

## 🔮 Extension Points

### Custom Roles

```yaml
# Add custom role to appropriate collection
ansible_collections/proxshift/openshift/roles/custom_role/
├── tasks/main.yml
├── defaults/main.yml
├── meta/argument_specs.yml
└── README.md

# Or for Vault-related functionality:
ansible_collections/proxshift/hashi_vault/roles/custom_vault_role/

# Or for Proxmox-related functionality:
ansible_collections/proxshift/proxmox/roles/custom_proxmox_role/
```

### Plugin Architecture

- **Custom Modules**: Extend Ansible with custom functionality
- **Filter Plugins**: Custom Jinja2 filters for templates
- **Lookup Plugins**: Additional secret/data sources
- **Callback Plugins**: Custom logging and notifications

### Integration Hooks

- **Pre/Post Tasks**: Custom tasks before/after provisioning
- **Custom Templates**: Override default OpenShift manifests
- **External APIs**: Integrate with additional services
- **Custom Vault Paths**: Flexible secret organization

---

**ProxShift** - Where Proxmox meets OpenShift ⚡
