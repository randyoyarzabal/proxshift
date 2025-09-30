# VMForge - Generic Linux VM Deployment

VMForge is a flexible Ansible-based system for deploying Linux VMs to Proxmox using qcow2 cloud images. It supports any Linux distribution with cloud-init support and provides automated VM provisioning with custom configurations.

## Prerequisites

1. **Linux QCOW2 Cloud Image**: Any Linux distribution with cloud-init support
2. **Proxmox Access**: API user with VM creation permissions  
3. **SSH Access**: SSH key-based access to Proxmox host
4. **Ansible**: Ansible with community.general collection

## Linux Cloud Images - Download Locations

### Popular Distributions

| Distribution | Download URL | Notes |
|-------------|-------------|-------|
| **Red Hat Enterprise Linux 9** | `https://access.redhat.com/downloads/content/479/ver=/rhel---9/` | Enterprise Linux standard (subscription required) |
| **Rocky Linux 9** | `https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2` | Enterprise-grade RHEL clone |
| **Ubuntu 22.04 LTS** | `https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img` | Popular server distribution |
| **Ubuntu 24.04 LTS** | `https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img` | Latest LTS release |
| **Debian 12** | `https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2` | Stable base distribution |
| **CentOS Stream 9** | `https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2` | Upstream RHEL development |
| **Fedora 40** | `https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2` | Cutting-edge features |
| **OpenSUSE Leap** | `https://download.opensuse.org/repositories/Cloud:/Images:/Leap_15.5/images/openSUSE-Leap-15.5-OpenStack.x86_64.qcow2` | Enterprise SUSE base |
| **Alma Linux 9** | `https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2` | Community RHEL rebuild |

### Verification Commands

```bash
# Download image (example with Rocky Linux)
wget https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2

# Verify qcow2 format
qemu-img info Rocky-9-GenericCloud-Base.latest.x86_64.qcow2

# Check for cloud-init support (should show cloud-init packages)
virt-customize -a image.qcow2 --run-command 'rpm -qa | grep cloud-init' --dry-run
```

## QCOW2 Image Setup (NFS Shared Storage)

### 1. Configure NFS Storage (Required)

You need an NFS storage configured in Proxmox for shared qcow2 images:

- **Storage ID**: Use your NFS storage name (e.g., `nfs-images`, `shared-storage`)
- **Mount point**: Typically `/mnt/pve/your-nfs-storage/`
- **Images directory**: `/mnt/pve/your-nfs-storage/images/`
- **Content types**: Must include **"Disk image"** for qcow2 uploads

**Setup via Proxmox Web UI:**

1. Navigate to **Datacenter** -> **Storage** -> **Add** -> **NFS**
2. Configure your NFS server details and mount path
3. Enable **Content**: `Disk image, ISO image, Container template`

### 2. Download and Upload Linux Cloud Image

1. **Download your chosen distribution** (example with Rocky Linux):

   ```bash
   wget https://download.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
   ```

2. **Upload via Proxmox Web UI**:
   - Navigate to any PVE node -> **your NFS storage**
   - Click **Upload** -> **Content type**: `Disk image`
   - Select the downloaded qcow2 file
   - Upload (will be accessible from all cluster nodes)

**✅ Benefits of NFS Storage:**

- **Cluster-wide access**: Any PVE node can access the images
- **VM migration**: VMs can migrate between nodes seamlessly  
- **Centralized management**: Upload once, use anywhere
- **Backup efficiency**: Single location for all qcow2 images
- **Multi-distro support**: Store multiple Linux distributions
- **Storage path**: Images stored at `/mnt/pve/your-nfs-storage/images/` on all nodes

### 3. Image Selection Guidelines

**Recommended for Production:**

- **Enterprise**: Red Hat Enterprise Linux, Rocky Linux, Alma Linux
- **General Purpose**: Ubuntu LTS, Debian Stable
- **Development**: CentOS Stream, Fedora, Ubuntu non-LTS

