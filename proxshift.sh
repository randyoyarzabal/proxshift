#!/usr/bin/env bash
# ProxShift - OpenShift Proxmox Automation
# Provision OpenShift clusters on Proxmox with minimal setup

# ProxShift Environment Setup
# Note: Environment is not automatically activated. Use ps.activate function.

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
  echo "Error: ProxShift must be sourced, not executed directly."
  echo "Usage: source proxshift.sh"
  echo ""
  echo "Environment setup:"
  echo "  ps.activate               - Activate ProxShift environment"
  echo ""
  echo "Main functions:"
  echo "  ps.provision <cluster>     - Provision a complete cluster"
  echo "  ps.generate_manifests     - Generate install manifests only"
  echo "  ps.clusters               - List available clusters"
  echo "  ps.validate_cluster       - Validate cluster exists"
  echo ""
  echo "Add --dry-run to any operation to preview commands"
  exit 1
fi

# ProxShift Environment Configuration
# Set these environment variables or they'll use sensible defaults
export PROXSHIFT_ROOT="${PROXSHIFT_ROOT:-$(pwd)}"
export PROXSHIFT_VAULT_PASS="${PROXSHIFT_VAULT_PASS:-${HOME}/.proxshift/.vault_pass}"

function ps.activate() {
  echo "Activating ProxShift environment..."
  
  # Create and activate virtual environment if it doesn't exist
  if [[ -f ".venv/bin/activate" ]]; then
    echo "Activating existing virtual environment..."
    source .venv/bin/activate
    echo "✓ Virtual environment activated: $(python --version)"
  else
    echo "🔧 Virtual environment not found. Creating new environment..."
    
    # Create virtual environment
    if ! python3 -m venv .venv; then
      echo "✗ Failed to create virtual environment"
      echo "   Make sure python3 is installed and accessible"
      return 1
    fi
    
    # Activate virtual environment
    source .venv/bin/activate
    echo "✓ Virtual environment created and activated: $(python --version)"
    
    # Upgrade pip
    echo "🔧 Upgrading pip..."
    pip install --upgrade pip
    
    # Install requirements
    if [[ -f "requirements.txt" ]]; then
      echo "🔧 Installing Python dependencies..."
      if ! pip install -r requirements.txt; then
        echo "✗ Failed to install Python dependencies"
        return 1
      fi
      echo "✓ Python dependencies installed"
    else
      echo "⚠ requirements.txt not found, skipping Python dependencies"
    fi
    
    # Install Ansible collections
    if [[ -f "collections/requirements.yml" ]]; then
      echo "🔧 Installing Ansible collections..."
      if ! ansible-galaxy collection install -r collections/requirements.yml; then
        echo "✗ Failed to install Ansible collections"
        return 1
      fi
      echo "✓ Ansible collections installed"
    else
      echo "⚠ collections/requirements.yml not found, skipping Ansible collections"
    fi
  fi
  
  # Verify required tools
  if ! command -v ansible >/dev/null 2>&1; then
    echo "✗ Ansible not found after setup"
    echo "   This shouldn't happen. Please check your Python environment."
    return 1
  fi
  
  echo "✓ Ansible available: $(ansible --version | head -1)"
  echo "Working Directory: $PROXSHIFT_ROOT"
  echo ""
  echo "Environment Variables:"
  echo "   PROXSHIFT_ROOT=$PWD"
  echo "   PROXSHIFT_VAULT_PASS=${PROXSHIFT_VAULT_PASS}"
  echo ""
  echo "Usage:"
  echo "   ps.provision <cluster>            # Provision complete cluster"
  echo "   ps.provision <cluster> --dry-run  # Preview actions"
  echo "   ps.provision --help               # Show detailed help"
  echo "   ps.clusters                       # List available clusters"
  echo ""
  echo "✓ ProxShift environment ready!"
}

function ps.root() {
  cd "${PROXSHIFT_ROOT}" || { echo "✗ Error: Cannot change to PROXSHIFT_ROOT directory"; return 1; }
}

# Utility functions
function _ps.get_gitops_root() {
  local config_file="${HOME}/.proxshift/site-config.yaml"
  if [[ -f "$config_file" ]]; then
    # Extract gitops_root value from YAML, handling quoted paths
    grep "^gitops_root:" "$config_file" | sed 's/^gitops_root: *"\?\([^"]*\)"\?/\1/'
  else
    # Fallback to environment variable or default
    echo "${PROXSHIFT_GITOPS_ROOT:-${HOME}/gitops}"
  fi
}

