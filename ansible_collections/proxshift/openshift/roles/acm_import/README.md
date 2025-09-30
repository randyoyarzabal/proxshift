# ACM Import Role

## Description

This role manages Advanced Cluster Management (ACM) import operations for OpenShift clusters. It handles both the preparation and execution of cluster imports into Red Hat ACM hub clusters.

## Requirements

- Ansible 2.15+
- Collections:
  - `kubernetes.core`
  - `proxshift.openshift` (for oc_kubeadmin role dependency)
- Access to both hub cluster and managed cluster APIs
- Valid kubeadmin credentials for both clusters

## Role Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `acm_import_hub_cluster` | string | Name of the ACM hub cluster |
| `acm_import_cluster` | string | Name of the cluster to be imported |
| `acm_import_hub_cluster_api_url` | string | API URL of the hub cluster |
| `acm_import_cluster_api_url` | string | API URL of the cluster to be imported |
| `acm_import_output_dir` | string | Directory where ACM manifests will be generated |
| `ocp_install_dir` | string | OpenShift installation directory |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `acm_import_enabled` | boolean | `false` | Enable ACM import functionality |
| `acm_import_import` | boolean | `false` | Execute the actual import operation |
| `acm_import_api_key` | string | `""` | API key for cluster authentication (auto-set by oc_kubeadmin role) |

## Dependencies

- `proxshift.openshift.oc_kubeadmin` - Used for cluster authentication

## Tags

- `acm_import` - Run ACM import operations
- `vm_delete` - Clean up existing cluster resources before import

## Example Playbook

```yaml
- name: Import cluster to ACM hub
  hosts: localhost
  tasks:
    - name: Prepare and import cluster
      ansible.builtin.include_role:
        name: proxshift.openshift.acm_import
      vars:
        acm_import_enabled: true
        acm_import_import: true
        acm_import_hub_cluster: "hub-cluster"
        acm_import_cluster: "managed-cluster"
        acm_import_hub_cluster_api_url: "https://api.hub.example.com:6443"
        acm_import_cluster_api_url: "https://api.managed.example.com:6443"
        acm_import_output_dir: "/tmp/acm-manifests"
        ocp_install_dir: "/tmp/ocp-install"
```

## Workflow

1. **Preparation Phase** (when `acm_import_enabled: true`):
   - Logs into hub cluster using `oc_kubeadmin` role
   - Removes existing ManagedCluster resources if they exist
   - Deletes cluster namespace on hub
   - Generates and applies new ManagedCluster manifest
   - Labels the ManagedCluster with required metadata

2. **Import Phase** (when `acm_import_import: true`):
   - Logs into hub cluster to retrieve import secrets
   - Extracts CRDs and import manifests
   - Logs into target cluster
   - Applies CRDs and import configurations

## Generated Files

- `{acm_import_output_dir}/acm_join.yaml` - ManagedCluster manifest
- `{ocp_install_dir}/crds.yaml` - ACM CRDs for managed cluster
- `{ocp_install_dir}/import.yaml` - Import configuration for managed cluster

## License

MIT

## Author Information

ProxShift Development Team