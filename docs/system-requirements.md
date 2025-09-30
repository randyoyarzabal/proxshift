# System Requirements for ProxShift

## Operating System Packages

ProxShift requires certain system packages to be installed before running the playbooks.

### Linux (RedHat/CentOS/Fedora)
```bash
# Install NFS client utilities
sudo dnf install nfs-utils

# Install CIFS/SMB client utilities  
sudo dnf install cifs-utils

# Install Python package manager
sudo dnf install python3-pip
```

### Linux (Ubuntu/Debian)
```bash
# Install NFS client utilities
sudo apt update
sudo apt install nfs-common

# Install CIFS/SMB client utilities
sudo apt install cifs-utils

# Install Python package manager
sudo apt install python3-pip
```

### macOS (Recommended - Virtual Environment)
```bash
# 1. Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install Python (if not already installed)
brew install python3

# 3. Set up ProxShift environment
cd /path/to/proxshift
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r collections/requirements.yml

# 4. Set environment variables and activate ProxShift
export PROXSHIFT_ROOT=$HOME/dev/proxshift
export PROXSHIFT_VAULT_PASS=${PROXSHIFT_ROOT}/config/.vault_pass

source proxshift.sh  # Load functions
ps.activate          # Activate environment
```

**Note**: macOS has built-in NFS (`/sbin/mount_nfs`) and SMB (`/sbin/mount_smbfs`) support - no additional packages needed!

## Python Dependencies

### Recommended: Virtual Environment (avoids "externally managed" errors)
```bash
cd /path/to/proxshift
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
ansible-galaxy collection install -r collections/requirements.yml
```

### Alternative: Global Installation (may require --break-system-packages)
```bash
# Not recommended - use virtual environment instead
pip3 install -r requirements.txt --break-system-packages
```

## Verification

Verify your system is ready:

```bash
# Check NFS utilities
showmount --version

# Check CIFS utilities (Linux only)
mount.cifs --version

# Check Ansible
ansible --version

# Check Python packages
pip3 list | grep -E "(hvac|proxmoxer|kubernetes)"
```

## Notes

- **No sudo required**: ProxShift ISO copy operations use user-space mounts in `./.tmpmount/`
- **macOS users**: Built-in NFS support is sufficient; CIFS support may require additional configuration
- **Network shares**: Ensure your user has access to the SMB/NFS shares specified in configuration
