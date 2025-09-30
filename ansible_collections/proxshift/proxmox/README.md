# ProxShift Proxmox Collection

A comprehensive Ansible collection for Proxmox VE infrastructure management, providing VM lifecycle operations and cluster resource management for ProxShift.

## Features

- **VM Lifecycle Management**: Complete VM creation, configuration, and lifecycle operations
- **Resource Configuration**: CPU, memory, disk, and network configuration
- **Multi-Node Support**: Distribute VMs across Proxmox cluster nodes
- **State Management**: Start, stop, restart, and delete operations
- **ISO Mounting**: Automatic ISO image mounting for installations
- **Validation**: Comprehensive configuration validation and error handling

## Roles

### VM Management
- `proxmox_vm` - Complete Proxmox VM lifecycle management
- `vm_lifecycle` - VM start/stop operations for cluster management

## Installation

```bash
# Install from local development
ansible-galaxy collection install ./ansible_collections/proxshift/proxmox

# Or reference in requirements.yml
collections:
  - name: ./ansible_collections/proxshift/proxmox
    type: dir
```

## Quick Start

### Basic VM Creation

```yaml
- name: Create VM on Proxmox
  hosts: localhost
  tasks:
    - name: Create basic VM
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
          name: "test-vm"
          memory: 4096
          cores: 2
        proxmox_vm_state: "present"
```

### Advanced VM with Custom Configuration

```yaml
- name: Create OpenShift node VM
  hosts: localhost
  tasks:
    - name: Create VM with full configuration
      ansible.builtin.include_role:
        name: proxshift.proxmox.proxmox_vm
      vars:
        proxmox_vm_api:
          host: "proxmox.example.com"
          user: "api-user@pve"
          password: "{{ proxmox_password }}"
        proxmox_vm_config:
          node: "pve-node1"
          vmid: 102
          name: "ocp-master-1"
          memory: 16384
          cores: 4
          sockets: 1
          cpu: "host"
          iso_image: "rhcos-live.iso"
          disks:
            scsi0:
              size: "120G"
              storage: "fast-ssd"
              ssd: true
              iothread: true
            scsi1:
              size: "500G"
              storage: "bulk-storage"
          nics:
            net0:
              bridge: "vmbr0"
              model: "virtio"
              tag: 100
              firewall: true
        proxmox_vm_state: "started"
        proxmox_vm_force: true
```

### VM Lifecycle Operations

```yaml
- name: Manage cluster VM lifecycle
  hosts: localhost
  tasks:
    # Start all VMs in cluster
    - name: Start cluster VMs
      ansible.builtin.include_role:
        name: proxshift.proxmox.vm_lifecycle
      vars:
        start_stop_vms_state: 'started'

    # Stop all VMs in cluster  
    - name: Stop cluster VMs
      ansible.builtin.include_role:
        name: proxshift.proxmox.vm_lifecycle
      vars:
        start_stop_vms_state: 'stopped'
```

### Bulk VM Creation

```yaml
- name: Create multiple VMs for OpenShift cluster
  hosts: localhost
  vars:
    cluster_nodes:
      - { name: "ocp-master-1", vmid: 110, memory: 16384, cores: 4, node: "pve-node1" }
      - { name: "ocp-master-2", vmid: 111, memory: 16384, cores: 4, node: "pve-node2" }
      - { name: "ocp-worker-1", vmid: 120, memory: 32768, cores: 8, node: "pve-node3" }
  tasks:
    - name: Create cluster VMs
      ansible.builtin.include_role:
        name: proxshift.proxmox.proxmox_vm
      vars:
        proxmox_vm_api:
          host: "proxmox.example.com"
          user: "api-user@pve"
          password: "{{ proxmox_password }}"
        proxmox_vm_config:
          name: "{{ item.name }}"
          node: "{{ item.node }}"
          vmid: "{{ item.vmid }}"
          memory: "{{ item.memory }}"
          cores: "{{ item.cores }}"
          disks:
            scsi0:
              size: "120G"
              storage: "local-lvm"
          nics:
            net0:
              bridge: "vmbr0"
              model: "virtio"
        proxmox_vm_state: "present"
      loop: "{{ cluster_nodes }}"
```