function ps.clusters() {
  _ps.parse_dry_run "$@"
  
  if [[ "$_ps_dry_run" == "true" ]]; then
    echo " DRY RUN - Would list available clusters:"
    echo "   Source: inventory/clusters.yml"
    echo "   Method: ansible-inventory --list + jq parsing"
    echo "   Fallback: grep parsing of clusters.yml"
    echo ""
    echo " To execute, remove --dry-run/-n flag"
    return 0
  fi
  
  if [[ "$_ps_check_mode" == "true" ]]; then
    echo "⚠  --check mode not supported for ps.clusters (no Ansible operations)"
    echo "   Use --dry-run/-n to preview behavior instead"
    return 1
  fi
  
  ps.root
  echo "Available clusters:"
  # Use a more reliable method that doesn't depend on ansible-inventory
  if command -v ansible-inventory >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    ansible-inventory --list 2>/dev/null | jq -r '.clusters.children[]' 2>/dev/null || _ps.list_clusters_fallback
  else
    _ps.list_clusters_fallback
  fi
}

# Fallback method to list clusters directly from YAML
function _ps.list_clusters_fallback() {
  if [[ -f "inventory/clusters.yml" ]]; then
    grep -E "^\s+[a-z][a-z0-9-]+:$" "inventory/clusters.yml" | \
    grep -v "children\|vars\|hosts" | \
    sed "s/://g" | \
    awk '{print $1}' | \
    grep -E "^(ocp|ocp-)" | \
    grep -v "node"
  else
    echo "Error: Cannot read inventory"
  fi
}

function ps.validate_cluster() {
  local cluster=$1
  if [[ -z "$cluster" ]]; then
    echo "✗ Error: No cluster specified"
    ps.clusters
    return 1
  fi
  
  # Use reliable validation method
  ps.root
  local cluster_found=false
  
  # Try ansible-inventory first, fallback to direct YAML parsing
  if command -v ansible-inventory >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    if ansible-inventory --list 2>/dev/null | jq -r '.clusters.children[]' 2>/dev/null | grep -q "^${cluster}$"; then
      cluster_found=true
    fi
  fi
  
  # Fallback method if ansible-inventory failed
  if [[ "$cluster_found" == "false" ]]; then
    if [[ -f "inventory/clusters.yml" ]] && grep -E "^\s+${cluster}:$" "inventory/clusters.yml" >/dev/null 2>&1; then
      cluster_found=true
    fi
  fi
  
  if [[ "$cluster_found" == "false" ]]; then
    echo "✗ Error: Cluster '${cluster}' not found in inventory"
    ps.clusters
    return 1
  fi
}

# Modern ProxShift functions with ps.* naming

