# Test Suite for OpenShift Proxmox Automation

## Overview

This directory contains tests for validating the OpenShift Proxmox automation system.

## Test Categories

### 1. Prerequisites Tests (`test_prerequisites.sh`)
- Ansible version validation
- Required collections check
- OpenShift installer binary verification
- jq availability

### 2. Syntax Tests (`test_syntax.sh`)
- Ansible playbook syntax validation
- Inventory syntax validation
- Jinja2 template syntax validation
- YAML linting

### 3. Integration Tests (`test_integration.sh`)
- Template rendering validation
- Inventory parsing
- Variable substitution
- Role parameter validation

### 4. Role Tests (`test_roles.yaml`)
- ProxShift collection role testing
- End-to-end role functionality validation
- Role integration testing
- Mock testing for external dependencies

### 5. Unit Tests (`test_units.sh`)
- Individual role testing
- Driver script function validation
- Configuration validation

## Running Tests

```bash
# Run all tests
./tests/run_all_tests.sh

# Run specific test category
./tests/test_prerequisites.sh
./tests/test_syntax.sh
./tests/test_integration.sh
./tests/test_units.sh

# Run role tests (requires Ansible)
cd tests && ansible-playbook test_roles.yaml

# CI/CD pipeline
./tests/ci_pipeline.sh
```

## CI/CD Integration

Tests are designed to run in CI/CD pipelines with:
- Exit codes for pass/fail
- Detailed logging
- Minimal dependencies
- Fast execution time

## Test Requirements

- Bash 4.0+
- Ansible 2.15+
- jq
- yamllint (optional)
- ansible-lint (optional)
