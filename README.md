# ProxShift

OpenShift clusters on Proxmox made simple.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ansible](https://img.shields.io/badge/Ansible-2.15%2B-red)](https://ansible.com)
[![OpenShift](https://img.shields.io/badge/OpenShift-4.16%2B-red)](https://openshift.com)

## Quick Start

```bash
# 1. Setup virtual environment (avoids "pip externally managed" errors)
git clone https://github.com/randyoyarzabal/proxshift.git
cd proxshift
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 2. Configure and deploy
cp examples/site-config.yaml config/
cp examples/clusters.yml.template inventory/clusters.yml
# Edit configs for your environment

# 3. Set environment and deploy cluster
export PROXSHIFT_ROOT=$HOME/dev/proxshift
export PROXSHIFT_VAULT_PASS=${PROXSHIFT_ROOT}/config/.vault_pass

source proxshift.sh
ps.activate
ps.provision ocp-sno1
```

## Features

- **Modern Python Setup** - Virtual environment support with manual activation control
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
source proxshift.sh  # Auto-activates .venv and loads functions

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

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   ProxShift     │    │     Proxmox      │    │   OpenShift     │
│   (Controller)  │────▶│   (Hypervisor)   │────▶│   (Cluster)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
    ┌────▼────┐              ┌───▼───┐              ┌────▼────┐
    │  Vault  │              │  VMs  │              │  Nodes  │
    │ (Secrets)│              │(ISO)  │              │(Workload)│
    └─────────┘              └───────┘              └─────────┘
```

**ProxShift workflow:**
1. **Retrieve secrets** from HashiCorp Vault
2. **Generate manifests** using universal templates
3. **Create ISO** with agent-based installer
4. **Provision VMs** on Proxmox with ISO mounting
5. **Auto-install** OpenShift via agent installer
6. **Import cluster** to ACM hub (optional)

## Project Structure

```
proxshift/
├── .venv/                      # Virtual environment (auto-created)
├── proxshift.sh               # Main entry point with auto-venv
├── site.yaml                  # Primary Ansible playbook
├── config/
│   ├── site-config.yaml       # Environment configuration
│   └── vault-credentials.yml  # Vault connection settings
├── inventory/
│   └── clusters.yml           # All cluster definitions
├── ansible_collections/       # ProxShift roles and collections
│   └── proxshift/
│       ├── openshift/         # OpenShift-specific roles
│       ├── proxmox/           # Proxmox VM management
│       └── hashi_vault/       # Vault integration
├── ocp_install/               # Generated files per cluster
│   ├── ocp-sno1/             # ISO, credentials, manifests
│   └── ocp3/
└── docs/                      # Comprehensive documentation
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
# Solution: Use virtual environment (modern Python security)
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Permission Denied on Mount

```bash
# ProxShift uses user-space mounts in ./.tmpmount/ - no sudo needed
# Ensure network share allows user access (SMB/NFS permissions)
```

### Ansible Collection Not Found

```bash
# Ensure virtual environment is activated
source .venv/bin/activate
ansible-galaxy collection install -r collections/requirements.yml --force
```

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Setup development environment: `source .venv/bin/activate`
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