# Helper function to parse dry-run flags from arguments
function _ps.parse_dry_run() {
  local args=("$@")
  local dry_run=false
  local check_mode=false
  local show_help=false
  local filtered_args=()
  
  for arg in "${args[@]}"; do
    if [[ "$arg" == "--dry-run" || "$arg" == "-n" ]]; then
      dry_run=true
    elif [[ "$arg" == "--check" || "$arg" == "-c" ]]; then
      check_mode=true
    elif [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
      show_help=true
    else
      filtered_args+=("$arg")
    fi
  done
  
  # Return results via global variables (bash limitation)
  _ps_dry_run="$dry_run"
  _ps_check_mode="$check_mode"
  _ps_show_help="$show_help"
  _ps_filtered_args=("${filtered_args[@]}")
}

# Helper function for ansible-playbook execution with consistent setup
function _ps.run_ansible() {
  local cluster="$1"
  local tags="$2"
  local skip_tags="$3"
  local extra_args="$4"
  local show_timing="${5:-false}"
  local force_install="${6:-false}"
  local dry_run="${7:-false}"
  local check_mode="${8:-false}"
  
  # Validate cluster if provided
  if [[ -n "$cluster" ]]; then
    ps.validate_cluster "$cluster" || return 1
  fi
  
  ps.root
  local save_env_set=false
  if [[ -n "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ]]; then
    local save_env=$ANSIBLE_VAULT_PASSWORD_FILE
    save_env_set=true
  fi
  
  # Check if ansible is available
  if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "✗ Ansible not found. ProxShift environment not activated."
    echo "   Run: ps.activate"
    return 1
  fi
  
  # Only set vault password file if it exists, otherwise let ansible prompt
  if [[ -n "$PROXSHIFT_VAULT_PASS" ]] && [[ -f "$PROXSHIFT_VAULT_PASS" ]]; then
    export ANSIBLE_VAULT_PASSWORD_FILE=$PROXSHIFT_VAULT_PASS
  elif [[ -n "$PROXSHIFT_VAULT_PASS" ]]; then
    echo "⚠ Vault password file not found: $PROXSHIFT_VAULT_PASS"
    echo "   Ansible will prompt for vault password interactively"
  else
    echo "⚠ PROXSHIFT_VAULT_PASS not defined"
    echo "   Ansible will prompt for vault password interactively"
    echo "   Set: export PROXSHIFT_VAULT_PASS=${HOME}/.proxshift/.vault_pass"
  fi
  
  # Start timing if requested (only for actual runs)
  if [[ "$show_timing" == "true" && "$dry_run" == "false" ]]; then
    SECONDS=0
  fi
  
  # Build command
  local cmd="ansible-playbook site.yaml"
  [[ -n "$cluster" ]] && cmd="$cmd -e cluster_name=${cluster}"
  [[ "$force_install" == "true" ]] && cmd="$cmd -e force_install=true"
  [[ -n "$tags" ]] && cmd="$cmd --tags=${tags}"
  [[ -n "$skip_tags" ]] && cmd="$cmd --skip-tags=${skip_tags}"
  [[ "$check_mode" == "true" ]] && cmd="$cmd --check"
  [[ -n "$extra_args" ]] && cmd="$cmd $extra_args"
  
  # Execute command based on mode
  if [[ "$dry_run" == "true" ]]; then
    echo " DRY RUN - Command that would be executed:"
    echo "   $cmd"
    echo ""
    echo " To execute, remove --dry-run/-n flag"
    local exit_code=0
  elif [[ "$check_mode" == "true" ]]; then
    echo " CHECK MODE - Running ansible-playbook with --check flag:"
    echo "   $cmd"
    echo ""
    eval "$cmd"
    local exit_code=$?
  else
    echo "$cmd"
    eval "$cmd"
    local exit_code=$?
  fi
  
  # Show timing if requested (only for actual runs)
  if [[ "$show_timing" == "true" && "$dry_run" == "false" ]]; then
    local duration=$SECONDS
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    echo "Run took: ${minutes}:${seconds}"
  fi
  
  # Restore environment
  if [[ "$save_env_set" == "true" ]]; then
    export ANSIBLE_VAULT_PASSWORD_FILE=$save_env
  else
    unset ANSIBLE_VAULT_PASSWORD_FILE
  fi
  return $exit_code
}

# Simplified functions using the helper
function ps.deprovision(){
  _ps.parse_dry_run "$@"
  _ps.run_ansible "${_ps_filtered_args[0]}" "vm_delete" "" "" false false "$_ps_dry_run" "$_ps_check_mode"
}

function ps.start(){
  _ps.parse_dry_run "$@"
  _ps.run_ansible "${_ps_filtered_args[0]}" "vm_start" "" "" false false "$_ps_dry_run" "$_ps_check_mode"
}

function ps.post(){
  _ps.parse_dry_run "$@"
  _ps.run_ansible "${_ps_filtered_args[0]}" "post,restore,vault,gitops,storage" "" "" false false "$_ps_dry_run" "$_ps_check_mode"
}

function ps.acm_import(){
  _ps.parse_dry_run "$@"
  _ps.run_ansible "${_ps_filtered_args[0]}" "acm_import" "backup,restore" "" false false "$_ps_dry_run" "$_ps_check_mode"
}

function ps.backup_certs(){
  _ps.parse_dry_run "$@"
  local gitops_root="$(_ps.get_gitops_root)"
  echo " Backing up certificate secrets from EXISTING cluster: ocp-sno1"
  echo "   Operation: standalone backup (not part of provisioning)"
  echo "   Target cluster: ocp-sno1 (must be running)"
  echo ""
  echo " Secrets to backup:"
  echo "   - secret-homelab-ca-tls (cert-manager namespace)"
  echo "   - secret-homelab-io-tls (homelab namespace)"
  echo ""
  echo " Backup destination: ${gitops_root}/backups/"
  echo "   Files will be created:"
  echo "   - cert-manager-secret-homelab-ca-tls.yaml"
  echo "   - homelab-secret-homelab-io-tls.yaml"
  echo ""
  _ps.run_ansible "ocp-sno1" "cert_backup" "" "-e backup_operation=true" false false "$_ps_dry_run" "$_ps_check_mode"
  
  if [[ "$_ps_dry_run" == "false" && $? -eq 0 ]]; then
    echo ""
    echo "✓ Certificate backup completed successfully!"
    echo " Backup files created:"
    echo "   - ${gitops_root}/backups/cert-manager-secret-homelab-ca-tls.yaml"
    echo "   - ${gitops_root}/backups/homelab-secret-homelab-io-tls.yaml"
    echo ""
    echo " Certificates are now safely backed up from cluster: ocp-sno1"
  fi
}

function ps.restore_certs(){
  _ps.parse_dry_run "$@"
  local gitops_root="$(_ps.get_gitops_root)"
  echo "  Restoring certificate secrets to REBUILT cluster: ocp-sno1"
  echo "   Operation: restore during cluster rebuild/post-install"
  echo "   Target cluster: ocp-sno1 (must be freshly provisioned)"
  echo ""
  echo " Secrets to restore:"
  echo "   - secret-homelab-ca-tls → cert-manager namespace"
  echo "   - secret-homelab-io-tls → homelab namespace"
  echo ""
  echo " Restore source: ${gitops_root}/backups/"
  echo "   Reading from files:"
  echo "   - cert-manager-secret-homelab-ca-tls.yaml"
  echo "   - homelab-secret-homelab-io-tls.yaml"
  echo ""
  _ps.run_ansible "ocp-sno1" "post,cert_restore" "" "-e restore_operation=true" false false "$_ps_dry_run" "$_ps_check_mode"
  
  if [[ "$_ps_dry_run" == "false" && $? -eq 0 ]]; then
    echo ""
    echo "✓ Certificate restore completed successfully!"
    echo "🔑 Secrets restored to cluster: ocp-sno1"
    echo "   - secret-homelab-ca-tls → cert-manager namespace"
    echo "   - secret-homelab-io-tls → homelab namespace"
    echo ""
    echo " Certificates are now available in the rebuilt cluster"
  fi
}

function ps.gitops_loop(){
  _ps.parse_dry_run "$@"
  _ps.run_ansible "ocp-sno1" "gitops_loop" "" "" false false "$_ps_dry_run" "$_ps_check_mode"
}

function ps.gitops(){
  _ps.parse_dry_run "$@"
  _ps.run_ansible "${_ps_filtered_args[0]}" "gitops" "" "" false false "$_ps_dry_run" "$_ps_check_mode"
}

function ps.vault(){
  _ps.parse_dry_run "$@"
  _ps.run_ansible "${_ps_filtered_args[0]}" "vault" "" "" false false "$_ps_dry_run" "$_ps_check_mode"
}


function ps.generate_manifests(){
  _ps.parse_dry_run "$@"
  local cluster="${_ps_filtered_args[0]:-}"
  
  if [[ -z "$cluster" ]]; then
    echo "✗ Error: No cluster specified"
    echo "Usage: ps.generate_manifests <cluster_name> [--dry-run|-n|--check|-c]"
    echo "Available clusters:"
    ps.clusters
    return 1
  fi
  
  echo " Generating OpenShift manifests for: $cluster"
  echo "   Output directory: ocp_install/$cluster/"
  echo "   Files: install-config.yaml, agent-config.yaml (with .bak copies)"
  echo ""
  
  # Run only what's needed: vault retrieval + manifest generation
  local extra_args="-e force_install=true"
  _ps.run_ansible "$cluster" "always,manifests" "" "$extra_args" false false "$_ps_dry_run" "$_ps_check_mode"
  
  if [[ "$_ps_dry_run" == "false" && $? -eq 0 ]]; then
    echo ""
    echo "✓ Manifest generation completed successfully!"
    echo " Generated files:"
    echo "   - ocp_install/$cluster/install-config.yaml"
    echo "   - ocp_install/$cluster/agent-config.yaml"
    echo ""
    echo " Note: Backup files (.bak) created for record-keeping"
    echo " Use 'ps.provision $cluster' to proceed with full cluster provisioning"
  fi
}

# Legacy function removed - use ps.generate_manifests instead

function ps.force(){
  _ps.parse_dry_run "$@"  # Parse all args consistently  
  local cluster="${_ps_filtered_args[0]:-}"
  local skip_restore="backup"
  # Special case: ocp-sno1 allows restore
  if [[ ${cluster} == 'ocp-sno1' ]]; then
    skip_restore="backup"
  else
    skip_restore="backup,restore"
  fi
  _ps.run_ansible "$cluster" "" "$skip_restore" "${_ps_filtered_args[*]:1}" true true "$_ps_dry_run" "$_ps_check_mode"
}

function ps.force_nohub(){
  _ps.parse_dry_run "$@"  # Parse all args consistently
  local cluster="${_ps_filtered_args[0]:-}"
  _ps.run_ansible "$cluster" "" "backup,restore,acm_import" "${_ps_filtered_args[*]:1}" true true "$_ps_dry_run" "$_ps_check_mode"
}

function ps.force_blank(){
  _ps.parse_dry_run "$@"  # Parse all args consistently  
  local cluster="${_ps_filtered_args[0]:-}"
  _ps.run_ansible "$cluster" "" "backup,restore,hub,post,acm_import,gitops" "${_ps_filtered_args[*]:1}" true true "$_ps_dry_run" "$_ps_check_mode"
}

function ps.provision() {
  _ps.parse_dry_run "$@"  # Parse all args consistently
  
  # Handle help flag
  if [[ "$_ps_show_help" == "true" ]]; then
    echo "ps.provision - Provision a complete OpenShift cluster"
    echo ""
    echo "Usage: ps.provision <cluster_name> [options]"
    echo ""
    echo "Arguments:"
    echo "  <cluster_name>    Name of the cluster to provision (required)"
    echo ""
    echo "Options:"
    echo "  --dry-run, -n     Preview actions without execution"
    echo "  --check, -c       Run Ansible in check mode (dry-run)"
    echo "  --help, -h        Show this help message"
    echo ""
    echo "Examples:"
    echo "  ps.provision ocp-sno1              # Provision cluster ocp-sno1"
    echo "  ps.provision ocp-sno1 --dry-run    # Preview provisioning actions"
    echo "  ps.provision ocp3 --check          # Check mode (Ansible dry-run)"
    echo ""
    ps.clusters
    return 0
  fi
  
  local cluster="${_ps_filtered_args[0]:-}"
  ps.validate_cluster "$cluster" || return 1
  if [[ "$_ps_dry_run" == "true" ]]; then
    echo " DRY RUN - Would provision cluster: $cluster"
    echo "   Equivalent to: ps.force $cluster ${_ps_filtered_args[*]:1}"
    echo "   Use --dry-run/-n to preview actions"
    echo ""
  else
    echo " Provisioning cluster: $cluster"
  fi
  # Pass through the appropriate flag
  local flag=""
  [[ "$_ps_dry_run" == "true" ]] && flag="--dry-run"
  [[ "$_ps_check_mode" == "true" ]] && flag="--check"
  ps.force "$cluster" "${_ps_filtered_args[@]:1}" "$flag"
}

function ps.install_watch () {
  _ps.parse_dry_run "$@"
  local cluster="${_ps_filtered_args[0]:-}"
  local gitops_root="${PROXSHIFT_GITOPS_ROOT:-${HOME}/gitops}"
  
  if [[ -z "$cluster" ]]; then
    echo "✗ Error: No cluster specified"
    echo "Usage: ps.install_watch <cluster_name> [--dry-run|-n]"
    echo "Available clusters:"
    ps.clusters
    return 1
  fi
  
  if [[ "$_ps_dry_run" == "true" ]]; then
    echo " DRY RUN - Would monitor installation for cluster: $cluster"
    echo "   Directory: ocp_install/$cluster"
    echo "   Command: openshift-install agent wait-for install-complete --dir=\"ocp_install/$cluster\" --log-level=debug"
    echo "   Function: Monitor OpenShift installation until completion"
    echo ""
    echo " To execute, remove --dry-run/-n flag"
    return 0
  fi
  
  if [[ "$_ps_check_mode" == "true" ]]; then
    echo "⚠  --check mode not supported for ps.install_watch (not an Ansible operation)"
    echo "   Use --dry-run/-n to preview behavior instead"
    return 1
  fi
  
  if [[ -d "${gitops_root}/.ansible" ]]; then
    cd "${gitops_root}/.ansible" || { echo "✗ Error: Cannot change to GitOps directory"; return 1; }
  else
    echo "⚠  GitOps directory not found: ${gitops_root}/.ansible"
    echo "   Set PROXSHIFT_GITOPS_ROOT environment variable or create the directory"
    ps.root
  fi
  
  echo " Monitoring OpenShift installation for cluster: $cluster"
  echo "   Install directory: ocp_install/$cluster"
  echo "   This will wait until installation completes..."
  echo ""
  
  openshift-install agent wait-for install-complete --dir="ocp_install/$cluster" --log-level=debug
}
