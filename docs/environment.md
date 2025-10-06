# ProxShift Environment Guide

Comprehensive guide for setting up and managing your ProxShift development environment.

## Virtual Environment Setup

### Why Use Virtual Environments?

ProxShift uses Python virtual environments to:
- **Avoid conflicts** with system Python packages
- **Prevent "pip externally managed" errors** on modern systems
- **Ensure consistent dependencies** across different environments
- **Isolate ProxShift dependencies** from other projects

### Quick Setup

```bash
cd /path/to/proxshift

# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
ansible-galaxy collection install -r collections/requirements.yml

# Use ProxShift
source proxshift.sh  # Auto-activates venv
ps.clusters          # Ready to use!
```

### Automatic Environment Activation

ProxShift includes automatic environment setup:

```bash
# Simply source proxshift.sh
source proxshift.sh

# Output:
# Activating ProxShift virtual environment...
# ✓ Virtual environment activated: Python 3.13.7
```

**What happens automatically:**
1. ✓ Detects `.venv` directory
2. ✓ Activates virtual environment  
3. ✓ Verifies Ansible is available
4. ✓ Loads all ProxShift functions
5. ✓ Shows helpful error messages if issues found

## Environment Variables

### Core Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PROXSHIFT_ROOT` | `$(pwd)` | ProxShift installation directory |
| `PROXSHIFT_VAULT_PASS` | `${PROXSHIFT_ROOT}/config/.vault_pass` | Ansible vault password file |
| `VAULT_ADDR` | From config | HashiCorp Vault address |
| `VAULT_TOKEN` | From config | HashiCorp Vault token |

### Setting Environment Variables

```bash
# Option 1: Export in shell
export PROXSHIFT_ROOT="/Users/username/proxshift"
export VAULT_ADDR="https://vault.example.com:8200"

# Option 2: Add to ~/.bashrc or ~/.zshrc
echo 'export PROXSHIFT_ROOT="/Users/username/proxshift"' >> ~/.bashrc
echo 'export VAULT_ADDR="https://vault.example.com:8200"' >> ~/.bashrc

# Option 3: Use .env file (create in ProxShift root)
cat > .env << EOF
PROXSHIFT_ROOT="/Users/username/proxshift"
VAULT_ADDR="https://vault.example.com:8200"
VAULT_TOKEN="your-token-here"
EOF

# Load .env file
set -a; source .env; set +a
```

## Directory Structure

```
proxshift/
├── .venv/                      # Virtual environment (auto-created)
├── proxshift.sh               # Main ProxShift functions
├── config/
│   ├── site-config.yaml       # Site configuration
│   └── vault-credentials.yml  # Vault settings
├── inventory/                 # Cluster inventory definitions
│   └── clusters.yml           # All cluster definitions
├── ocp_install/               # Generated ISOs and credentials
│   ├── cluster1/
│   └── cluster2/
├── ansible_collections/       # ProxShift roles and collections
└── docs/                      # Documentation
```

## Daily Workflow

### Starting a Session

```bash
# Standard workflow
cd /path/to/proxshift

# Set required environment variables (examples only - adjust paths)
export PROXSHIFT_ROOT=$HOME/dev/proxshift
export PROXSHIFT_VAULT_PASS=${PROXSHIFT_ROOT}/config/.vault_pass

source proxshift.sh  # Load functions
ps.activate          # Activate environment

# Alternative: Manual activation (advanced users)
cd /path/to/proxshift
export PROXSHIFT_ROOT=$HOME/dev/proxshift
export PROXSHIFT_VAULT_PASS=${PROXSHIFT_ROOT}/config/.vault_pass
source .venv/bin/activate
source proxshift.sh
```

### Working with Clusters

```bash
# List available clusters
ps.clusters

# Provision a cluster
ps.provision ocp-sno1

# Generate manifests only
ps.generate_manifests ocp-sno1

# Create ISO only
ansible-playbook site.yaml -e cluster_name=ocp-sno1 --tags=create_iso
```

### Ending a Session

```bash
# Deactivate virtual environment (optional)
deactivate

# Or simply close terminal
```

## Troubleshooting

### Virtual Environment Issues

```bash
# Problem: "pip externally managed"
# Solution: Use virtual environment
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Problem: Virtual environment corrupted
# Solution: Recreate virtual environment
rm -rf .venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Problem: Wrong Python version in venv
# Solution: Specify Python version
python3.11 -m venv .venv  # Use specific version
source .venv/bin/activate
pip install -r requirements.txt
```

### Environment Detection Issues

```bash
# Problem: proxshift.sh doesn't find venv
# Solution: Ensure you're in the right directory
pwd  # Should show /path/to/proxshift
ls -la .venv  # Should show virtual environment directory

# Problem: Ansible not found after activation
# Solution: Reinstall in virtual environment
source .venv/bin/activate
pip install -r requirements.txt
ansible --version  # Should show version
```

### Path Issues

```bash
# Problem: Can't find OpenShift tools
# Solution: Add to PATH or specify full path
export PATH="$HOME/bin:$PATH"
which openshift-install

# Problem: Wrong PROXSHIFT_ROOT
# Solution: Set explicitly
export PROXSHIFT_ROOT="/correct/path/to/proxshift"
cd $PROXSHIFT_ROOT
source proxshift.sh
```

## Shell Integration

### Bash Integration

Add to `~/.bashrc`:

```bash
# ProxShift environment
export PROXSHIFT_ROOT="/path/to/proxshift"
alias ps.env='cd $PROXSHIFT_ROOT && source proxshift.sh'
alias ps.activate='cd $PROXSHIFT_ROOT && source .venv/bin/activate'
```

### Zsh Integration

Add to `~/.zshrc`:

```bash
# ProxShift environment
export PROXSHIFT_ROOT="/path/to/proxshift"
alias ps.env='cd $PROXSHIFT_ROOT && source proxshift.sh'
alias ps.activate='cd $PROXSHIFT_ROOT && source .venv/bin/activate'

# Tab completion for ProxShift functions
autoload -U compinit && compinit
```

### Fish Shell Integration

Add to `~/.config/fish/config.fish`:

```fish
# ProxShift environment
set -gx PROXSHIFT_ROOT "/path/to/proxshift"
alias ps.env "cd $PROXSHIFT_ROOT && source proxshift.sh"
alias ps.activate "cd $PROXSHIFT_ROOT && source .venv/bin/activate"
```

## Advanced Configuration

### Custom Python Path

```bash
# Use specific Python version
/usr/local/bin/python3.11 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Offline Installation

```bash
# Download packages
pip download -r requirements.txt -d ./offline-packages

# Install from downloaded packages
pip install --no-index --find-links ./offline-packages -r requirements.txt
```

### Development Mode

```bash
# Install development dependencies
pip install -r requirements.txt
pip install ansible-lint yamllint

# Install ProxShift collections in development mode
cd ansible_collections/proxshift
ansible-galaxy collection build .
ansible-galaxy collection install *.tar.gz --force
```

---

**ProxShift** - Seamless OpenShift on Proxmox