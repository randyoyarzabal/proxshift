# ProxShift Certificate Backup & Restore Guide

## Overview

ProxShift provides automated certificate backup and restore functionality for OpenShift clusters, specifically designed for the `ocp-sno1` ACM hub cluster which hosts critical certificate secrets.

## **Key Architecture**

### **Backup Operations (Standalone)**
- **Purpose**: Backup certificates from an EXISTING, running ACM cluster
- **When to use**: Before major changes, regular backup schedule
- **Tags**: `cert_backup` (standalone, does NOT interfere with other operations)
- **Requirements**: Target cluster must be running and accessible

### **Restore Operations (Post-Install)**  
- **Purpose**: Restore certificates to a REBUILT ACM cluster
- **When to use**: During cluster rebuild/provisioning process
- **Tags**: `post,cert_restore` (part of post-install workflow)
- **Requirements**: Target cluster must be freshly provisioned

## 🔐 **Certificate Backup & Restore Features**

### **Reusable Authentication**
- Uses the new `tasks/cluster_login.yml` for consistent authentication
- No duplicate login code - leverages the unified cluster login system
- Proper error handling and status feedback

### **Configurable Operations**
- **Backup**: Save certificate secrets to designated backup directory
- **Restore**: Restore certificate secrets from backup files
- **Granular Control**: Run backup and restore independently
- **Verbose Mode**: Detailed operation logging

## **Quick Usage**

### **Backup Certificate Secrets (From Existing Cluster)**

```bash
# Load ProxShift functions
source proxshift.sh

# Backup certificates from EXISTING ocp-sno1 (dry-run)
ps.backup_certs --dry-run

# Backup certificates from EXISTING ocp-sno1 (actual operation)  
ps.backup_certs
```

**⚠ Important**: The cluster `ocp-sno1` must be running and accessible!

### **Restore Certificate Secrets (To Rebuilt Cluster)**

```bash
# Restore certificates to REBUILT ocp-sno1 (dry-run)
ps.restore_certs --dry-run

# Restore certificates to REBUILT ocp-sno1 (actual operation)
ps.restore_certs
```

**⚠ Important**: Use this ONLY when rebuilding the ACM hub cluster!

## **Configuration**

### **Default Certificate Secrets** (defined in `config/site-config.yaml`)

```yaml
backup_secrets:
  - name: secret-homelab-ca-tls
    namespace: cert-manager
  - name: secret-homelab-io-tls
    namespace: homelab

backup_dir: "{{ gitops_root }}/backups"
```

### **Feature Flags** (in `site.yaml`)

```yaml
backup_operation: false      # Set to true to backup certificate secrets
restore_operation: false     # Set to true to restore certificate secrets
backup_verbose: false        # Enable verbose output for backup/restore operations
enable_backup_restore: true  # Enable certificate backup/restore functionality
```

## **Manual Ansible Usage**

### **Backup Only (Standalone Operation)**

```bash
ansible-playbook site.yaml \
  -e cluster_name=ocp-sno1 \
  -e backup_operation=true \
  --tags=cert_backup
```

**Note**: Uses `cert_backup` tag - does NOT run any post-install tasks!

### **Restore Only (During Cluster Rebuild)**

```bash
ansible-playbook site.yaml \
  -e cluster_name=ocp-sno1 \
  -e restore_operation=true \
  --tags=cert_restore
```

**Note**: Uses `cert_restore` tag - runs as part of post-install workflow!

### **Verbose Backup**
```bash
ansible-playbook site.yaml \
  -e cluster_name=ocp-sno1 \
  -e backup_operation=true \
  -e backup_verbose=true \
  --tags=cert_backup
```

## **Advanced Configuration**

### **Custom Backup Directory**
```bash
ansible-playbook site.yaml \
  -e cluster_name=ocp-sno1 \
  -e backup_operation=true \
  -e backup_dir="/custom/backup/path" \
  --tags=backup
```

