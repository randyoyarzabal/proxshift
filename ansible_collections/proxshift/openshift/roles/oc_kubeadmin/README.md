# OpenShift Kubeadmin Authentication Role

## Description

This role handles OpenShift cluster authentication using kubeadmin credentials stored in HashiCorp Vault. It provides a clean interface for logging into OpenShift clusters and returns authentication tokens for use in other roles and tasks.

## Requirements

- Ansible 2.15+
- Collections:
  - `community.hashi_vault`
- HashiCorp Vault with cluster credentials stored
- Valid Vault authentication token

## Role Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `oc_kubeadmin_cluster_name` | string | Name of the cluster to authenticate to |
| `oc_kubeadmin_vault_addr` | string | HashiCorp Vault server URL |
| `oc_kubeadmin_vault_token` | string | Vault authentication token |
| `oc_kubeadmin_vault_path` | string | Vault path where cluster credentials are stored |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `oc_kubeadmin_validate_certs` | boolean | `false` | Validate SSL certificates |
| `oc_kubeadmin_verbose` | boolean | `false` | Enable verbose output |

## Return Values

The role sets the following facts:

| Variable | Type | Description |
|----------|------|-------------|
| `oc_kubeadmin_value_return` | string | OpenShift API authentication token |
| `oc_kubeadmin_api_url` | string | OpenShift API URL |

## Vault Storage Format

The role expects cluster credentials to be stored in Vault with the following structure:

```json
{
  "data": {
    "data": {
      "api": "https://api.cluster-name.domain.com:6443",
      "kubeadmin": "kubeadmin-password-here",
      "kubeconfig": "base64-encoded-kubeconfig-content"
    }
  }
}
```

## Dependencies

None

## Example Playbook

### Basic Authentication

```yaml
- name: Authenticate to OpenShift cluster
  hosts: localhost
  tasks:
    - name: Login to cluster
      ansible.builtin.include_role:
        name: proxshift.openshift.oc_kubeadmin
      vars:
        oc_kubeadmin_cluster_name: "production-cluster"
        oc_kubeadmin_vault_addr: "https://vault.example.com:8200"
        oc_kubeadmin_vault_token: "{{ vault_token }}"
        oc_kubeadmin_vault_path: "secret/data/openshift/clusters"

    - name: Use authentication token
      kubernetes.core.k8s_info:
        host: "{{ oc_kubeadmin_api_url }}"
        api_key: "{{ oc_kubeadmin_value_return }}"
        validate_certs: false
        api_version: v1
        kind: Node
      register: cluster_nodes

    - name: Display cluster nodes
      ansible.builtin.debug:
        msg: "Cluster has {{ cluster_nodes.resources | length }} nodes"
```

### Multiple Cluster Authentication

```yaml
- name: Authenticate to multiple clusters
  hosts: localhost
  vars:
    clusters:
      - "hub-cluster"
      - "spoke-cluster-1"
      - "spoke-cluster-2"
  tasks:
    - name: Login to each cluster
      ansible.builtin.include_role:
        name: proxshift.openshift.oc_kubeadmin
      vars:
        oc_kubeadmin_cluster_name: "{{ item }}"
        oc_kubeadmin_vault_addr: "{{ vault_url }}"
        oc_kubeadmin_vault_token: "{{ vault_token }}"
        oc_kubeadmin_vault_path: "secret/data/openshift/clusters"
      loop: "{{ clusters }}"
      register: cluster_auth_results

    - name: Store authentication details
      ansible.builtin.set_fact:
        cluster_credentials: >-
          {{
            cluster_credentials | default({}) | combine({
              item.item: {
                'api_url': oc_kubeadmin_api_url,
                'token': oc_kubeadmin_value_return
              }
            })
          }}
      loop: "{{ cluster_auth_results.results }}"
```

### Using with ACM Import

```yaml
- name: ACM cluster import with authentication
  hosts: localhost
  tasks:
    - name: Login to hub cluster
      ansible.builtin.include_role:
        name: proxshift.openshift.oc_kubeadmin
      vars:
        oc_kubeadmin_cluster_name: "hub-cluster"
        oc_kubeadmin_vault_addr: "{{ vault_addr }}"
        oc_kubeadmin_vault_token: "{{ vault_token }}"
        oc_kubeadmin_vault_path: "{{ vault_path }}"

    - name: Store hub credentials
      ansible.builtin.set_fact:
        hub_api_url: "{{ oc_kubeadmin_api_url }}"
        hub_api_token: "{{ oc_kubeadmin_value_return }}"

    - name: Login to spoke cluster
      ansible.builtin.include_role:
        name: proxshift.openshift.oc_kubeadmin
      vars:
        oc_kubeadmin_cluster_name: "spoke-cluster"
        oc_kubeadmin_vault_addr: "{{ vault_addr }}"
        oc_kubeadmin_vault_token: "{{ vault_token }}"
        oc_kubeadmin_vault_path: "{{ vault_path }}"

    - name: Import spoke to hub
      kubernetes.core.k8s:
        host: "{{ hub_api_url }}"
        api_key: "{{ hub_api_token }}"
        validate_certs: false
        definition:
          apiVersion: cluster.open-cluster-management.io/v1
          kind: ManagedCluster
          metadata:
            name: "spoke-cluster"
            labels:
              cloud: "auto-detect"
              cluster.open-cluster-management.io/clusterset: "default"
        state: present
```

## Error Handling

The role includes comprehensive error handling for:

1. **Vault Connection Issues**: Clear error messages for connectivity problems
2. **Missing Credentials**: Validation that required secrets exist in Vault
3. **Authentication Failures**: Detailed feedback on OpenShift login issues
4. **API Connectivity**: Verification that cluster API is accessible

## Vault Path Structure

The role expects Vault paths to be structured as:
```
{vault_path}/{cluster_name}
```

For example, with `vault_path: "secret/data/openshift/clusters"` and `cluster_name: "production"`:
- Full Vault path: `secret/data/openshift/clusters/production`

## Security Considerations

1. **Token Management**: API tokens are stored in Ansible facts - ensure proper cleanup
2. **Vault Security**: Use appropriate Vault policies to restrict access
3. **SSL Verification**: Enable certificate validation in production environments
4. **Token Lifetime**: Be aware of OpenShift token expiration policies

## Best Practices

1. **Naming Convention**: Use consistent cluster naming across Vault and inventory
2. **Token Caching**: Consider caching tokens for multiple operations
3. **Error Recovery**: Implement retry logic for transient network issues
4. **Audit Logging**: Enable Vault audit logging for credential access

## License

MIT

## Author Information

ProxShift Development Team