# 📄 ProxShift Template Generation Guide

## New Function: `ocp.generate_manifests`

### Purpose

Generate OpenShift manifest files (templates) without proceeding with full cluster provisioning. Perfect for:

- **Template validation** before provisioning
- **Testing** new cluster configurations 
- **Comparing** against previous template files
- **Debugging** template logic

### Usage

```bash
# Generate templates for ocp-sno3
ocp.generate_manifests ocp-sno3

# Preview what would be generated (dry-run)
ocp.generate_manifests ocp-sno3 --dry-run

# Available for all clusters
ocp.generate_manifests ocp        # Multi-node cluster
ocp.generate_manifests ocp-sno1   # SNO cluster
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
ocp_install/<cluster>/
├── install-config.yaml     # OpenShift install configuration
├── agent-config.yaml       # Agent-based installer configuration  
├── install-config.yaml.bak # Backup copy
└── agent-config.yaml.bak   # Backup copy
```

### Example Output

```bash
$ ocp.generate_manifests ocp-sno3

📄 Generating OpenShift manifest templates for: ocp-sno3
   Output directory: ocp_install/ocp-sno3/
   Files: install-config.yaml, agent-config.yaml

[Ansible playbook runs...]

✓ Template generation completed successfully!
📂 Generated files:
   - ocp_install/ocp-sno3/install-config.yaml
   - ocp_install/ocp-sno3/agent-config.yaml  
   - ocp_install/ocp-sno3/install-config.yaml.bak
   - ocp_install/ocp-sno3/agent-config.yaml.bak

Use 'ocp.provision ocp-sno3' to proceed with full cluster provisioning
```

### Template Validation Workflow

```bash
# 1. Generate templates
ocp.generate_manifests my-cluster

# 2. Review generated files
cat ocp_install/my-cluster/install-config.yaml
cat ocp_install/my-cluster/agent-config.yaml

# 3. Compare with previous version (if needed)
diff ocp_install/my-cluster/install-config.yaml previous_version.yaml

# 4. If satisfied, proceed with full provisioning
ocp.provision my-cluster
```

### Benefits

- **Fast** - No VM operations or ISO creation
- **Safe** - Review before provisioning  
- 🧪 **Testing** - Validate template logic
- 📊 **Comparison** - Easy to diff against previous versions
- 🐛 **Debugging** - Isolate template issues from infrastructure issues