# ProxShift Function Reference

## Overview

ProxShift provides a modern `ps.*` function interface for managing OpenShift clusters on Proxmox. All functions support the `--dry-run` flag to preview commands before execution.

## Loading Functions

The main script is now located in the project root for easy access:

```bash
# From project root
source proxshift.sh

# Or from anywhere with PROXSHIFT_ROOT set
source $PROXSHIFT_ROOT/proxshift.sh
```

## Core Functions

### ps.clusters
List all available clusters from inventory.

```bash
ps.clusters
```

### ps.validate_cluster
Validate that a cluster exists in the inventory.

```bash
ps.validate_cluster <cluster_name>
```

### ps.root
Change to the ProxShift project root directory.

```bash
ps.root
```

## Cluster Management

### ps.provision
Complete cluster provisioning workflow (recommended for most users).

```bash
ps.provision <cluster_name> [--dry-run]
```

### ps.generate_manifests
Generate OpenShift install manifests only (useful for customization).

```bash
ps.generate_manifests <cluster_name> [--dry-run]
```

## VM Lifecycle

### ps.start
Start VMs for a cluster.

```bash
ps.start <cluster_name> [--dry-run]
```

### ps.deprovision
Delete VMs for a cluster.

```bash
ps.deprovision <cluster_name> [--dry-run]
```

## Post-Installation

### ps.post
Run post-installation tasks (storage labels, certificates, etc.).

```bash
ps.post <cluster_name> [--dry-run]
```

### ps.acm_import
Import cluster to ACM hub.

```bash
ps.acm_import <cluster_name> [--dry-run]
```

### ps.backup_certs
Backup certificate secrets from EXISTING ocp-sno1 cluster.

```bash
ps.backup_certs [--dry-run]
```

Backs up:
- `secret-homelab-ca-tls` from `cert-manager` namespace
- `secret-homelab-io-tls` from `homelab` namespace  

Files saved to: `$gitops_root/backups/` using format: `{namespace}-{secret-name}.yaml`

### ps.restore_certs
Restore certificate secrets to REBUILT ocp-sno1 cluster.

```bash
ps.restore_certs [--dry-run]
```

Restores:
- `secret-homelab-ca-tls` → `cert-manager` namespace
- `secret-homelab-io-tls` → `homelab` namespace

Files read from: `$gitops_root/backups/` using format: `{namespace}-{secret-name}.yaml`

## GitOps and Vault

### ps.gitops
Apply GitOps configuration.

```bash
ps.gitops <cluster_name> [--dry-run]
```

### ps.gitops_loop
Run GitOps reconciliation loop (ocp-sno1 only).

```bash
ps.gitops_loop [--dry-run]
```

### ps.vault
Store cluster credentials in Vault.

```bash
ps.vault <cluster_name> [--dry-run]
```

### ps.dns
Configure DNS for cluster.

```bash
ps.dns <cluster_name> [--dry-run]
```

## Advanced Operations

### ps.force
Force complete cluster deployment with timing.

```bash
ps.force <cluster_name> [extra_args] [--dry-run]
```

### ps.force_nohub
Force deployment without ACM import.

```bash
ps.force_nohub <cluster_name> [extra_args] [--dry-run]
```

### ps.force_blank
Force deployment with minimal components (blank cluster).

```bash
ps.force_blank <cluster_name> [extra_args] [--dry-run]
```

## Installation Monitoring

### ps.install_watch
Watch OpenShift installation progress.

```bash
ps.install_watch <cluster_name>
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PROXSHIFT_ROOT` | `$(pwd)` | Project root directory |
| `PROXSHIFT_VAULT_PASS` | `${PROXSHIFT_ROOT}/config/.vault_pass` | Ansible vault password file |
| `PROXSHIFT_GITOPS_ROOT` | `${HOME}/gitops` | GitOps directory for install_watch |

## Examples

### Complete Cluster Deployment
```bash
# Preview the full deployment
ps.provision ocp-sno3 --dry-run

# Execute the deployment
ps.provision ocp-sno3
```

### Manifest Generation Only
```bash
# Generate manifests for customization
ps.generate_manifests ocp-sno3

# Review generated files
ls ocp_install/ocp-sno3/
```

### Blank Cluster (No GitOps/ACM)
```bash
# Deploy minimal cluster
ps.force_blank ocp-sno3
```

### Post-Installation Tasks
```bash
# Apply storage labels, backup certs, configure GitOps
ps.post ocp-sno3
```

## Dry Run Mode

All functions support `--dry-run` mode to preview commands:

```bash
ps.provision ocp-sno3 --dry-run
# Output:
# 🧪 DRY RUN - Command that would be executed:
#    ansible-playbook site.yaml -e cluster_name=ocp-sno3 -e force_install=true --skip-tags=backup,restore
```

## Migration from ocp.* Functions

| Old Function | New Function | Notes |
|--------------|--------------|-------|
| `ocp.list_clusters` | `ps.clusters` | Modern name |
| `ocp.provision` | `ps.provision` | Same functionality |
| `ocp.ansible_*` | `ps.*` | Removed "ansible" prefix |
| `ocp.generate_templates` | `ps.generate_manifests` | Renamed for clarity |

The new `ps.*` functions provide the same functionality with cleaner naming conventions.
