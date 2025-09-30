#!/bin/bash
# Prerequisites test for ProxShift

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing Prerequisites...${NC}"

# Test 1: Ansible version
echo "Checking Ansible version..."
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}✗${NC} FAIL: Ansible not found"
    exit 1
fi

ANSIBLE_VERSION=$(ansible --version | head -n1 | awk '{print $3}')
echo -e "${GREEN}✓${NC} PASS: Ansible $ANSIBLE_VERSION found"

# Test 2: Required collections
echo "Checking Ansible collections..."
REQUIRED_COLLECTIONS=(
    "community.general"
    "community.proxmox" 
    "kubernetes.core"
    "ansible.posix"
)

for collection in "${REQUIRED_COLLECTIONS[@]}"; do
    if ansible-galaxy collection list | grep -q "$collection"; then
        echo -e "${GREEN}✓${NC} PASS: Collection $collection found"
    else
        echo -e "${RED}✗${NC} FAIL: Collection $collection missing"
        echo "  Install with: ansible-galaxy collection install $collection"
        exit 1
    fi
done

# Test 3: jq availability
echo "Checking jq..."
if command -v jq &> /dev/null; then
    echo -e "${GREEN}✓${NC} PASS: jq found"
else
    echo -e "${RED}✗${NC} FAIL: jq not found"
    echo "  Install with: brew install jq (macOS) or dnf install jq (RHEL/CentOS) or yum install jq (older RHEL)"
    exit 1
fi

# Test 4: OpenShift installer (optional check)
echo "Checking OpenShift installer..."
OCP_INSTALLER_PATH="$HOME/bin"
if [[ -x "$OCP_INSTALLER_PATH/openshift-install" ]]; then
    OCP_VERSION=$("$OCP_INSTALLER_PATH/openshift-install" version | head -n1 | awk '{print $2}')
    echo -e "${GREEN}✓${NC} PASS: OpenShift installer $OCP_VERSION found"
else
    echo -e "${YELLOW}!${NC} WARN: OpenShift installer not found at $OCP_INSTALLER_PATH/openshift-install"
    echo "  Download from: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/"
fi

# Test 5: Project structure
echo "Checking project structure..."
REQUIRED_DIRS=(
    "ansible_collections/proxshift"
    "examples"
    "docs"
    "tests"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ -d "$PROJECT_ROOT/$dir" ]]; then
        echo -e "${GREEN}✓${NC} PASS: Directory $dir exists"
    else
        echo -e "${RED}✗${NC} FAIL: Directory $dir missing"
        exit 1
    fi
done

# Check collection structure
echo "Checking collection structure..."
COLLECTION_DIRS=(
    "ansible_collections/proxshift/openshift"
    "ansible_collections/proxshift/proxmox"
    "ansible_collections/proxshift/hashi_vault"
)

for dir in "${COLLECTION_DIRS[@]}"; do
    if [[ -d "$PROJECT_ROOT/$dir" ]]; then
        echo -e "${GREEN}✓${NC} PASS: Collection directory $dir exists"
    else
        echo -e "${RED}✗${NC} FAIL: Collection directory $dir missing"
        exit 1
    fi
done

REQUIRED_FILES=(
    "ansible.cfg"
    "site.yaml"
    "examples/site-config.yaml"
    "examples/vault-credentials.yml"
    "examples/clusters.yml.template"
    "examples/README.md"
    "proxshift.sh"
    "docs/index.md"
    "docs/_config.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$PROJECT_ROOT/$file" ]]; then
        echo -e "${GREEN}✓${NC} PASS: File $file exists"
    else
        echo -e "${RED}✗${NC} FAIL: File $file missing"
        exit 1
    fi
done

echo -e "${GREEN}All prerequisites tests passed!${NC}"
