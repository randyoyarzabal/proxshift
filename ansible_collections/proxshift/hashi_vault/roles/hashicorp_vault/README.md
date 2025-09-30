# HashiCorp Vault Role

## Description

This role provides a clean interface for retrieving secrets from HashiCorp Vault. It handles multiple secret retrieval operations and stores them in a unified output variable for use in other tasks.

## Requirements

- Ansible 2.15+
- Access to HashiCorp Vault instance
- Valid Vault authentication token
- Python `requests` library

## Role Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `hashicorp_vault_api` | dict | Vault API connection details |
| `hashicorp_vault_api.url` | string | Vault server URL (e.g., `https://vault.example.com:8200`) |
| `hashicorp_vault_api.token` | string | Vault authentication token |
| `hashicorp_vault_secrets` | list | List of secrets to retrieve (see structure below) |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `hashicorp_vault_output_var` | string | `vault_values` | Variable name to store all retrieved secrets |

### Secret Structure

Each item in `hashicorp_vault_secrets` must contain:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Variable name to store this secret |
| `path` | string | Vault secret path (without `/v1/` prefix) |
| `key` | string | Secret key within the path |

## Return Values

The role sets a fact named by `hashicorp_vault_output_var` (default: `vault_values`) containing a dictionary with all retrieved secrets.

## Example Playbook

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
          - name: "ca_bundle"
            path: "secret/data/certificates"
            key: "ca_bundle"
        hashicorp_vault_output_var: "my_secrets"

    - name: Use retrieved secrets
      ansible.builtin.debug:
        msg: "Retrieved {{ my_secrets.keys() | list | length }} secrets"
```

## Advanced Example

```yaml
- name: Multi-environment secret retrieval
  hosts: localhost
  vars:
    environment: "production"
  tasks:
    - name: Get environment-specific secrets
      ansible.builtin.include_role:
        name: proxshift.hashi_vault.hashicorp_vault
      vars:
        hashicorp_vault_api:
          url: "{{ vault_url }}"
          token: "{{ vault_token }}"
        hashicorp_vault_secrets:
          - name: "api_key"
            path: "secret/data/{{ environment }}/openshift"
            key: "api_key"
          - name: "database_password"
            path: "secret/data/{{ environment }}/database"
            key: "password"
        hashicorp_vault_output_var: "env_secrets"
```

## Error Handling

The role validates all required variables and will fail with descriptive error messages if:
- Vault API connection details are missing
- Secret list is empty
- Vault API returns non-200 status codes
- Secret paths or keys don't exist

## Security Considerations

- Vault tokens should be stored securely (use Ansible Vault or environment variables)
- Retrieved secrets are stored in Ansible facts - ensure proper cleanup
- Consider using short-lived tokens when possible

## License

MIT

## Author Information

ProxShift Development Team
