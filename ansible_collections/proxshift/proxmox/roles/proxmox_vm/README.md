# Proxmox VM Role

## Description

This role manages the complete lifecycle of Proxmox VE virtual machines, including creation, configuration, and state management. It provides a clean interface for defining VM specifications with comprehensive disk and network configuration support.

## Requirements

- Ansible 2.15+
- Collections:
  - `community.general`
- Proxmox VE cluster with API access
- Valid Proxmox API credentials

## Role Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `proxmox_vm_api` | dict | Proxmox API connection details |
| `proxmox_vm_api.host` | string | Proxmox host FQDN or IP |
| `proxmox_vm_api.user` | string | Proxmox API user (e.g., `api-user@pve`) |
| `proxmox_vm_api.password` | string | Proxmox API password |
| `proxmox_vm_config` | dict | VM configuration specification |
| `proxmox_vm_config.node` | string | Proxmox node name |
| `proxmox_vm_config.vmid` | integer | VM ID (unique integer) |
| `proxmox_vm_config.name` | string | VM name |
| `proxmox_vm_config.memory` | integer | Memory in MB |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `proxmox_vm_state` | string | `present` | Desired VM state (`present`, `absent`, `started`, `stopped`, `restarted`) |
| `proxmox_vm_force` | boolean | `false` | Force VM recreation if exists |
| `proxmox_vm_timeout` | integer | `300` | Operation timeout in seconds |

### VM Configuration Options

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `cores` | integer | `2` | Number of CPU cores |
| `sockets` | integer | `1` | Number of CPU sockets |
| `cpu` | string | `host` | CPU type |
| `boot` | string | `order=scsi0;ide2` | Boot order |
| `onboot` | boolean | `true` | Start VM on boot |
| `ostype` | string | `l26` | OS type |
| `iso_image` | string | - | ISO image for CD-ROM |
| `disks` | dict | `{}` | Disk configuration |
| `nics` | dict | `{}` | Network interface configuration |

### Disk Configuration

Each disk in the `disks` dictionary should have:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `size` | string/int | Yes | Disk size (e.g., `"32G"` or `32`) |
| `storage` | string | No | Storage location (default: `local-lvm`) |
| `backup` | boolean | No | Include in backups |
| `ssd` | boolean | No | SSD optimization |
| `iothread` | boolean | No | Enable IO threads |

### Network Interface Configuration

Each NIC in the `nics` dictionary should have:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `model` | string | `virtio` | Network adapter model |
| `bridge` | string | `vmbr0` | Bridge interface |
| `mac` | string | - | MAC address (auto-generated if omitted) |
| `tag` | integer | - | VLAN tag |
| `firewall` | boolean | `false` | Enable firewall |

## Dependencies

None

## Example Playbook

### Basic VM Creation

```yaml
- name: Create basic VM
  hosts: localhost
  tasks:
    - name: Create VM on Proxmox
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

### Advanced VM with Multiple Disks and NICs

```yaml
- name: Create advanced VM
  hosts: localhost
  tasks:
    - name: Create VM with custom configuration
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
          name: "openshift-master"
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
            net1:
              bridge: "vmbr1"
              model: "virtio"
        proxmox_vm_state: "started"
        proxmox_vm_force: true
```

### VM Management Operations

```yaml
- name: Manage VM lifecycle
  hosts: localhost
  tasks:
    # Start VM
    - name: Start VM
      ansible.builtin.include_role:
        name: proxshift.proxmox.proxmox_vm
      vars:
        proxmox_vm_api: "{{ vm_api_config }}"
        proxmox_vm_config:
          node: "pve-node1"
          vmid: 101
          name: "test-vm"
          memory: 4096
        proxmox_vm_state: "started"

    # Stop VM
    - name: Stop VM
      ansible.builtin.include_role:
        name: proxshift.proxmox.proxmox_vm
      vars:
        proxmox_vm_api: "{{ vm_api_config }}"
        proxmox_vm_config:
          node: "pve-node1"
          vmid: 101
          name: "test-vm"
          memory: 4096
        proxmox_vm_state: "stopped"

    # Delete VM
    - name: Delete VM
      ansible.builtin.include_role:
        name: proxshift.proxmox.proxmox_vm
      vars:
        proxmox_vm_api: "{{ vm_api_config }}"
        proxmox_vm_config:
          node: "pve-node1"
          vmid: 101
          name: "test-vm"
          memory: 4096
        proxmox_vm_state: "absent"
```

## Error Handling

The role includes comprehensive validation for:
- Required API connection parameters
- VM configuration completeness
- Disk size specifications
- Network interface configurations

## Best Practices

1. **VMID Management**: Ensure VMIDs are unique across your Proxmox cluster
2. **Force Recreation**: Use `proxmox_vm_force: true` carefully as it will delete existing VMs
3. **Storage Selection**: Choose appropriate storage backends for your disk requirements
4. **Network Planning**: Plan your bridge and VLAN configurations in advance
5. **Resource Allocation**: Size memory and CPU appropriately for your workload

## License

MIT

## Author Information

ProxShift Development Team