### **Custom Certificate Secrets**
```yaml
# Override in your inventory or command line
backup_secrets:
  - name: my-custom-cert
    namespace: my-namespace
  - name: another-cert
    namespace: cert-manager
```

## 📁 **Backup Structure**

The backup directory structure follows this pattern:
```
{{ backup_dir }}/
├── ocp-sno1/
│   ├── cert-manager/
│   │   └── secret-homelab-ca-tls.yaml
│   └── homelab/
│       └── secret-homelab-io-tls.yaml
└── metadata/
    ├── backup-timestamp.txt
    └── cluster-info.yaml
```

## **Workflow Details**

### **Backup Operation**
1. **Authentication**: Login to `ocp-sno1` using `cluster_login.yml`
2. **Validation**: Verify cluster connectivity and secret existence
3. **Export**: Extract certificate secrets to YAML files
4. **Storage**: Save to designated backup directory with timestamps
5. **Verification**: Confirm backup files were created successfully

### **Restore Operation**
1. **Authentication**: Login to `ocp-sno1` using `cluster_login.yml`
2. **Validation**: Verify backup files exist and are readable
3. **Import**: Apply certificate secrets from backup files
4. **Verification**: Confirm secrets were restored successfully
5. **Status**: Report restoration results

## **Integration with ProxShift**

### **Role Integration**
- Uses `proxshift.openshift.secret_management` role
- Consistent variable naming: `secret_management_*`
- Proper argument specifications and validation

### **Authentication Integration**
- Leverages reusable `tasks/cluster_login.yml`
- Eliminates duplicate authentication code
- Consistent with ACM and GitOps operations

### **Tagging System**
- `backup`: Certificate backup operations
- `restore`: Certificate restore operations  
- `post`: Post-installation tasks (includes backup/restore)

## **Target Clusters**

Currently configured for:
- **ocp-sno1**: Primary certificate management cluster
- Easily extendable to other clusters by modifying the cluster condition

## **Troubleshooting**

### **Missing Required Arguments Error**
```
missing required arguments: secret_management_backup_dir, secret_management_cluster, secret_management_secrets
```

**Solution**: This was fixed by updating variable names in `site.yaml` to match the role's argument specifications.

### **Authentication Failed**
```
✗ Login failed for cluster: ocp-sno1
```

**Solutions**:
1. Verify cluster is running and accessible
2. Check vault credentials are correct
3. Ensure cluster API URL is reachable

### **Backup Directory Not Found**
```
Backup directory does not exist: /path/to/backup
```

**Solutions**:
1. Verify `backup_dir` path exists and is writable
2. Check `gitops_root` variable is correctly set
3. Create backup directory manually if needed

### **Secret Not Found**
```
Secret 'secret-name' not found in namespace 'namespace'
```

**Solutions**:
1. Verify secret exists: `oc get secrets -n namespace`
2. Check secret name spelling in configuration
3. Ensure correct namespace is specified

## 📈 **Best Practices**

### **Regular Backups**
- Schedule regular certificate backups
- Test restore procedures periodically
- Keep backups in version control (GitOps repository)

### **Security Considerations**
- Backup files contain sensitive certificate data
- Store in secure, encrypted locations
- Limit access to backup directories
- Use proper file permissions

### **Monitoring**
- Monitor backup success/failure
- Set up alerts for failed backup operations
- Track backup file sizes and timestamps

## **Future Enhancements**

### **Multi-Cluster Support**
- Extend to support additional clusters beyond `ocp-sno1`
- Dynamic cluster selection based on certificates

### **Automated Scheduling**
- Cron job integration for automated backups
- Retention policies for old backup files

### **Enhanced Validation**
- Certificate expiration checking
- Backup integrity verification
- Restore simulation/dry-run

This guide provides comprehensive coverage of ProxShift's certificate backup and restore capabilities, ensuring reliable certificate management for your OpenShift infrastructure.
