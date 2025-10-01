#!/bin/bash
# Core function regression tests for ProxShift
# Tests all key functions from proxshift.sh script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Test configuration
TEST_CLUSTER="ocp-sno3"  # Safe test cluster
TEST_TIMEOUT=300  # 5 minutes timeout for operations

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

echo -e "${BOLD}${BLUE}ProxShift Core Function Regression Tests${NC}"
echo "=========================================="

# Ensure we're in the right directory
cd "$PROJECT_ROOT"

# Source the ProxShift functions
if [[ -f "proxshift.sh" ]]; then
    source proxshift.sh
else
    echo -e "${RED}✗${NC} FAIL: proxshift.sh not found"
    exit 1
fi

# Test utility functions
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    echo ""
    echo -e "${BLUE}Testing: $test_name${NC}"
    echo "----------------------------------------"
    
    if timeout $TEST_TIMEOUT bash -c "$test_function"; then
        echo -e "${GREEN}✓${NC} PASS: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} FAIL: $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test functions
test_ps_ansible_root() {
    local start_dir=$(pwd)
    cd /tmp  # Change to different directory
    
    # Test function
    ps.ansible_root || return 1
    
    # Verify we're back in the project root
    if [[ $(pwd) == "$PROJECT_ROOT" ]]; then
        return 0
    else
        echo "Expected: $PROJECT_ROOT, Got: $(pwd)"
        return 1
    fi
}

test_ps_list_clusters() {
    local output
    output=$(ps.list_clusters 2>&1)
    
    # Check if output contains expected clusters
    if echo "$output" | grep -q "Available clusters"; then
        if echo "$output" | grep -E "(ocp|ocp-sno)" >/dev/null; then
            return 0
        else
            echo "No clusters found in output: $output"
            return 1
        fi
    else
        echo "Unexpected output format: $output"
        return 1
    fi
}

test_ps_validate_cluster_valid() {
    # Test with a known valid cluster
    ps.validate_cluster "$TEST_CLUSTER"
}

test_ps_validate_cluster_invalid() {
    # Test with invalid cluster - should fail
    if ps.validate_cluster "nonexistent-cluster" 2>/dev/null; then
        echo "Should have failed for nonexistent cluster"
        return 1
    else
        return 0
    fi
}

test_ps_validate_cluster_empty() {
    # Test with empty cluster name - should fail
    if ps.validate_cluster "" 2>/dev/null; then
        echo "Should have failed for empty cluster name"
        return 1
    else
        return 0
    fi
}

test_dry_run_parsing() {
    # Test the dry-run parsing function
    _ps.parse_dry_run "ocp-sno3" "--dry-run" "extra-arg"
    
    if [[ "$_ps_dry_run" == "true" ]] && \
       [[ "${_ps_filtered_args[0]}" == "ocp-sno3" ]] && \
       [[ "${_ps_filtered_args[1]}" == "extra-arg" ]]; then
        return 0
    else
        echo "Dry run parsing failed: dry_run=$_ps_dry_run, filtered_args=(${_ps_filtered_args[*]})"
        return 1
    fi
}

test_dry_run_parsing_no_flag() {
    # Test parsing without dry-run flag
    _ps.parse_dry_run "ocp-sno3" "extra-arg"
    
    if [[ "$_ps_dry_run" == "false" ]] && \
       [[ "${_ps_filtered_args[0]}" == "ocp-sno3" ]] && \
       [[ "${_ps_filtered_args[1]}" == "extra-arg" ]]; then
        return 0
    else
        echo "Non-dry run parsing failed: dry_run=$_ps_dry_run, filtered_args=(${_ps_filtered_args[*]})"
        return 1
    fi
}

test_generate_manifests_dry_run() {
    # Test manifest generation in dry-run mode
    local output
    output=$(ps.generate_manifests "$TEST_CLUSTER" --dry-run 2>&1)
    
    if echo "$output" | grep -q "DRY RUN"; then
        return 0
    else
        echo "Dry run output not detected: $output"
        return 1
    fi
}

test_provision_dry_run() {
    # Test provision in dry-run mode
    local output
    output=$(ps.provision "$TEST_CLUSTER" --dry-run 2>&1)
    
    if echo "$output" | grep -q "DRY RUN"; then
        return 0
    else
        echo "Provision dry run output not detected: $output"
        return 1
    fi
}