**Cloud-init Requirements:**

- All images must include cloud-init package
- Images should support automatic disk expansion
- SSH key injection capability required

### 4. Verify Image Integrity (Optional)

```bash
# For Rocky Linux/RHEL-based
wget https://download.rockylinux.org/pub/rocky/9/images/x86_64/CHECKSUM
sha256sum -c CHECKSUM --ignore-missing

# For Ubuntu
wget https://cloud-images.ubuntu.com/jammy/current/SHA256SUMS
sha256sum -c SHA256SUMS --ignore-missing

# For Debian  
wget https://cloud.debian.org/images/cloud/bookworm/latest/SHA512SUMS
sha512sum -c SHA512SUMS --ignore-missing
```

## Configuration

### 1. Install Dependencies

```bash
cd vmforge
ansible-galaxy collection install -r collections/requirements.yml
```

### 2. Configure Secrets

Either set environment variables:

```bash
export PROXMOX_HOST="your-proxmox-host"
export PROXMOX_USER="api-user@pve"
export PROXMOX_PASSWORD="your-api-password"
export CLOUD_INIT_PASSWORD="your-vm-password"
```

Or edit and encrypt the secrets file:

```bash
# Edit secrets
nano vars/secrets.yaml

# Encrypt secrets  
ansible-vault encrypt vars/secrets.yaml
```

### 3. Configure VM Deployment

Edit `inventory/hosts.yml` to customize your VM:

**Important**: Update `qcow2_image_path` to match your actual NFS storage name configured in Proxmox.

```yaml
# Example configuration
proxmox_vm_config:
  node: pve2                    # Target Proxmox node
  name: my-vm                   # VM hostname
  memory: 8192                  # RAM in MB (8GB)
  cores: 4                      # CPU cores
  # Auto-assigned VM ID (or specify vmid: 200)
  
  # Specify your qcow2 image
  qcow2_image: "your-distro-cloud-image.qcow2"
  qcow2_image_path: "/mnt/pve/your-nfs-storage/images"  # Update to match your NFS storage name
  
  # Network configuration
  cloud_init:
    user: "admin"               # Default user
    password: "{{ cloud_init_pass }}"
    ipconfig: "ip=192.168.1.100/24,gw=192.168.1.1"
    nameservers: [8.8.8.8, 1.1.1.1]
    
  # Storage configuration  
  disks:
    scsi0:
      storage: local-lvm
      size: 50                  # Disk size in GB
```

## Deployment

VMForge uses proxshift's existing virtual environment for consistency:

### 1. Using the activation script (Recommended)

```bash
cd vmforge
./activate_venv.sh
```

### 2. Manual activation

```bash
cd vmforge
source ../.venv/bin/activate
ansible-galaxy collection install -r collections/requirements.yml
ansible-playbook site.yaml
```

### 3. Using custom arguments

```bash
cd vmforge
./activate_venv.sh site.yaml --ask-vault-pass
./activate_venv.sh site.yaml --tags never  # To delete VM
```

### 4. Test Connection (Optional)

```bash
source ../.venv/bin/activate
ansible virtual_machines -m ping
```

## Example Deployment (Current Configuration)

The included example configuration deploys:

- **Distribution**: Rocky Linux 9.6
- **Name**: my-vm.example.com
- **IP**: 192.168.1.100/24
- **Gateway**: 192.168.1.1
- **VLAN**: 50
- **Disk**: 150GB total
- **CPU**: 12 cores
- **RAM**: 32GB
- **Host**: pve2.example.com

**Customize this configuration** in `inventory/hosts.yml` for your environment.

## Network Configuration

The VM will be configured with:

- Bridge: vmbr0
- VLAN tag: 50
- Static IP configuration via cloud-init
- DNS servers: 8.8.8.8, 1.1.1.1

## Post-Deployment Access

After successful deployment, access your VM:

