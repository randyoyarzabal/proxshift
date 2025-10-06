# ProxShift

Welcome to **ProxShift** - OpenShift clusters on Proxmox made simple.

## Table of Contents

### Getting Started

- [Prerequisites](prerequisites.md) - System requirements and virtual environment setup
- [Setup Guide](setup.md) - Complete installation and configuration
- [Environment Guide](environment.md) - Virtual environments and shell integration
- [Welcome Guide](welcome.md) - Comprehensive introduction

### User Guides

- [Architecture](architecture.md) - How ProxShift works under the hood
- [Template Generation](template-generation.md) - Preview manifests before provisioning
- [Vault Guide](vault-guide.md) - Secret management with HashiCorp Vault
- [Backup & Restore](backup-restore-guide.md) - Certificate backup and restore
- [Migration Notes](migration-notes.md) - Version upgrade guidance
- [Modular Tasks](modular-tasks.md) - Understanding ProxShift's task structure

### Advanced Topics

- [Function Reference](function-reference.md) - Complete command reference
- [System Requirements](system-requirements.md) - Detailed system requirements
- [Cluster Login Refactoring](cluster-login-refactoring.md) - Authentication improvements
- [Demo Guide](demo.md) - Demonstration scenarios

### Reference

- [Changelog](changelog.md) - Version history and changes

## Quick Start

New to ProxShift? Start here:

1. **[Prerequisites](prerequisites.md)** - System requirements and virtual environment setup
2. **[Setup Guide](setup.md)** - Complete installation and configuration
3. **[Environment Guide](environment.md)** - Virtual environments and shell integration
4. **[Quick Examples](#quick-examples)** - Common commands

## Quick Examples

### Single Node OpenShift (SNO)

```bash
cd /path/to/proxshift
source proxshift.sh  # Auto-activates virtual environment
ps.provision ocp-sno1
```

### Compact Cluster (3 masters)

```bash
ps.provision ocp3
```

### Full Production Cluster (3 masters + 3 workers)

```bash
ps.provision ocp
```

### Preview Templates Only

```bash
ps.generate_manifests ocp-sno1 --dry-run
```

## Cluster Types

| Command | Type | Nodes | Use Case |
|---------|------|--------|----------|
| `ocp-sno1` | **SNO** | 1 | Edge, testing, dev |
| `ocp3` | **Compact** | 3 | Small production |
| `ocp` | **Standard** | 6 | Full production |

## Common Operations

```bash
# Load ProxShift (auto-activates venv)
source proxshift.sh

# List available clusters
ps.clusters

# Start/stop VMs
ps.start ocp-sno1
ps.deprovision ocp-sno1

# Generate templates only
ps.generate_manifests ocp-sno1

# Full provisioning with preview
ps.provision ocp-sno1 --dry-run
ps.provision ocp-sno1
```

## Prerequisites

**Essential setup requirements:**

- **Python 3.8+** with virtual environment (avoids "pip externally managed" errors)
- **System packages** for NFS/SMB mounting (varies by OS)
- **OpenShift tools** (installer and CLI binaries)
- **Infrastructure access** (Proxmox API, Vault, DNS)

**[Complete Prerequisites Guide](prerequisites.md)**

## How It Works

ProxShift uses:

- **Inventory-driven** - All clusters in `inventory/clusters.yml`  
- **Universal templates** - No per-cluster files to maintain
- **Auto-detection** - SNO vs multi-node, IPs, roles
- **Portable** - Works from any directory

---

**ProxShift** - Where Proxmox meets OpenShift

**GitHub:** [https://github.com/randyoyarzabal/proxshift](https://github.com/randyoyarzabal/proxshift)
