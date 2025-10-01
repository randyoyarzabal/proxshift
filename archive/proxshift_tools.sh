#!/usr/bin/env bash
# ProxShift Tools - OpenShift Proxmox Automation
# Provision OpenShift clusters on Proxmox with minimal setup

if [[ $0 == "${BASH_SOURCE[0]}" ]]; then
  echo "Error: ProxShift tools must be sourced, not executed directly."
  echo "Usage: source tools/proxshift_tools.sh"
  exit 1
fi

# ProxShift Environment Configuration
# Set these environment variables or they'll use sensible defaults
export PROXSHIFT_ROOT="${PROXSHIFT_ROOT:-$(pwd)}"
export PROXSHIFT_VAULT_PASS="${PROXSHIFT_VAULT_PASS:-${PROXSHIFT_ROOT}/config/.vault_pass}"

function ps.root() {
  cd "${PROXSHIFT_ROOT}" || { echo "❌ Error: Cannot change to PROXSHIFT_ROOT directory"; return 1; }
}

# Legacy aliases for backward compatibility
alias ocp.ansible_root=ps.root
alias ocp.root=ps.root

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

# Legacy alias
alias ocp.list_clusters=ps.clusters

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

function ps.validate() {
  local cluster=$1
  if [[ -z "$cluster" ]]; then
    echo "❌ Error: No cluster specified"
    echo "Available clusters:"
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
    echo "Available clusters:"
    ps.clusters
    return 1
  fi
}

# Legacy alias
alias ocp.validate_cluster=ps.validate

# Helper function to parse dry-run flags from arguments
function _ps.parse_dry_run() {
  local args=("$@")
  local dry_run=false
  local filtered_args=()
  
  for arg in "${args[@]}"; do
    if [[ "$arg" == "--dry-run" || "$arg" == "-n" ]]; then
      dry_run=true
    else
      filtered_args+=("$arg")
    fi
  done
  
  # Return results via global variables (bash limitation)
  _ps_dry_run="$dry_run"
  _ps_filtered_args=("${filtered_args[@]}")
}

