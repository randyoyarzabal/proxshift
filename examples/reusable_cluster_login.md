# Reusable Cluster Login Examples

## Overview

The new `tasks/cluster_login.yml` is a reusable task that can authenticate to any OpenShift cluster. It's used throughout ProxShift for different scenarios.

## Usage Examples

### 1. Login to Newly Provisioned Cluster

```yaml
- name: "Login to newly provisioned cluster"
  ansible.builtin.include_tasks:
    file: tasks/cluster_login.yml
  vars:
    login_cluster_name: "{{ cluster_name }}"
    login_cluster_api_url: "{{ cluster_api_url }}"
    login_auth_method: "kubeadmin"
```

### 2. Login to ACM Hub Cluster

```yaml
- name: "Login to ACM hub cluster for import operations"
  ansible.builtin.include_tasks:
    file: tasks/cluster_login.yml
  vars:
    login_cluster_name: "{{ hub_cluster }}"
    login_cluster_api_url: "{{ hub_cluster_api_url }}"
    login_auth_method: "kubeadmin"
```

### 3. Login to Target Cluster for Detach

```yaml
- name: "Login to target cluster for ACM detach"
  ansible.builtin.include_tasks:
    file: tasks/cluster_login.yml
  vars:
    login_cluster_name: "{{ target_cluster }}"
    login_cluster_api_url: "{{ target_cluster_api_url }}"
    login_auth_method: "kubeadmin"
```

### 4. Login with Service Account Token

```yaml
- name: "Login with service account"
  ansible.builtin.include_tasks:
    file: tasks/cluster_login.yml
  vars:
    login_cluster_name: "{{ cluster_name }}"
    login_cluster_api_url: "{{ cluster_api_url }}"
    login_auth_method: "token"
    login_token: "{{ service_account_token }}"
```

## Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `login_cluster_name` | Name of the cluster to login to | `cluster_name` | Yes |
| `login_cluster_api_url` | API URL of the cluster | `cluster_api_url` | Yes |
| `login_auth_method` | Authentication method | `kubeadmin` | No |
| `login_token` | Token for token-based auth | - | If auth_method=token |

## Return Values

After successful execution:
- `cluster_login_successful`: Boolean indicating success
- `cluster_auth_token`: The authentication token
- `oc_kubeadmin_value_return`: Token (for backward compatibility)

## Integration Points

### ACM Operations

The task can be used for:
- Hub cluster login for import operations
- Target cluster login for detach operations
- Multi-cluster management workflows

### GitOps Operations

- Login to clusters for ESO configuration
- Login to clusters for ArgoCD setup
- Login to clusters for policy deployment

### Storage Operations

- Login for OCS/ODF configuration
- Login for storage class management
- Login for PV operations

## Error Handling

The task includes:
- Verification of login success
- Clear error messages
- Status facts for downstream tasks

If login fails, subsequent tasks can check `cluster_login_successful` before proceeding.