```bash
# SSH using IP address
ssh your-user@vm-ip-address

# SSH using hostname (if DNS configured)
ssh your-user@vm-hostname

# Example (customize for your environment):
ssh admin@192.168.1.100
ssh admin@my-vm.example.com
```

**Default Credentials:**

- **User**: As configured in `cloud_init.user`
- **Password**: As configured in `secrets.yaml`
- **SSH Key**: Automatic injection of your public key (`~/.ssh/id_rsa.pub`)

**Distribution-Specific Default Users:**

- **Red Hat Enterprise Linux**: `cloud-user`, `ec2-user`
- **Rocky/CentOS/Alma**: `rocky`, `centos`, `almalinux`
- **Ubuntu**: `ubuntu`  
- **Debian**: `debian`
- **Fedora**: `fedora`
- **OpenSUSE**: `opensuse`

## Troubleshooting

### Common Issues

1. **QCOW2 Image Not Found**:
   - Verify image is uploaded to your NFS storage via Proxmox web UI
   - Check storage mount: `ls -la /mnt/pve/your-nfs-storage/images/` on any PVE node
   - Ensure your NFS storage has "Disk image" content type enabled
   - Verify qcow2_image filename matches uploaded file exactly

2. **VM ID Conflict**:
   - Remove `vmid:` from inventory to enable auto-assignment
   - Or manually specify unique vmid in inventory/hosts.yml
   - Check existing VMs: `qm list` on target node

3. **Cloud-init Issues**:
   - Verify Linux image includes cloud-init package
   - Check cloud-init logs: `sudo journalctl -u cloud-init`
   - Ensure network configuration is valid for your environment

4. **Network Issues**:
   - Verify VLAN configuration matches your network
   - Check bridge configuration: `ip link show vmbr0`
   - Validate IP range doesn't conflict with existing systems

5. **Permission Errors**:
   - Ensure Proxmox API user has VM creation rights
   - Verify API credentials in secrets.yaml
   - Check storage permissions for target storage

6. **Distribution-Specific Issues**:
   - **Ubuntu/Debian**: May require `sudo apt update` before package operations
   - **RHEL-based**: Ensure subscription or free repos are available
   - **Fedora**: Check for latest image URLs (versions change frequently)

7. **Storage Issues**:
   - **NFS**: Check NFS server accessibility: `showmount -e your-nfs-server`
   - **Local**: Verify sufficient space: `df -h /var/lib/vz`
   - **LVM**: Check volume group space: `vgs`

### Debug Commands

```bash
# Check VM status
qm status <vmid>

# View VM configuration  
qm config <vmid>

# Monitor cloud-init progress
tail -f /var/log/cloud-init-output.log

# Test network connectivity
ping <vm-ip-address>
nslookup <vm-hostname>
```

## File Structure

```text
vmforge/
|-- ansible.cfg              # Ansible configuration
|-- site.yaml               # Main deployment playbook
|-- README.md               # This documentation
|-- activate_venv.sh        # Deployment activation script
|-- collections/
|   `-- requirements.yml    # Required Ansible collections
|-- inventory/
|   `-- hosts.yml          # VM configuration and inventory
`-- vars/
    |-- vmforge_config.yaml # General VMForge configuration
    `-- secrets.yaml        # Encrypted credentials (vault)
```

## Features

✅ **Multi-Distribution Support**: Deploy any Linux distro with cloud-init  
✅ **Automated VM ID Assignment**: Avoids conflicts with existing VMs/containers  
✅ **QCOW2 Import & Resize**: Automatic disk image import and expansion  
✅ **Cloud-init Integration**: User, SSH keys, network, and hostname configuration  
✅ **NFS Storage Support**: Cluster-wide image sharing and management  
✅ **Security**: Ansible Vault encrypted credentials  
✅ **Reusable**: Template-based approach for consistent deployments  
✅ **Proxshift Integration**: Uses existing proxshift virtual environment
