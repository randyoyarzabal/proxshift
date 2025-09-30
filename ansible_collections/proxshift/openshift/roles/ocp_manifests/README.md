# OpenShift Manifests Role

## Description

This role generates OpenShift installation manifests (`install-config.yaml` and `agent-config.yaml`) from universal templates. It supports both Single Node OpenShift (SNO) and multi-node cluster configurations, automatically detecting the cluster type based on node count.

## Requirements

- Ansible 2.15+
- Valid OpenShift pull secret
- SSH public key for cluster access
- Network configuration details

## Role Variables

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `ocp_manifests_cluster` | dict | Cluster configuration |
| `ocp_manifests_cluster.name` | string | Cluster name |
| `ocp_manifests_network` | dict | Network configuration |
| `ocp_manifests_network.base_domain` | string | Base domain for cluster |
| `ocp_manifests_network.subnet` | string | Cluster subnet CIDR |
| `ocp_manifests_network.gateway` | string | Gateway IP address |
| `ocp_manifests_network.dns_servers` | list | DNS server list |
| `ocp_manifests_nodes` | list | Node configuration list |
| `ocp_manifests_credentials` | dict | Cluster credentials |
| `ocp_manifests_credentials.pull_secret` | string | Container registry pull secret |
| `ocp_manifests_credentials.ssh_key` | string | SSH public key for access |
| `ocp_manifests_output_dir` | string | Output directory for manifests |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ocp_manifests_cluster.version` | string | `4.16.7` | OpenShift version |
| `ocp_manifests_network.interface_name` | string | `eno1` | Network interface name |
| `ocp_manifests_network.cluster_cidr` | string | `10.128.0.0/14` | Pod network CIDR |
| `ocp_manifests_network.service_cidr` | string | `172.30.0.0/16` | Service network CIDR |
| `ocp_manifests_credentials.cert_bundle` | string | - | CA certificate bundle |
| `ocp_manifests_backup` | boolean | `true` | Create backup copies |
| `ocp_manifests_file_mode` | string | `0600` | File permissions for manifests |

### Node Configuration

Each node in `ocp_manifests_nodes` should contain:

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Node hostname |
| `ip` | string | Static IP address |
| `mac` | string | MAC address |
| `role` | string | Node role (`master`, `worker`) |

## Dependencies

None

## Generated Files

- `{output_dir}/install-config.yaml` - OpenShift installation configuration
- `{output_dir}/agent-config.yaml` - Agent-based installation configuration
- `{output_dir}/install-config.yaml.bak` - Backup of install-config (if enabled)
- `{output_dir}/agent-config.yaml.bak` - Backup of agent-config (if enabled)

## Example Playbook

### Single Node OpenShift (SNO)

```yaml
- name: Generate SNO manifests
  hosts: localhost
  tasks:
    - name: Create OpenShift manifests
      ansible.builtin.include_role:
        name: proxshift.openshift.ocp_manifests
      vars:
        ocp_manifests_cluster:
          name: "sno-cluster"
          version: "4.17.1"
        ocp_manifests_network:
          base_domain: "homelab.local"
          subnet: "192.168.1.0/24"
          gateway: "192.168.1.1"
          dns_servers:
            - "192.168.1.1"
            - "8.8.8.8"
          interface_name: "ens192"
        ocp_manifests_nodes:
          - name: "sno-master"
            ip: "192.168.1.100"
            mac: "00:50:56:12:34:56"
            role: "master"
        ocp_manifests_credentials:
          pull_secret: "{{ vault_pull_secret }}"
          ssh_key: "{{ vault_ssh_key }}"
          cert_bundle: "{{ ca_bundle | default('') }}"
        ocp_manifests_output_dir: "/tmp/sno-manifests"
```

### Multi-Node Cluster

```yaml
- name: Generate multi-node manifests
  hosts: localhost
  tasks:
    - name: Create OpenShift manifests
      ansible.builtin.include_role:
        name: proxshift.openshift.ocp_manifests
      vars:
        ocp_manifests_cluster:
          name: "production-cluster"
          version: "4.16.7"
        ocp_manifests_network:
          base_domain: "example.com"
          subnet: "10.0.0.0/24"
          gateway: "10.0.0.1"
          dns_servers:
            - "10.0.0.1"
            - "1.1.1.1"
          cluster_cidr: "10.128.0.0/14"
          service_cidr: "172.30.0.0/16"
        ocp_manifests_nodes:
          - name: "master-1"
            ip: "10.0.0.10"
            mac: "00:50:56:11:11:11"
            role: "master"
          - name: "master-2"
            ip: "10.0.0.11"
            mac: "00:50:56:11:11:12"
            role: "master"
          - name: "master-3"
            ip: "10.0.0.12"
            mac: "00:50:56:11:11:13"
            role: "master"
          - name: "worker-1"
            ip: "10.0.0.20"
            mac: "00:50:56:22:22:21"
            role: "worker"
          - name: "worker-2"
            ip: "10.0.0.21"
            mac: "00:50:56:22:22:22"
            role: "worker"
          - name: "worker-3"
            ip: "10.0.0.22"
            mac: "00:50:56:22:22:23"
            role: "worker"
        ocp_manifests_credentials:
          pull_secret: "{{ registry_credentials }}"
          ssh_key: "{{ admin_ssh_key }}"
        ocp_manifests_output_dir: "/opt/openshift/manifests"
        ocp_manifests_backup: false
```

### Using with Inventory

```yaml
- name: Generate manifests from inventory
  hosts: localhost
  tasks:
    - name: Create manifests for cluster
      ansible.builtin.include_role:
        name: proxshift.openshift.ocp_manifests
      vars:
        cluster_name: "{{ target_cluster }}"
        ocp_manifests_cluster:
          name: "{{ cluster_name }}"
          version: "{{ hostvars[groups[cluster_name][0]]['ocp_version'] }}"
        ocp_manifests_network: "{{ network_defaults }}"
        ocp_manifests_nodes: "{{ groups[cluster_name] | map('extract', hostvars) | list }}"
        ocp_manifests_credentials:
          pull_secret: "{{ vault_values['pull-secret'] }}"
          ssh_key: "{{ vault_values['ssh-key'] }}"
        ocp_manifests_output_dir: "ocp_install/{{ cluster_name }}"
```

## Features

### Automatic Cluster Type Detection

The role automatically detects cluster type based on node count:
- **1 node**: Single Node OpenShift (SNO)
- **2+ nodes**: Multi-node cluster

### Universal Templates

Uses Jinja2 templates that work for both SNO and multi-node deployments:
- Conditional logic for SNO-specific configurations
- Dynamic node role assignments
- Flexible network configurations

### Backup Management

When `ocp_manifests_backup: true` (default):
- Creates `.bak` files for all generated manifests
- Preserves previous configurations during updates

## Template Structure

The role uses two main templates:

1. **install-config.yaml.j2**: Core OpenShift installation configuration
2. **agent-config.yaml.j2**: Agent-based installation configuration

Both templates are designed to handle various cluster topologies and configurations automatically.

## Best Practices

1. **Version Management**: Always specify OpenShift version explicitly
2. **Network Planning**: Ensure subnets don't conflict with existing infrastructure
3. **DNS Configuration**: Verify DNS servers can resolve cluster domains
4. **SSH Keys**: Use dedicated SSH keys for cluster access
5. **Pull Secrets**: Keep pull secrets secure and up-to-date

## License

MIT

## Author Information

ProxShift Development Team
