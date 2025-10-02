# ProxShift

OpenShift clusters on Proxmox made simple.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ansible](https://img.shields.io/badge/Ansible-2.15%2B-red)](https://ansible.com)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.16%2B-red)](https://openshift.com)

## Quick Start

```bash
# 1. Clone and setup
git clone https://github.com/randyoyarzabal/proxshift.git
cd proxshift

# 2. Configure for your environment
mkdir -p ~/.proxshift
mkdir -p inventory
cp examples/site-config.yaml ~/.proxshift/
cp examples/vault-credentials.yml ~/.proxshift/
cp examples/clusters.yml.template inventory/clusters.yml
# Edit configs for your environment

# 3. Deploy cluster (auto-creates venv and installs dependencies)
export PROXSHIFT_ROOT=$HOME/dev/proxshift
export PROXSHIFT_VAULT_PASS=${HOME}/.proxshift/.vault_pass

source proxshift.sh
ps.activate  # Auto-creates .venv, installs deps, activates environment
ps.provision ocp-sno1
```

## Features

- **Auto-Setup Environment** - `ps.activate` auto-creates venv, installs dependencies, and activates
- **Zero Package Management** - No sudo required, uses user-space mounts
- **Secure by Default** - All credential operations use `no_log: true`
- **Inventory-Driven** - Define all clusters in `inventory/clusters.yml`
- **Universal Templates** - No per-cluster files to maintain
- **Auto-Detection** - SNO vs multi-node, IPs, roles, protocol detection
- **Portable** - Works from any directory with consistent setup

## Requirements

### System Prerequisites

| OS | Requirements |
|----|-------------|
| **macOS** | `brew install python3` (NFS/SMB built-in) |
| **Ubuntu/Debian** | `apt install python3 python3-venv nfs-common cifs-utils` |
| **RHEL/CentOS/Fedora** | `dnf install python3 nfs-utils cifs-utils` |

### Infrastructure

- **Proxmox VE 7.0+** with API access
- **HashiCorp Vault** with KV secrets
- **DNS** with cluster domain resolution
- **Network** with static IP allocation

## Cluster Types

| Cluster | Type | Nodes | Memory | Use Case |
|---------|------|-------|---------|----------|
| `ocp-sno1` | Single Node | 1 | 16GB+ | Edge, dev, testing |
| `ocp3` | Compact | 3 masters | 48GB+ | Small production |
| `ocp` | Standard | 3+3 | 96GB+ | Full production |

## Core Commands

```bash
# Environment setup (run once)
source proxshift.sh  # Loads functions
ps.activate          # Auto-creates .venv, installs deps, activates environment

# Cluster operations
ps.clusters                    # List available clusters
ps.provision ocp-sno1         # Deploy complete cluster
ps.provision ocp-sno1 --dry-run  # Preview without execution

# Lifecycle management
ps.start ocp-sno1            # Start cluster VMs
ps.deprovision ocp-sno1      # Stop and remove cluster

# Template operations
ps.generate_manifests ocp-sno1  # Generate OpenShift manifests only
ansible-playbook site.yaml -e cluster_name=ocp-sno1 --tags=create_iso
```

## Architecture

```text
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│     ProxShift       │    │      Proxmox        │    │     OpenShift       │
│    (Controller)     │───▶│    (Hypervisor)     │───▶│     (Cluster)       │
└─────────────────────┘    └─────────────────────┘    └─────────────────────┘
           │                           │                           │
    ┌──────▼──────┐              ┌─────▼─────┐              ┌──────▼──────┐
    │    Vault    │              │    VMs    │              │    Nodes    │
    │  (Secrets)  │              │   (ISO)   │              │ (Workload)  │
    └─────────────┘              └───────────┘              └─────────────┘
```

**ProxShift workflow:**

1. **Retrieve secrets** from HashiCorp Vault
2. **Generate manifests** using universal templates
3. **Create ISO** with agent-based installer
4. **Provision VMs** on Proxmox with ISO mounting
5. **Auto-install** OpenShift via agent installer
6. **Import cluster** to ACM hub (optional)

## Project Structure

```text
proxshift/
├── .venv/                     # Virtual environment (auto-created)
├── proxshift.sh               # Main entry point with auto-venv
├── site.yaml                  # Primary Ansible playbook
├── ansible.cfg                # Ansible configuration
├── inventory/                 # User cluster inventory (gitignored)
│   └── clusters.yml           # Your cluster definitions (or symlink to external)
├── examples/                  # Configuration templates
│   ├── site-config.yaml       # Environment configuration template
│   ├── vault-credentials.yml  # Vault connection template
│   └── clusters.yml.template  # Cluster definitions template
├── ansible_collections/       # ProxShift roles and collections
│   └── proxshift/
│       ├── openshift/         # OpenShift-specific roles
│       ├── proxmox/           # Proxmox VM management
│       └── hashi_vault/       # Vault integration
├── ocp_install/               # Generated files per cluster
│   ├── ocp-sno1/              # ISO, credentials, manifests
│   └── ocp3/
└── docs/                      # Comprehensive documentation

# User configuration (created during installation)
~/.proxshift/
├── site-config.yaml           # Your environment configuration
├── vault-credentials.yml      # Your vault connection settings
└── .vault_pass               # Vault password file

# Alternative: Symlink to external inventory
# ln -s ~/.proxmox/inventory/clusters.yml inventory/clusters.yml
# or: ln -s /path/to/your/existing/inventory inventory
```

## Documentation

| Guide | Description |
|-------|-------------|
| **[Prerequisites](docs/prerequisites.md)** | System requirements and virtual environment setup |
| **[Setup Guide](docs/setup.md)** | Complete installation and configuration |
| **[Environment Guide](docs/environment.md)** | Virtual environments and shell integration |
| **[Architecture](docs/architecture.md)** | How ProxShift works internally |
| **[Function Reference](docs/FUNCTION_REFERENCE.md)** | Complete command reference |

## Troubleshooting

### "pip externally managed" Error

```bash
# Solution: Use ps.activate (auto-creates venv and installs dependencies)
source proxshift.sh
ps.activate  # Handles everything automatically
```

### Permission Denied on Mount

```bash
# ProxShift uses user-space mounts in ./.tmpmount/ - no sudo needed
# Ensure network share allows user access (SMB/NFS permissions)
```

### Ansible Collection Not Found

```bash
# Use ps.activate to ensure everything is properly installed
source proxshift.sh
ps.activate  # Auto-installs collections and activates environment
```

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Setup development environment: `source proxshift.sh && ps.activate`
4. Test changes: `ansible-lint`, `yamllint`
5. Commit changes: `git commit -m 'Add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- OpenShift team for the agent-based installer
- Proxmox team for the excellent virtualization platform
- Ansible community for automation excellence
- HashiCorp for Vault secret management

---

**ProxShift** - Where Proxmox meets OpenShift

**GitHub:** [https://github.com/randyoyarzabal/proxshift](https://github.com/randyoyarzabal/proxshift)
