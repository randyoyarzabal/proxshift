#!/bin/bash
# VMForge - Activate proxshift virtual environment and run playbook

# Get the script directory to find the proxshift .venv
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXSHIFT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_PATH="$PROXSHIFT_DIR/.venv"

# Check if virtual environment exists
if [ ! -d "$VENV_PATH" ]; then
    echo "❌ Proxshift virtual environment not found at: $VENV_PATH"
    echo "Please run setup from the proxshift root directory first."
    exit 1
fi

# Activate virtual environment
echo "Activating proxshift virtual environment..."
source "$VENV_PATH/bin/activate"

# Verify activation
if [ -z "$VIRTUAL_ENV" ]; then
    echo "❌ Failed to activate virtual environment"
    exit 1
fi

echo "✅ Virtual environment activated: $VIRTUAL_ENV"
echo "Python: $(which python)"
echo "Ansible: $(which ansible-playbook)"

# Change to vmforge directory
cd "$SCRIPT_DIR"

# Install collections if requirements file exists
if [ -f "collections/requirements.yml" ]; then
    echo "Installing Ansible collections..."
    ansible-galaxy collection install -r collections/requirements.yml --force
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install collections"
        exit 1
    fi
    echo "✅ Collections installed successfully"
fi

# Run the playbook with any arguments passed to the script
if [ $# -eq 0 ]; then
    echo "Running VMForge deployment..."
    echo "Enter vault password when prompted..."
    ansible-playbook site.yaml --ask-vault-pass
else
    echo "Running: ansible-playbook $@"
    ansible-playbook "$@"
fi
