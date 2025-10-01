#!/usr/bin/env bash
# ProxShift - OpenShift Proxmox Automation
# Provision OpenShift clusters on Proxmox with minimal setup

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
  echo "Error: ProxShift must be sourced, not executed directly."
  echo "Usage: source tools/ocp_pm.sh"
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
export PROXSHIFT_VAULT_PASS="${PROXSHIFT_VAULT_PASS:-${PROXSHIFT_ROOT}/config/.vault_pass}"

function ps.root() {
  cd "${PROXSHIFT_ROOT}" || { echo "❌ Error: Cannot change to PROXSHIFT_ROOT directory"; return 1; }
}

# Utility functions
function ps.clusters() {
  ps.root
  echo "Available clusters:"
  # Use a more reliable method that doesn't depend on ansible-inventory
  if command -v jq >/dev/null 2>&1; then
    ansible-inventory --list 2>/dev/null | jq -r '.clusters.children[]' 2>/dev/null || _ps.list_clusters_fallback
  else
    _ps.list_clusters_fallback
  fi
}

# Fallback method to list clusters directly from YAML
function _ps.list_clusters_fallback() {
  if [[ -f "inventory/clusters.yml" ]]; then
    grep -E "^\s+[a-z][a-z0-9-]+:$" inventory/clusters.yml | \
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
    echo "❌ Error: No cluster specified"
    ps.clusters
    return 1
  fi
  
  # Use reliable validation method
  ps.root
  local cluster_found=false
  
  # Try ansible-inventory first, fallback to direct YAML parsing
  if command -v jq >/dev/null 2>&1; then
    if ansible-inventory --list 2>/dev/null | jq -r '.clusters.children[]' 2>/dev/null | grep -q "^${cluster}$"; then
      cluster_found=true
    fi
  fi
  
  # Fallback method if ansible-inventory failed
  if [[ "$cluster_found" == "false" ]]; then
    if [[ -f "inventory/clusters.yml" ]] && grep -E "^\s+${cluster}:$" inventory/clusters.yml >/dev/null 2>&1; then
      cluster_found=true
    fi
  fi
  
  if [[ "$cluster_found" == "false" ]]; then
    echo "❌ Error: Cluster '${cluster}' not found in inventory"
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
  
  # Only set vault password file if it exists, otherwise let ansible prompt
  if [[ -f "$PROXSHIFT_VAULT_PASS" ]]; then
    export ANSIBLE_VAULT_PASSWORD_FILE=$PROXSHIFT_VAULT_PASS
  else
    echo "⚠️  Vault password file not found: $PROXSHIFT_VAULT_PASS"
    echo "   Ansible will prompt for vault password interactively"
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
    echo "🧪 DRY RUN - Command that would be executed:"
    echo "   $cmd"
    echo ""
    echo "💡 To execute, remove --dry-run/-n flag"
    local exit_code=0
  elif [[ "$check_mode" == "true" ]]; then
    echo "🔍 CHECK MODE - Running ansible-playbook with --check flag:"
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
  _ps.run_ansible "${_ps_filtered_args[0]}" "acm,acm_import" "backup,restore" "" false false "$_ps_dry_run" "$_ps_check_mode"
}

function ps.backup_certs(){
  _ps.parse_dry_run "$@"
  _ps.run_ansible "ocp-sno1" "post,backup" "" "" false false "$_ps_dry_run" "$_ps_check_mode"
}

function ps.restore_certs(){
  _ps.parse_dry_run "$@"
  _ps.run_ansible "ocp-sno1" "post,restore" "" "" false false "$_ps_dry_run" "$_ps_check_mode"
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
    echo "❌ Error: No cluster specified"
    echo "Usage: ps.generate_manifests <cluster_name> [--dry-run|-n]"
    echo "Available clusters:"
    ps.clusters
    return 1
  fi
  
  echo "📄 Generating OpenShift manifests for: $cluster"
  echo "   Output directory: ocp_install/$cluster/"
  echo "   Files: install-config.yaml, agent-config.yaml (with .bak copies)"
  echo ""
  
  # Run only what's needed: vault retrieval + manifest generation
  local extra_args="-e force_install=true"
  _ps.run_ansible "$cluster" "always,manifests" "" "$extra_args" false false "$_ps_dry_run" "$_ps_check_mode"
  
  if [[ "$_ps_dry_run" == "false" && $? -eq 0 ]]; then
    echo ""
    echo "✅ Manifest generation completed successfully!"
    echo "📂 Generated files:"
    echo "   - ocp_install/$cluster/install-config.yaml"
    echo "   - ocp_install/$cluster/agent-config.yaml"
    echo ""
    echo "💡 Note: Backup files (.bak) created for record-keeping"
    echo "💡 Use 'ps.provision $cluster' to proceed with full cluster provisioning"
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
    echo "🚀 DRY RUN - Would provision cluster: $cluster"
    echo "   Equivalent to: ps.force $cluster ${_ps_filtered_args[*]:1}"
    echo ""
  else
    echo "🚀 Provisioning cluster: $cluster"
  fi
  # Pass through the appropriate flag
  local flag=""
  [[ "$_ps_dry_run" == "true" ]] && flag="--dry-run"
  [[ "$_ps_check_mode" == "true" ]] && flag="--check"
  ps.force "$cluster" "${_ps_filtered_args[@]:1}" "$flag"
}

function ps.install_watch () {
  local gitops_root="${PROXSHIFT_GITOPS_ROOT:-${HOME}/gitops}"
  if [[ -d "${gitops_root}/.ansible" ]]; then
    cd "${gitops_root}/.ansible" || { echo "❌ Error: Cannot change to GitOps directory"; return 1; }
  else
    echo "⚠️  GitOps directory not found: ${gitops_root}/.ansible"
    echo "   Set PROXSHIFT_GITOPS_ROOT environment variable or create the directory"
    ps.root
  fi
  openshift-install agent wait-for install-complete --dir="ocp_install/${1}" --log-level=debug
}
