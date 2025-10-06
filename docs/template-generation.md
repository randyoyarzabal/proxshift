# 📄 ProxShift Template Generation Guide

## New Function: `my-production-cluster.generate_manifests`

### Purpose

Generate OpenShift manifest files (templates) without proceeding with full cluster provisioning. Perfect for:

- **Template validation** before provisioning
- **Testing** new cluster configurations 
- **Comparing** against previous template files
- **Debugging** template logic

### Usage

```bash
# Generate templates for my-cluster
my-production-cluster.generate_manifests my-cluster

# Preview what would be generated (dry-run)
my-production-cluster.generate_manifests my-cluster --dry-run

# Available for all clusters
my-production-cluster.generate_manifests my-production-cluster        # Multi-node cluster
my-production-cluster.generate_manifests my-sno-cluster   # SNO cluster
```

### What It Does

1. ✓ **Validates** cluster name exists in inventory
2. ✓ **Retrieves** secrets from HashiCorp Vault 
3. ✓ **Generates** `install-config.yaml` from universal template
4. ✓ **Generates** `agent-config.yaml` from universal template
5. ✓ **Creates** backup copies (`.bak` files)
6. ✗ **Skips** ISO creation, VM provisioning, and post-install tasks

### Generated Files

```
my-production-cluster_install/<cluster>/
├── install-config.yaml     # OpenShift install configuration
├── agent-config.yaml       # Agent-based installer configuration  
├── install-config.yaml.bak # Backup copy
└── agent-config.yaml.bak   # Backup copy
```

### Example Output

```bash
$ my-production-cluster.generate_manifests my-cluster

📄 Generating OpenShift manifest templates for: my-cluster
   Output directory: my-production-cluster_install/my-cluster/
   Files: install-config.yaml, agent-config.yaml

[Ansible playbook runs...]

✓ Template generation completed successfully!
📂 Generated files:
   - my-production-cluster_install/my-cluster/install-config.yaml
   - my-production-cluster_install/my-cluster/agent-config.yaml  
   - my-production-cluster_install/my-cluster/install-config.yaml.bak
   - my-production-cluster_install/my-cluster/agent-config.yaml.bak

Use 'my-production-cluster.provision my-cluster' to proceed with full cluster provisioning
```

### Template Validation Workflow

```bash
# 1. Generate templates
my-production-cluster.generate_manifests my-cluster

# 2. Review generated files
cat my-production-cluster_install/my-cluster/install-config.yaml
cat my-production-cluster_install/my-cluster/agent-config.yaml

# 3. Compare with previous version (if needed)
diff my-production-cluster_install/my-cluster/install-config.yaml previous_version.yaml

# 4. If satisfied, proceed with full provisioning
my-production-cluster.provision my-cluster
```

### Benefits

- **Fast** - No VM operations or ISO creation
- **Safe** - Review before provisioning  
- 🧪 **Testing** - Validate template logic
- 📊 **Comparison** - Easy to diff against previous versions
- 🐛 **Debugging** - Isolate template issues from infrastructure issues