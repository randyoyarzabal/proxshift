# ProxShift OpenShift Collection

A comprehensive Ansible collection for OpenShift cluster management, including ACM integration, cluster authentication, credential management, and GitOps workflows.

## Features

- **Cluster Authentication**: Secure kubeadmin login using Vault-stored credentials
- **ACM Integration**: Advanced Cluster Management import and lifecycle operations
- **Manifest Generation**: Dynamic OpenShift installation configuration generation
- **Credential Management**: Vault-based cluster credential storage and retrieval
- **Node Management**: Automated node labeling and configuration
- **Secret Operations**: Backup and restore of cluster secrets

## Roles

### Core OpenShift Management
- `acm_import` - Advanced Cluster Management import operations
- `cluster_auth` - OpenShift cluster authentication using Vault credentials
- `oc_kubeadmin` - Kubeadmin authentication and token management
- `ocp_manifests` - OpenShift installation manifest generation

### Credential & Secret Management

- `cluster_credentials` - Store cluster credentials in Vault
- `vault_credentials` - Vault-based credential operations
- `secret_management` - Backup/restore OpenShift secrets

### Node & Infrastructure

- `node_labeling` - Apply labels to OpenShift nodes

## Installation


```bash
# Install from local development
ansible-galaxy collection install ./ansible_collections/proxshift/openshift

# Or reference in requirements.yml
collections:
  - name: ./ansible_collections/proxshift/openshift
    type: dir
```

## Quick Start

### Basic Cluster Authentication

```yaml
- name: Login to OpenShift cluster
  hosts: localhost
  tasks:
    - name: Authenticate to cluster
      ansible.builtin.include_role:
        name: proxshift.openshift.oc_kubeadmin
      vars:
        oc_kubeadmin_cluster_name: "my-cluster"
        oc_kubeadmin_vault_addr: "https://vault.example.com:8200"
        oc_kubeadmin_vault_token: "{{ vault_token }}"
        oc_kubeadmin_vault_path: "secret/data/openshift/clusters"
```

### Generate OpenShift Manifests

```yaml
- name: Generate OpenShift installation manifests
  hosts: localhost
  tasks:
    - name: Create manifests
      ansible.builtin.include_role:
        name: proxshift.openshift.ocp_manifests
      vars:
        ocp_manifests_cluster:
          name: "production-cluster"
          version: "4.17.1"
        ocp_manifests_network:
          base_domain: "example.com"
          subnet: "10.0.0.0/24"
          gateway: "10.0.0.1"
          dns_servers: ["10.0.0.1", "8.8.8.8"]
        ocp_manifests_nodes:
          - name: "master-1"
            ip: "10.0.0.10"
            mac: "00:50:56:11:11:11"
            role: "master"
        ocp_manifests_credentials:
          pull_secret: "{{ pull_secret }}"
          ssh_key: "{{ ssh_public_key }}"
        ocp_manifests_output_dir: "/tmp/manifests"
```

### ACM Cluster Import

```yaml
- name: Import cluster to ACM hub
  hosts: localhost
  tasks:
    - name: Import to hub
      ansible.builtin.include_role:
        name: proxshift.openshift.acm_import
      vars:
        acm_import_enabled: true
        acm_import_import: true
        acm_import_hub_cluster: "hub-cluster"
        acm_import_cluster: "spoke-cluster"
        acm_import_hub_cluster_api_url: "https://api.hub.example.com:6443"
        acm_import_cluster_api_url: "https://api.spoke.example.com:6443"
        acm_import_output_dir: "/tmp/acm"
        ocp_install_dir: "/tmp/install"
```

## Dependencies

- `community.hashi_vault` - For Vault integration
- `kubernetes.core` - For Kubernetes/OpenShift operations
- `community.okd` - For OpenShift authentication

## Documentation

Each role includes comprehensive documentation:

- Role-specific README files with usage examples
- Argument specifications in `meta/argument_specs.yml`
- Complete parameter documentation

See the [ProxShift documentation](https://github.com/randyoyarzabal/proxshift/tree/main/docs) for complete setup and usage guides.

## License

MIT

## Author Information

ProxShift Development Team
- Randy Oyarzabal <randyoyarzabal@gmail.com>