# Helper function for ansible-playbook execution with consistent setup (LEGACY - for backward compatibility)
function _ps.run_ansible_legacy() {
  local cluster="$1"
  local tags="$2"
  local skip_tags="$3"
  local extra_args="$4"
  local show_timing="${5:-false}"
  local force_install="${6:-false}"
  local dry_run="${7:-false}"
  
  # Validate cluster if provided
  if [[ -n "$cluster" ]]; then
    ps.validate "$cluster" || return 1
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
  
  # ⚠️ LEGACY WARNING: Still using old main.yaml for backward compatibility
  # Build command
  local cmd="ansible-playbook main.yaml.bak"
  [[ -n "$cluster" ]] && cmd="$cmd -e cluster_name=${cluster}"
  [[ "$force_install" == "true" ]] && cmd="$cmd -e force_install=true"
  [[ -n "$tags" ]] && cmd="$cmd --tags=${tags}"
  [[ -n "$skip_tags" ]] && cmd="$cmd --skip-tags=${skip_tags}"
  [[ -n "$extra_args" ]] && cmd="$cmd $extra_args"
  
  # Show command
  if [[ "$dry_run" == "true" ]]; then
    echo "🧪 DRY RUN - Command that would be executed:"
    echo "   $cmd"
    echo ""
    echo "⚠️  WARNING: This function uses the legacy main.yaml.bak"
    echo "💡 To execute, remove --dry-run or -n flag"
    local exit_code=0
  else
    echo "⚠️  WARNING: Using legacy main.yaml.bak - consider migrating to new modular functions"
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

# Legacy alias
alias _ocp.run_ansible=_ps.run_ansible_legacy

# ============================================================================
# MODERN MODULAR FUNCTIONS - Using site.yaml orchestrator
# ============================================================================

function ps.provision() {
  _ps.parse_dry_run "$@"  # Parse all args consistently
  local cluster="${_ps_filtered_args[0]}"
  ps.validate "$cluster" || return 1
  if [[ "$_ps_dry_run" == "true" ]]; then
    echo "🚀 DRY RUN - Would provision cluster: $cluster"
    echo "   Equivalent to: ansible-playbook site.yaml -e cluster_name=$cluster"
    echo ""
  else
    echo "🚀 Provisioning cluster: $cluster using modular site.yaml"
  fi
  
  # Use the new modular site.yaml orchestrator
  ps.root
  local extra_args="${_ps_filtered_args[*]:1}"
  local cmd="ansible-playbook site.yaml -e cluster_name=$cluster $extra_args"
  
  if [[ "$_ps_dry_run" == "true" ]]; then
    echo "🧪 DRY RUN - Command that would be executed:"
    echo "   $cmd"
  else
    echo "$cmd"
    eval "$cmd"
  fi
}

# Legacy alias
alias ocp.provision=ps.provision

function ps.manifests(){
  _ps.parse_dry_run "$@"
  local cluster="${_ps_filtered_args[0]}"
  
  if [[ -z "$cluster" ]]; then
    echo "❌ Error: No cluster specified"
    echo "Usage: ps.manifests <cluster_name> [--dry-run|-n]"
    echo "Available clusters:"
    ps.clusters
    return 1
  fi
  
  echo "📄 Generating OpenShift manifests for: $cluster"
  echo "   Output directory: ocp_install/$cluster/"
  echo "   Files: install-config.yaml, agent-config.yaml (without backups)"
  echo ""
  
  # Use the new modular site.yaml with manifest-only mode
  ps.root
  local extra_args="${_ps_filtered_args[*]:1}"
  local cmd="ansible-playbook site.yaml -e cluster_name=$cluster -e only_manifests=true $extra_args"
  
  if [[ "$_ps_dry_run" == "true" ]]; then
    echo "🧪 DRY RUN - Command that would be executed:"
    echo "   $cmd"
  else
    echo "$cmd"
    eval "$cmd"
  fi
}

# Legacy aliases
alias ocp.generate_manifests=ps.manifests
alias ocp.generate_templates=ps.manifests


function ps.homelab(){
  _ps.parse_dry_run "$@"
  local cluster="${_ps_filtered_args[0]}"
  ps.validate "$cluster" || return 1
  
  echo "🏠 Provisioning FULL homelab cluster: $cluster (all features enabled)"
  
  ps.root
  local extra_args="${_ps_filtered_args[*]:1}"
  local cmd="ansible-playbook site.yaml -e cluster_name=$cluster -e enable_all=true $extra_args"
  
  if [[ "$_ps_dry_run" == "true" ]]; then
    echo "🧪 DRY RUN - Command that would be executed:"
    echo "   $cmd"
  else
    echo "$cmd"
    eval "$cmd"
  fi
}

# Legacy alias
alias ocp.homelab=ps.homelab

function ps.blank(){
  _ps.parse_dry_run "$@"
  local cluster="${_ps_filtered_args[0]}"
  ps.validate "$cluster" || return 1
  
  echo "⚪ Provisioning BLANK cluster: $cluster (minimal features)"
  
  ps.root
  local extra_args="${_ps_filtered_args[*]:1}"
  local cmd="ansible-playbook site.yaml -e cluster_name=$cluster -e enable_gitops=false -e enable_acm_import=false $extra_args"
  
  if [[ "$_ps_dry_run" == "true" ]]; then
    echo "🧪 DRY RUN - Command that would be executed:"
    echo "   $cmd"
  else
    echo "$cmd"
    eval "$cmd"
  fi
}

# Legacy alias
alias ocp.blank=ps.blank

function ps.backup(){
  _ps.parse_dry_run "$@"
  local cluster="${_ps_filtered_args[0]}"
  ps.validate "$cluster" || return 1
  
  echo "💾 Backing up certificates for cluster: $cluster (run BEFORE deletion)"
  
  ps.root
  local extra_args="${_ps_filtered_args[*]:1}"
  local cmd="ansible-playbook playbooks/pre-deletion-backup.yaml -e cluster_name=$cluster $extra_args"
  
  if [[ "$_ps_dry_run" == "true" ]]; then
    echo "🧪 DRY RUN - Command that would be executed:"
    echo "   $cmd"
  else
    echo "$cmd"
    eval "$cmd"
  fi
}

# Legacy alias
alias ocp.backup_certs=ps.backup

# ============================================================================
# LEGACY FUNCTIONS - Using main.yaml.bak for backward compatibility
# These are kept for existing scripts but should be migrated to new functions
# ============================================================================

# ============================================================================
# LEGACY FUNCTIONS - Using main.yaml.bak for backward compatibility
# These are kept for existing scripts but should be migrated to new functions
# ============================================================================

# Simplified functions using the legacy helper
function ps.deprovision(){
  _ps.parse_dry_run "$@"
  echo "⚠️  LEGACY: Consider using modular approach with site.yaml"
  _ps.run_ansible_legacy "${_ps_filtered_args[0]}" "vm_delete" "" "" false false "$_ps_dry_run"
}

# Legacy aliases
alias ocp.ansible_deprovision=ps.deprovision

function ps.start(){
  _ps.parse_dry_run "$@"
  echo "⚠️  LEGACY: Consider using modular approach with site.yaml"
  _ps.run_ansible_legacy "${_ps_filtered_args[0]}" "vm_start" "" "" false false "$_ps_dry_run"
}

alias ocp.ansible_start=ps.start

function ps.post(){
  _ps.parse_dry_run "$@"
  echo "⚠️  LEGACY: Consider using modular approach with site.yaml"
  _ps.run_ansible_legacy "${_ps_filtered_args[0]}" "post,restore,vault,gitops,storage" "" "" false false "$_ps_dry_run"
}

alias ocp.ansible_post=ps.post

function ps.acm(){
  _ps.parse_dry_run "$@"
  echo "⚠️  LEGACY: Consider using modular approach with site.yaml"
  _ps.run_ansible_legacy "${_ps_filtered_args[0]}" "acm,acm_import" "backup,restore" "" false false "$_ps_dry_run"
}

alias ocp.ansible_acm_import=ps.acm

function ps.backup_legacy(){
  _ps.parse_dry_run "$@"
  echo "⚠️  LEGACY: Consider using ps.backup function instead"
  _ps.run_ansible_legacy "ocp-sno1" "post,backup" "" "" false false "$_ps_dry_run"
}

alias ocp.ansible_backup_certs=ps.backup_legacy

function ps.restore(){
  _ps.parse_dry_run "$@"
  echo "⚠️  LEGACY: Consider using modular approach with site.yaml"
  _ps.run_ansible_legacy "ocp-sno1" "post,restore" "" "" false false "$_ps_dry_run"
}

alias ocp.ansible_restore_certs=ps.restore

function ps.gitops_loop(){
  _ps.parse_dry_run "$@"
  echo "⚠️  LEGACY: Consider using modular approach with site.yaml"
  _ps.run_ansible_legacy "ocp-sno1" "gitops_loop" "" "" false false "$_ps_dry_run"
}

alias ocp.ansible_gitops_loop=ps.gitops_loop

function ps.gitops(){
  _ps.parse_dry_run "$@"
  echo "⚠️  LEGACY: Consider using modular approach with site.yaml"
  _ps.run_ansible_legacy "${_ps_filtered_args[0]}" "gitops" "" "" false false "$_ps_dry_run"
}

alias ocp.ansible_gitops=ps.gitops

function ps.vault(){
  _ps.parse_dry_run "$@"
  echo "⚠️  LEGACY: Consider using modular approach with site.yaml"
  _ps.run_ansible_legacy "${_ps_filtered_args[0]}" "vault" "" "" false false "$_ps_dry_run"
}

alias ocp.ansible_vault=ps.vault


function ps.force(){
  _ps.parse_dry_run "$@"  # Parse all args consistently  
  local cluster="${_ps_filtered_args[0]}"
  local skip_restore="backup"
  echo "⚠️  LEGACY: Consider using ps.provision or ps.homelab functions instead"
  # Special case: ocp-sno1 allows restore
  if [[ ${cluster} == 'ocp-sno1' ]]; then
    skip_restore="backup"
  else
    skip_restore="backup,restore"
  fi
  _ps.run_ansible_legacy "$cluster" "" "$skip_restore" "${_ps_filtered_args[*]:1}" true true "$_ps_dry_run"
}

alias ocp.ansible_force=ps.force

function ps.force_nohub(){
  _ps.parse_dry_run "$@"  # Parse all args consistently
  local cluster="${_ps_filtered_args[0]}"
  echo "⚠️  LEGACY: Consider using ps.blank function instead"
  _ps.run_ansible_legacy "$cluster" "" "backup,restore,acm_import" "${_ps_filtered_args[*]:1}" true true "$_ps_dry_run"
}

alias ocp.ansible_force_nohub=ps.force_nohub

function ps.force_blank(){
  _ps.parse_dry_run "$@"  # Parse all args consistently  
  local cluster="${_ps_filtered_args[0]}"
  echo "⚠️  LEGACY: Consider using ps.blank function instead"
  _ps.run_ansible_legacy "$cluster" "" "backup,restore,hub,post,acm_import,gitops" "${_ps_filtered_args[*]:1}" true true "$_ps_dry_run"
}

alias ocp.ansible_force_blank=ps.force_blank

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function ps.watch () {
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

alias ocp.install_watch=ps.watch

# ============================================================================
# PROXSHIFT BANNER AND STATUS
# ============================================================================

# Display ProxShift banner with status
function __ps.banner() {
  local feature_status=""
  local cluster_status=""
  local mode_status=""
  
  # Show current cluster if available
  if [[ -n "${CLUSTER_NAME:-}" ]]; then
    cluster_status="cluster: \033[0;36m${CLUSTER_NAME}\033[0m"
  else
    cluster_status="cluster: \033[0;33mnone selected\033[0m"
  fi
  
  # Check feature flags from site.yaml or current environment
  local acm_status="\033[0;31mdisabled\033[0m"
  local gitops_status="\033[0;31mdisabled\033[0m"
  local backup_status="\033[0;31mdisabled\033[0m"
  
  # Try to determine current feature status (these would be set by site.yaml)
  if [[ "${enable_acm_import:-true}" == "true" ]]; then
    acm_status="\033[0;32menabled\033[0m"
  fi
  if [[ "${enable_gitops:-false}" == "true" ]]; then
    gitops_status="\033[0;32menabled\033[0m"
  fi
  if [[ "${enable_backup_restore:-false}" == "true" ]]; then
    backup_status="\033[0;32menabled\033[0m"
  fi
  
  feature_status="acm: ${acm_status} | gitops: ${gitops_status} | backup: ${backup_status}"
  
  # Determine mode based on available clusters
  local available_clusters
  available_clusters=$(ps.clusters 2>/dev/null | grep -E "^  (ocp|ocp-)" | wc -l 2>/dev/null || echo "0")
  if [[ "$available_clusters" -gt 3 ]]; then
    mode_status="mode: \033[0;32mhomelab (${available_clusters} clusters)\033[0m"
  else
    mode_status="mode: \033[0;36mstandard (${available_clusters} clusters)\033[0m"
  fi
  
  echo -e "\033[1;33m    ____                 _____ __    _ ____  __\033[0m"
  echo -e "\033[1;33m   / __ \\________  _  __/ ___// /_  (_) __/ / /\033[0m ${cluster_status}"
  echo -e "\033[1;33m  / /_/ / ___/ _ \\| |/_/\\__ \\/ __ \\/ / /_/ / /_\033[0m ${feature_status}"
  echo -e "\033[1;33m / ____/ /  / (_) >  <___/ / / / / / __/ / __/\033[0m ${mode_status}"
  echo -e "\033[1;33m/_/   /_/   \\___/_/|_/____/_/ /_/_/_/   /_/\033[0m   OpenShift on Proxmox"
}

# Display ProxShift status and tips
function __ps.status() {
  echo -e "\033[0;36mProxShift Status:\033[0m"
  echo -e "• Available functions: \033[0;36m$(compgen -A function | grep '^ps\.' | wc -l | tr -d ' ')\033[0m (modern) + $(compgen -A function | grep '^ocp\.' | wc -l | tr -d ' ')\033[0m (legacy)"
  
  local cluster_count
  cluster_count=$(ps.clusters 2>/dev/null | grep -E "^  (ocp|ocp-)" | wc -l 2>/dev/null || echo "0")
  echo -e "• Clusters available: \033[0;36m${cluster_count}\033[0m"
  
  local vault_status="\033[0;31mnot configured\033[0m"
  if [[ -f "config/vault-credentials.yml" ]]; then
    vault_status="\033[0;32mconfigured\033[0m"
  fi
  echo -e "• Vault: ${vault_status}"
  
  local playbook_count
  playbook_count=$(find playbooks -name "*.yaml" 2>/dev/null | wc -l || echo "0")
  echo -e "• Playbooks: \033[0;36m${playbook_count}\033[0m modular components"
}

# ============================================================================
# HELP AND INFO FUNCTIONS
# ============================================================================

function ps.help() {
  local USAGE="\033[0;36mUsage:\033[0m \$FUNCNAME [category] [options]

\033[1;33mDescription:\033[0m
Display ProxShift help information, commands, and usage examples.

\033[0;34mArguments:\033[0m
  category    Help category: commands, examples, config (optional)

\033[0;34mOptions:\033[0m
  --compact, -c   Show compact command reference
  --search <term> Search for specific commands or topics
  -?, --help      Show this help

\033[0;32mCategories:\033[0m
  commands    Core ProxShift commands and usage
  examples    Usage examples and workflows
  config      Configuration and setup help
  search      Search through available functions

\033[1;33mExamples:\033[0m
  \$FUNCNAME                    # Show full help with banner
  \$FUNCNAME commands          # Show only core commands
  \$FUNCNAME examples          # Show usage examples
  \$FUNCNAME --compact         # Compact command reference
  \$FUNCNAME --search ocp      # Search for cluster-related commands
"

  if [[ $1 == "-?" ]] || [[ $1 == "--help" ]]; then
    echo -e "${USAGE}"
    return
  fi

  case "${1:-full}" in
    commands|cmd)
      __ps.show_core_commands
      ;;
    examples|ex)
      __ps.show_examples
      ;;
    config|cfg)
      __ps.show_configuration_help
      ;;
    search)
      __ps.search_help "$2"
      ;;
    --compact|-c)
      __ps.show_compact_reference
      ;;
    --search)
      __ps.search_help "$2"
      ;;
    full|*)
      __ps.banner
      echo
      __ps.status
      echo
      echo -e "\033[1;33mAvailable help categories:\033[0m"
      echo -e "• \033[0;32mps.help commands\033[0m  - Core commands and usage"
      echo -e "• \033[0;32mps.help examples\033[0m  - Usage examples and workflows"
      echo -e "• \033[0;32mps.help config\033[0m    - Configuration options"
      echo -e "• \033[0;32mps.help --compact\033[0m - Quick reference"
      echo
      echo -e "\033[0;36mQuick start: \033[0;32mps.[tab][tab]\033[0m to see all commands"
      echo
      echo -e "\033[1;33m🚀 Getting Started:\033[0m"
      echo -e "\033[0;32mps.homelab ocp-sno1\033[0m     # Full homelab deployment"
      echo -e "\033[0;32mps.blank ocp-sno2\033[0m       # Minimal OpenShift cluster"
      echo -e "\033[0;32mps.manifests ocp-sno3\033[0m   # Generate manifests only"
      ;;
  esac
}

# Show core ProxShift commands
function __ps.show_core_commands() {
  echo -e "\033[1;33mCore ProxShift Commands:\033[0m"
  echo
  echo -e "\033[0;36mCluster Deployment:\033[0m"
  echo -e "  \033[0;32mps.provision <cluster>\033[0m   Standard cluster deployment"
  echo -e "  \033[0;32mps.homelab <cluster>\033[0m    Full homelab deployment (all features)"
  echo -e "  \033[0;32mps.blank <cluster>\033[0m      Minimal cluster (no GitOps/ACM)"
  echo -e "  \033[0;32mps.manifests <cluster>\033[0m  Generate manifests only"
  echo
  echo -e "\033[0;36mCluster Management:\033[0m"
  echo -e "  \033[0;32mps.backup <cluster>\033[0m     Backup certificates before deletion"
  echo -e "  \033[0;32mps.watch <cluster>\033[0m      Watch installation progress"
  echo -e "  \033[0;32mps.clusters\033[0m             List available clusters"
  echo
  echo -e "\033[0;36mUtilities:\033[0m"
  echo -e "  \033[0;32mps.root\033[0m                 Navigate to ProxShift directory"
  echo -e "  \033[0;32mps.help\033[0m                 Show this help system"
  echo
  echo -e "\033[0;34mUsage tip:\033[0m All commands support \033[0;32m--dry-run\033[0m or \033[0;32m-n\033[0m for previews"
}

# Show usage examples
function __ps.show_examples() {
  echo -e "\033[1;33mProxShift Usage Examples:\033[0m"
  echo
  echo -e "\033[0;36mHomelab Deployment (All Features):\033[0m"
  echo -e "  \033[0;32mps.homelab ocp-sno1\033[0m"
  echo -e "  • ACM import/detach: \033[0;32menabled\033[0m"
  echo -e "  • GitOps/ESO: \033[0;32menabled\033[0m"
  echo -e "  • Certificate backup/restore: \033[0;32menabled\033[0m"
  echo -e "  • Storage labels: \033[0;32menabled\033[0m"
  echo
  echo -e "\033[0;36mMinimal Cluster (Most Users):\033[0m"
  echo -e "  \033[0;32mps.blank ocp-sno2\033[0m"
  echo -e "  • Just OpenShift cluster"
  echo -e "  • No GitOps or ACM complexity"
  echo -e "  • Perfect for testing or simple deployments"
  echo
  echo -e "\033[0;36mManifest Generation Only:\033[0m"
  echo -e "  \033[0;32mps.manifests ocp-sno3\033[0m"
  echo -e "  • Generates install-config.yaml and agent-config.yaml"
  echo -e "  • No backup files created"
  echo -e "  • Perfect for customization before deployment"
  echo
  echo -e "\033[0;36mCustom Feature Selection:\033[0m"
  echo -e "  \033[0;32mansible-playbook site.yaml -e cluster_name=ocp-sno1 -e enable_gitops=true -e enable_acm_import=false\033[0m"
  echo
  echo -e "\033[0;36mCertificate Backup Workflow:\033[0m"
  echo -e "  \033[0;32mps.backup ocp-sno1\033[0m        # BEFORE cluster deletion"
  echo -e "  \033[0;33m# Delete cluster\033[0m"
  echo -e "  \033[0;32mps.homelab ocp-sno1\033[0m       # Rebuild with certificate restore"
}

# Show compact command reference  
function __ps.show_compact_reference() {
  echo -e "\033[1;33mProxShift Quick Reference:\033[0m"
  echo
  echo -e "\033[0;36mCore:\033[0m provision, homelab, blank, manifests, backup, watch"
  echo -e "\033[0;36mUtils:\033[0m clusters, root, help"
  echo -e "\033[0;36mLegacy:\033[0m ps.* (modern) vs ocp.* (deprecated)"
  echo
  echo -e "\033[0;34mQuick Start:\033[0m"
  echo -e "\033[0;32mps.homelab ocp-sno1\033[0m   # Full deployment"
  echo -e "\033[0;32mps.blank ocp-sno2\033[0m     # Minimal cluster"
}

# Search through ProxShift commands
function __ps.search_help() {
  local search_term="$1"
  
  if [[ -z "$search_term" ]]; then
    echo -e "\033[0;31mError:\033[0m Please provide a search term"
    echo -e "\033[0;34mUsage:\033[0m ps.help --search <term>"
    return 1
  fi
  
  echo -e "\033[0;36mSearching for: \033[1;33m$search_term\033[0m"
  echo
  
  # Search function names
  local matching_functions=($(compgen -A function | grep -i "ps.*$search_term" | sort))
  if [[ ${#matching_functions[@]} -gt 0 ]]; then
    echo -e "\033[0;32mMatching Functions:\033[0m"
    for func in "${matching_functions[@]}"; do
      echo -e "  \033[0;36m$func\033[0m"
    done
    echo
  fi
  
  # Search aliases  
  local matching_aliases=($(compgen -A alias | grep -i ".*$search_term" | sort))
  if [[ ${#matching_aliases[@]} -gt 0 ]]; then
    echo -e "\033[0;32mMatching Aliases:\033[0m"
    for alias_name in "${matching_aliases[@]}"; do
      echo -e "  \033[0;36m$alias_name\033[0m"
    done
    echo
  fi
  
  if [[ ${#matching_functions[@]} -eq 0 && ${#matching_aliases[@]} -eq 0 ]]; then
    echo -e "\033[1;33mNo matches found for '$search_term'\033[0m"
    echo
    echo -e "\033[0;34mTry:\033[0m"
    echo -e "• \033[0;32mps.help commands\033[0m - see all core commands"
    echo -e "• \033[0;32mps.help examples\033[0m - see usage examples"
    echo -e "• \033[0;32mps.[tab][tab]\033[0m - bash completion"
  fi
}

# Legacy alias for backward compatibility
alias ocp.help=ps.help

# Show ProxShift banner and info on source
__ps.banner
echo
echo "✅ ProxShift Tools loaded!"
echo "💡 Type '\033[0;32mps.help\033[0m' for usage information"
echo "🚀 Modern functions: \033[0;32mps.homelab\033[0m, \033[0;32mps.blank\033[0m, \033[0;32mps.provision\033[0m"
echo "⚠️  Legacy functions: \033[0;33mocp.*\033[0m (deprecated, use \033[0;32mps.*\033[0m instead)"
echo
