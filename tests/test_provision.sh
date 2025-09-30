#!/bin/bash
# Test script for ps.provision ocp-sno3

set -e

echo "🚀 Testing ProxShift Collection Integration with ocp-sno3 provisioning"
echo "=================================================================="

export PROXSHIFT_ROOT="/Users/royarzab/dev/ocp_proxmox"
export PROXSHIFT_VAULT_PASS="${PROXSHIFT_ROOT}/config/.vault_pass"

cd "$PROXSHIFT_ROOT"

# Load functions in clean environment
source proxshift.sh

echo "📋 Available clusters:"
ps.clusters

echo ""
echo "🚀 Starting provision test for ocp-sno3..."
echo "⚠️  This will take several minutes to complete"

ps.provision ocp-sno3
