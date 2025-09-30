#!/bin/bash
# Main test runner for ProxShift

# Note: Don't use 'set -e' here as we want to continue running tests even if one fails

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${BOLD}${BLUE}Running ProxShift Test Suite${NC}"
echo "==============================="

# Make test scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo ""
    echo -e "${BLUE}Running $test_name...${NC}"
    echo "----------------------------------------"
    
    if bash "$SCRIPT_DIR/$test_script"; then
        echo -e "${GREEN}✓ $test_name PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ $test_name FAILED${NC}"
        ((TESTS_FAILED++))
    fi
}

# Run test suites
run_test "Prerequisites Tests" "test_prerequisites.sh"
run_test "Syntax Tests" "test_syntax.sh"
run_test "Template Tests" "test_templates.sh"

# Summary
echo ""
echo -e "${BOLD}Test Summary${NC}"
echo "============="
echo -e "${GREEN}✓${NC} Passed: $TESTS_PASSED"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}✗${NC} Failed: $TESTS_FAILED"
fi
echo -e "  Total:  $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo ""
    echo -e "${RED}Some tests failed. Please fix the issues before proceeding.${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}🎉 All tests passed! System is ready for use.${NC}"
    exit 0
fi
