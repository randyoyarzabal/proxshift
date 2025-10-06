# ProxShift

> **OpenShift clusters on Proxmox made simple**

Deploy OpenShift clusters on Proxmox with automated setup, zero package management, and secure credential handling. Perfect for homelabs, development, and production environments.

## Quick Start (3 Steps)

### 1. Clone & Setup

```bash
git clone https://github.com/randyoyarzabal/proxshift.git
cd proxshift

# Auto-setup environment
source proxshift.sh
ps.activate  # Creates venv, installs dependencies, activates environment
```

### 2. Configure Environment

```bash
# Copy configuration templates
mkdir -p ~/.proxshift inventory
cp examples/site-config.yaml ~/.proxshift/
cp examples/vault-credentials.yml ~/.proxshift/
cp examples/clusters.yml.template inventory/clusters.yml

# Edit configs for your environment
```

### 3. Deploy Cluster

```bash
# Deploy single-node cluster
ps.provision ocp-sno1

# Or deploy multi-node cluster
ps.provision ocp3
```

**That's it!** Your OpenShift cluster is deploying. See [Complete Documentation](docs/setup.md) for advanced configuration.

## System Requirements

- **Python 3.8+** with venv support
- **Proxmox VE 7.0+** with API access
- **HashiCorp Vault** with KV secrets
- **DNS** with cluster domain resolution
- **Network** with static IP allocation

**Supported OS**: macOS, Ubuntu/Debian, RHEL/CentOS/Fedora

> **Need detailed setup instructions?** See [Prerequisites](docs/prerequisites.md) and [Setup Guide](docs/setup.md) for comprehensive installation steps.

## Production Setup

### Cluster Management

```bash
# List available clusters
ps.clusters

# Deploy cluster
ps.provision ocp-sno1

# Lifecycle management
ps.start ocp-sno1            # Start cluster VMs
ps.deprovision ocp-sno1      # Stop and remove cluster
```

### Advanced Operations

```bash
# Preview deployment without execution
ps.provision ocp-sno1 --dry-run

# Generate manifests only
ps.generate_manifests ocp-sno1

# Create ISO only
ansible-playbook site.yaml -e cluster_name=ocp-sno1 --tags=create_iso
```

> **Advanced cluster management?** See [Function Reference](docs/FUNCTION_REFERENCE.md) for complete command documentation.

## Key Commands

```bash
# Environment Management
source proxshift.sh && ps.activate

# Cluster Operations
ps.clusters|provision|start|deprovision

# Template Operations
ps.generate_manifests|ansible-playbook site.yaml
```

## Features

- **Deploy in Minutes** - 3-step setup process
- **Auto-Setup Environment** - `ps.activate` handles everything automatically
- **Zero Package Management** - No sudo required, uses user-space mounts
- **Secure by Default** - All credential operations use `no_log: true`
- **Inventory-Driven** - Define all clusters in `inventory/clusters.yml`
- **Universal Templates** - No per-cluster files to maintain
- **Auto-Detection** - SNO vs multi-node, IPs, roles, protocol detection
- **Portable** - Works from any directory with consistent setup

## Documentation

- **[Complete Guide](docs/setup.md)** - Full setup and configuration
- **[Prerequisites](docs/prerequisites.md)** - System requirements and setup
- **[Environment Guide](docs/environment.md)** - Virtual environments and shell integration
- **[Architecture](docs/architecture.md)** - How ProxShift works internally
- **[Function Reference](docs/FUNCTION_REFERENCE.md)** - Complete command reference

## Troubleshooting

### Common Issues

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

> **Need more troubleshooting help?** See [Complete Documentation](docs/setup.md) for detailed solutions and advanced configuration.

## Contributing

Issues and pull requests welcome! See our [GitHub repository](https://github.com/randyoyarzabal/proxshift).

## License

MIT License - see [LICENSE](LICENSE) for details.

---

**ProxShift** - Where Proxmox meets OpenShift