## Role Documentation

### proxmox_vm

Complete VM lifecycle management with comprehensive configuration options.

#### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `proxmox_vm_api.host` | string | Proxmox host FQDN or IP |
| `proxmox_vm_api.user` | string | Proxmox API user |
| `proxmox_vm_api.password` | string | Proxmox API password |
| `proxmox_vm_config.node` | string | Proxmox node name |
| `proxmox_vm_config.vmid` | integer | Unique VM ID |
| `proxmox_vm_config.name` | string | VM name |
| `proxmox_vm_config.memory` | integer | Memory in MB |

#### Optional Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `proxmox_vm_state` | `present` | VM state (present/absent/started/stopped) |
| `proxmox_vm_force` | `false` | Force recreation if VM exists |
| `cores` | `2` | CPU cores |
| `sockets` | `1` | CPU sockets |
| `cpu` | `host` | CPU type |

### vm_lifecycle

Manages start/stop operations for VM clusters.

#### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `start_stop_vms_state` | string | Desired state (started/stopped) |

Requires proper inventory structure with cluster definitions.

## Configuration Examples

### Disk Configuration

```yaml
disks:
  scsi0:
    size: "120G"
    storage: "local-lvm"
    ssd: true
    iothread: true
  scsi1:
    size: "500G"
    storage: "nfs-storage"
    backup: false
```

### Network Configuration

```yaml
nics:
  net0:
    bridge: "vmbr0"
    model: "virtio"
    tag: 100
    firewall: true
  net1:
    bridge: "vmbr1"
    model: "e1000"
    mac: "00:50:56:12:34:56"
```

### Performance Optimization

```yaml
proxmox_vm_config:
  # CPU optimization
  cpu: "host"
  cores: 8
  sockets: 1
  
  # Memory optimization
  memory: 32768
  
  # Storage optimization
  disks:
    scsi0:
      size: "120G"
      storage: "nvme-pool"
      ssd: true
      iothread: true
      
  # Network optimization
  nics:
    net0:
      bridge: "vmbr0"
      model: "virtio"
```

## Best Practices

### Resource Planning

1. **VMID Management**: Use consistent VMID ranges for different cluster types
2. **Resource Allocation**: Size VMs appropriately for OpenShift workloads
3. **Storage Selection**: Use SSD storage for master nodes (etcd performance)
4. **Network Planning**: Plan VLAN and bridge configurations in advance

### VM Configuration

1. **CPU Type**: Use "host" CPU type for best performance
2. **Memory**: Ensure adequate memory for OpenShift requirements
3. **Storage**: Use separate disks for OS and data when possible
4. **Networking**: Use virtio drivers for optimal network performance

### Operational Practices

1. **Backup Strategy**: Configure backup schedules for important VMs
2. **Monitoring**: Monitor VM resource usage and performance
3. **Updates**: Keep Proxmox VE updated for security and features
4. **Documentation**: Document VM configurations and purposes

## Error Handling

The collection provides comprehensive error handling for:

- Proxmox API connectivity issues
- Invalid VM configurations
- Resource constraint violations
- Storage and network configuration errors
- VM state management conflicts

## Security Considerations

1. **API Credentials**: Store Proxmox API credentials securely
2. **Network Security**: Configure firewall rules appropriately
3. **Access Control**: Use Proxmox user permissions and roles
4. **SSL/TLS**: Enable certificate validation in production

## Dependencies

- `community.general` collection for Proxmox modules
- Network access to Proxmox VE API
- Valid Proxmox API user with VM management permissions

## License

MIT

## Author Information

ProxShift Development Team
- Randy Oyarzabal <randyoyarzabal@gmail.com>