test_ansible_operations_dry_run() {
    # Test various ansible operations in dry-run mode
    local operations=(
        "ps.deprovision"
        "ps.start" 
        "ps.post"
        "ps.acm_import"
        "ps.gitops"
        "ps.vault"
    )
    
    for op in "${operations[@]}"; do
        echo "Testing $op in dry-run mode..."
        local output
        output=$($op "$TEST_CLUSTER" --dry-run 2>&1)
        
        if ! echo "$output" | grep -q "DRY RUN"; then
            echo "$op dry run failed: $output"
            return 1
        fi
    done
    
    return 0
}

test_force_operations_dry_run() {
    # Test force operations in dry-run mode
    local operations=(
        "ps.force"
        "ps.force_nohub" 
        "ps.force_blank"
    )
    
    for op in "${operations[@]}"; do
        echo "Testing $op in dry-run mode..."
        local output
        output=$($op "$TEST_CLUSTER" --dry-run 2>&1)
        
        if ! echo "$output" | grep -q "DRY RUN"; then
            echo "$op dry run failed: $output"
            return 1
        fi
    done
    
    return 0
}

test_environment_variables() {
    # Test that environment variables are set correctly
    if [[ -z "$PROXSHIFT_ROOT" ]]; then
        echo "PROXSHIFT_ROOT not set"
        return 1
    fi
    
    if [[ ! -d "$PROXSHIFT_ROOT" ]]; then
        echo "PROXSHIFT_ROOT directory doesn't exist: $PROXSHIFT_ROOT"
        return 1
    fi
    
    # PROXSHIFT_VAULT_PASS should be set (file may or may not exist)
    if [[ -z "$PROXSHIFT_VAULT_PASS" ]]; then
        echo "PROXSHIFT_VAULT_PASS not set"
        return 1
    fi
    
    return 0
}

test_aliases() {
    # Test that aliases are set correctly
    if ! type ps.root >/dev/null 2>&1; then
        echo "ps.root alias not found"
        return 1
    fi
    
    return 0
}

test_fallback_cluster_listing() {
    # Test the fallback cluster listing mechanism
    if [[ -f "inventory/clusters.yml" ]]; then
        local output
        output=$(_ps.list_clusters_fallback 2>&1)
        
        if echo "$output" | grep -E "(ocp|ocp-sno)" >/dev/null; then
            return 0
        else
            echo "Fallback cluster listing failed: $output"
            return 1
        fi
    else
        echo "No clusters.yml file found - skipping fallback test"
        return 0
    fi
}

test_backward_compatibility() {
    # Test deprecated function still works
    local output
    # Note: ps.generate_templates was removed - test would fail which is expected
    
    if echo "$output" | grep -q "deprecated"; then
        if echo "$output" | grep -q "DRY RUN"; then
            return 0
        else
            echo "Deprecated function didn't execute properly: $output"
            return 1
        fi
    else
        echo "Deprecation warning not found: $output"
        return 1
    fi
}

# Run all tests
echo "Starting core function tests..."

run_test "Environment Setup" "test_environment_variables"
run_test "Aliases Setup" "test_aliases"
run_test "Change to Ansible Root" "test_ps_ansible_root"
run_test "List Clusters" "test_ps_list_clusters"
run_test "Validate Valid Cluster" "test_ps_validate_cluster_valid"
run_test "Validate Invalid Cluster" "test_ps_validate_cluster_invalid"
run_test "Validate Empty Cluster Name" "test_ps_validate_cluster_empty"
run_test "Dry Run Parsing (with flag)" "test_dry_run_parsing"
run_test "Dry Run Parsing (without flag)" "test_dry_run_parsing_no_flag"
run_test "Generate Manifests (Dry Run)" "test_generate_manifests_dry_run"
run_test "Provision (Dry Run)" "test_provision_dry_run"
run_test "Ansible Operations (Dry Run)" "test_ansible_operations_dry_run"
run_test "Force Operations (Dry Run)" "test_force_operations_dry_run"
run_test "Fallback Cluster Listing" "test_fallback_cluster_listing"
run_test "Backward Compatibility" "test_backward_compatibility"

# Summary
echo ""
echo -e "${BOLD}Core Function Test Summary${NC}"
echo "=========================="
echo -e "${GREEN}✓${NC} Passed: $TESTS_PASSED"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}✗${NC} Failed: $TESTS_FAILED"
fi
echo -e "  Total:  $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo ""
    echo -e "${RED}Some core function tests failed. Please fix the issues before proceeding.${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}🎉 All core function tests passed!${NC}"
    exit 0
fi
