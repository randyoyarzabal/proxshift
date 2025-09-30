# ProxShift HashiCorp Vault Collection

A focused Ansible collection for HashiCorp Vault integration, providing secure secret retrieval and management capabilities for ProxShift operations.

## Features

- **Secure Secret Retrieval**: Clean interface for fetching secrets from Vault
- **Multiple Secret Support**: Retrieve multiple secrets in a single operation
- **Flexible Configuration**: Support for various Vault configurations and auth methods
- **Error Handling**: Comprehensive validation and error reporting
- **Return Value Management**: Unified output variable for easy secret consumption

## Roles

### Secret Management
- `hashicorp_vault` - Retrieve secrets from HashiCorp Vault with clean interface

## Installation

```bash
# Install from local development
ansible-galaxy collection install ./ansible_collections/proxshift/hashi_vault

# Or reference in requirements.yml
collections:
  - name: ./ansible_collections/proxshift/hashi_vault
    type: dir
```

## Quick Start

### Basic Secret Retrieval

```yaml
- name: Retrieve secrets from Vault
  hosts: localhost
  tasks:
    - name: Get cluster credentials
      ansible.builtin.include_role:
        name: proxshift.hashi_vault.hashicorp_vault
      vars:
        hashicorp_vault_api:
          url: "https://vault.example.com:8200"
          token: "{{ vault_token }}"
        hashicorp_vault_secrets:
          - name: "pull_secret"
            path: "secret/data/openshift/registry"
            key: "pull_secret"
          - name: "ssh_key"
            path: "secret/data/openshift/access"
            key: "public_key"
        hashicorp_vault_output_var: "retrieved_secrets"

    - name: Use retrieved secrets
      ansible.builtin.debug:
        msg: "Retrieved {{ retrieved_secrets.keys() | length }} secrets"
```

### Advanced Multi-Environment Usage

```yaml
- name: Environment-specific secret retrieval
  hosts: localhost
  vars:
    environment: "{{ env | default('development') }}"
  tasks:
    - name: Get environment secrets
      ansible.builtin.include_role:
        name: proxshift.hashi_vault.hashicorp_vault
      vars:
        hashicorp_vault_api:
          url: "{{ vault_url }}"
          token: "{{ vault_token }}"
        hashicorp_vault_secrets:
          - name: "database_password"
            path: "secret/data/{{ environment }}/database"
            key: "password"
          - name: "api_token"
            path: "secret/data/{{ environment }}/api"
            key: "token"
          - name: "tls_cert"
            path: "secret/data/{{ environment }}/certificates"
            key: "tls_certificate"
        hashicorp_vault_output_var: "env_secrets"
```

### Integration with Other Collections

```yaml
- name: Complete workflow with Vault integration
  hosts: localhost
  tasks:
    # 1. Retrieve secrets
    - name: Get OpenShift secrets
      ansible.builtin.include_role:
        name: proxshift.hashi_vault.hashicorp_vault
      vars:
        hashicorp_vault_api:
          url: "{{ vault_addr }}"
          token: "{{ vault_token }}"
        hashicorp_vault_secrets:
          - name: "pull_secret"
            path: "secret/data/openshift/registry"
            key: "pull_secret"
          - name: "ssh_key"
            path: "secret/data/openshift/access"
            key: "public_key"
        hashicorp_vault_output_var: "ocp_secrets"

    # 2. Use secrets with other ProxShift collections
    - name: Generate OpenShift manifests
      ansible.builtin.include_role:
        name: proxshift.openshift.ocp_manifests
      vars:
        ocp_manifests_credentials:
          pull_secret: "{{ ocp_secrets.pull_secret }}"
          ssh_key: "{{ ocp_secrets.ssh_key }}"
        # ... other manifest variables
```

## Role Documentation

### hashicorp_vault

Retrieves secrets from HashiCorp Vault and stores them in a unified output variable.

#### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `hashicorp_vault_api.url` | string | Vault server URL |
| `hashicorp_vault_api.token` | string | Vault authentication token |
| `hashicorp_vault_secrets` | list | List of secrets to retrieve |

#### Secret Structure

Each secret in the list must contain:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Variable name for this secret |
| `path` | string | Vault secret path (without /v1/ prefix) |
| `key` | string | Secret key within the path |

#### Return Values

The role sets a fact named by `hashicorp_vault_output_var` containing all retrieved secrets as a dictionary.

## Security Considerations

1. **Token Security**: Store Vault tokens securely using environment variables or Ansible Vault
2. **Secret Cleanup**: Retrieved secrets are stored in Ansible facts - ensure proper cleanup
3. **Access Control**: Use appropriate Vault policies to restrict secret access
4. **Audit Logging**: Enable Vault audit logging for secret access tracking

## Error Handling

The role provides comprehensive error handling for:

- Invalid Vault connection parameters
- Network connectivity issues
- Authentication failures
- Missing secret paths or keys
- Malformed secret data

## Best Practices

1. **Token Management**: Use short-lived tokens when possible
2. **Path Organization**: Organize secrets logically in Vault paths
3. **Batch Operations**: Retrieve multiple related secrets in single operations
4. **Environment Isolation**: Use environment-specific Vault paths
5. **Monitoring**: Monitor Vault access patterns and usage

## Dependencies

- Python `requests` library
- Network access to HashiCorp Vault instance
- Valid Vault authentication credentials

## License

MIT

## Author Information

ProxShift Development Team
- Randy Oyarzabal <randyoyarzabal@gmail.com>
