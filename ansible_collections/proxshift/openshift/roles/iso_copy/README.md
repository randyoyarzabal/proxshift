# ISO Copy Role

This Ansible role provides functionality to dynamically mount remote SMB/NFS shares and copy ISO files to them. It supports automatic protocol detection and handles mounting, copying, and cleanup operations.

## Features

- **Multi-protocol support**: SMB/CIFS and NFS
- **Automatic protocol detection**: Based on URL scheme (smb://, cifs://, nfs://)
- **Dynamic mounting**: No manual mount setup required
- **Automatic cleanup**: Mount points are cleaned up after operation
- **Error handling**: Comprehensive validation and error handling
- **Cross-platform**: Works on RHEL/CentOS, Ubuntu, and Fedora

## Requirements

- Ansible 2.9 or higher
- System packages (must be installed manually):
  - `cifs-utils` (for SMB/CIFS mounts on Linux)
  - `nfs-utils` or `nfs-common` (for NFS mounts on Linux)
  - Note: macOS users need to install via Homebrew or use built-in mount commands

## Role Variables

### Required Variables

- `iso_source_file`: Full path to the source ISO file to copy
- `iso_destination_path`: Remote path in format `protocol://host/share/path`

### Optional Variables

- `iso_destination_filename`: Name of destination file (default: source filename)
- `iso_mount_user`: Username for SMB authentication (required for SMB)
- `iso_mount_password`: Password for SMB authentication (required for SMB)
- `iso_mount_timeout`: Mount operation timeout in seconds (default: 30)
- `iso_cleanup_on_failure`: Cleanup mount points on failure (default: true)

## Example Usage

### SMB/CIFS Share

```yaml
- name: Copy ISO to SMB share
  include_role:
    name: proxshift.openshift.iso_copy
  vars:
    iso_source_file: "/path/to/source/agent.x86_64.iso"
    iso_destination_path: "smb://172.25.50.122/nfs_data/template/iso"
    iso_destination_filename: "cluster-agent.x86_64.iso"
    iso_mount_user: "{{ iso_path_user }}"
    iso_mount_password: "{{ iso_path_pass }}"
```

### NFS Share

```yaml
- name: Copy ISO to NFS share
  include_role:
    name: proxshift.openshift.iso_copy
  vars:
    iso_source_file: "/path/to/source/agent.x86_64.iso"
    iso_destination_path: "nfs://172.25.50.122/nfs_data/template/iso"
    iso_destination_filename: "cluster-agent.x86_64.iso"
```

### Local Directory

```yaml
- name: Copy ISO to local directory
  include_role:
    name: proxshift.openshift.iso_copy
  vars:
    iso_source_file: "/path/to/source/agent.x86_64.iso"
    iso_destination_path: "/mnt/local/iso"
    iso_destination_filename: "cluster-agent.x86_64.iso"
```

## Handler Integration

This role is designed to be used in handlers for automated ISO copying:

```yaml
# In handlers/main.yml
- name: "Copy boot image to remote share"
  include_role:
    name: proxshift.openshift.iso_copy
  vars:
    iso_source_file: "{{ ocp_install_dir }}/agent.x86_64.iso"
    iso_destination_path: "{{ iso_boot_path }}"
    iso_destination_filename: "{{ cluster_name }}-agent.x86_64.iso"
    iso_mount_user: "{{ iso_path_user }}"
    iso_mount_password: "{{ iso_path_pass }}"
```

## Protocol Support

| Protocol | URL Format | Authentication | Notes |
|----------|------------|----------------|-------|
| SMB/CIFS | `smb://host/share/path` | Username/Password | Requires cifs-utils |
| NFS | `nfs://host/path` | None | Requires nfs-utils/nfs-common |
| Local | `/local/path` | None | Direct file copy |

## Security Notes

- SMB credentials are passed in mount options (consider using vault encryption)
- Temporary mount points are created in current directory (`./.tmpmount/`)
- Mount points are automatically cleaned up after operations
- No sudo privileges required - uses user-space mount operations

## Troubleshooting

1. **Mount failures**: Ensure required packages are installed and network connectivity exists
2. **Permission issues**: Role requires sudo/become privileges for mounting
3. **Protocol detection**: Ensure URL includes proper protocol scheme (smb://, nfs://)

## License

MIT

## Author Information

ProxShift - OpenShift cluster management and automation
