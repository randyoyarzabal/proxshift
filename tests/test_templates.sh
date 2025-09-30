#!/bin/bash
# Template validation tests for ProxShift

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Testing Templates...${NC}"

cd "$PROJECT_ROOT"

# Test 1: Template structure validation
echo "Testing template structure..."

TEMPLATE_DIR="ansible_collections/proxshift/openshift/roles/ocp_manifests/templates"

# Check that templates exist and have basic Jinja2 syntax
if [[ -d "$TEMPLATE_DIR" ]]; then
    for template in "$TEMPLATE_DIR"/*.j2; do
        if [[ -f "$template" ]]; then
            template_name=$(basename "$template")
            echo "  Checking $template_name..."
            
            # Check for Jinja2 templating syntax
            if grep -q "{{.*}}" "$template" && grep -q "{%.*%}" "$template"; then
                echo -e "${GREEN}✓${NC} PASS: $template_name contains Jinja2 syntax" 
            elif grep -q "{{.*}}" "$template" || grep -q "{%.*%}" "$template"; then
                echo -e "${GREEN}✓${NC} PASS: $template_name appears to be a Jinja2 template"
            else
                echo -e "${YELLOW}!${NC} WARN: $template_name may not be a Jinja2 template"
            fi
            
            # Check for required template variables (basic validation)
            case "$template_name" in
                "install-config.yaml.j2")
                    if grep -q "cluster_name\|base_domain\|pullSecret" "$template"; then
                        echo -e "${GREEN}✓${NC} PASS: $template_name contains expected variables"
                    else
                        echo -e "${RED}✗${NC} FAIL: $template_name missing expected variables"
                        exit 1
                    fi
                    ;;
                "agent-config.yaml.j2")
                    if grep -q "cluster_name\|macAddress\|hostname" "$template"; then
                        echo -e "${GREEN}✓${NC} PASS: $template_name contains expected variables"
                    else
                        echo -e "${RED}✗${NC} FAIL: $template_name missing expected variables" 
                        exit 1
                    fi
                    ;;
            esac
        fi
    done
else
    echo -e "${YELLOW}!${NC} WARN: Template directory not found at $TEMPLATE_DIR"
fi

# Check ACM import templates
ACM_TEMPLATE_DIR="ansible_collections/proxshift/openshift/roles/acm_import/templates"
if [[ -d "$ACM_TEMPLATE_DIR" ]]; then
    for template in "$ACM_TEMPLATE_DIR"/*.j2; do
        if [[ -f "$template" ]]; then
            template_name=$(basename "$template")
            echo "  Checking ACM template $template_name..."
            
            # Check for Jinja2 templating syntax
            if grep -q "{{.*}}" "$template" || grep -q "{%.*%}" "$template"; then
                echo -e "${GREEN}✓${NC} PASS: ACM $template_name appears to be a Jinja2 template"
            else
                echo -e "${YELLOW}!${NC} WARN: ACM $template_name may not be a Jinja2 template"
            fi
        fi
    done
else
    echo -e "${YELLOW}!${NC} WARN: ACM template directory not found at $ACM_TEMPLATE_DIR"
fi

# Test 2: Template examples validation
echo "Validating example templates..."

EXAMPLE_FILES=(
    "examples/site-config.yaml"
    "examples/vault-credentials.yml" 
    "examples/clusters.yml.template"
)

for example_file in "${EXAMPLE_FILES[@]}"; do
    if [[ -f "$example_file" ]]; then
        echo "  Validating $example_file..."
        
        # Check for placeholder values (should not contain real data)
        if grep -q "your-domain\|your-vault\|your_nfs\|example.com\|192.168.1\." "$example_file"; then
            echo -e "${GREEN}✓${NC} PASS: $example_file contains template placeholders"
        else
            echo -e "${RED}✗${NC} FAIL: $example_file may contain real data instead of placeholders"
            exit 1
        fi
        
        # Validate YAML syntax
        if ansible-inventory -i "$example_file" --list > /dev/null 2>&1 || \
           ansible-playbook --syntax-check <(echo -e "---\n- hosts: localhost\n  vars_files: ['$example_file']") > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} PASS: $example_file has valid YAML syntax"
        else
            echo -e "${RED}✗${NC} FAIL: $example_file has YAML syntax errors"
            exit 1
        fi
    else
        echo -e "${RED}✗${NC} FAIL: Required example file $example_file not found"
        exit 1
    fi
done

echo -e "${GREEN}All template tests passed!${NC}"
