# ProxShift Changelog

## [Recent Changes] - 2024

### Major Improvements

#### **Script Modernization**
- **BREAKING**: Renamed `tools/ocp_pm.sh` → `proxshift.sh` (moved to project root)
- **BREAKING**: All functions renamed from `ocp.*` to `ps.*` for modern naming
- **BREAKING**: Removed `tools/` directory - script now in project root
- **BREAKING**: Renamed `main.yaml` → `site.yaml` (Ansible best practice)

#### 📝 **Updated Function Names**
| Old Function | New Function | Description |
|--------------|--------------|-------------|
| `ocp.list_clusters` | `ps.clusters` | List available clusters |
| `ocp.provision` | `ps.provision` | Complete cluster provisioning |
| `ocp.generate_manifests` | `ps.generate_manifests` | Generate install manifests |
| `ocp.validate_cluster` | `ps.validate_cluster` | Validate cluster exists |
| `ocp.ansible_*` | `ps.*` | All ansible operations (removed "ansible" prefix) |

#### **Usage Changes**
**Before:**
```bash
source tools/ocp_pm.sh
ocp.provision my-cluster
```

**After:**
```bash
source proxshift.sh
ps.provision my-cluster
```

#### 📚 **Documentation Updates**
- All documentation updated to reflect new script location
- Function reference guide created at `docs/FUNCTION_REFERENCE.md`
- Examples updated with new function names
- Test suite updated and passing

#### **Benefits**
- **Cleaner Interface**: More intuitive `ps.*` naming
- **Easier Access**: Script in project root (no subdirectory)
- **Modern Standards**: Follows Ansible best practices (`site.yaml`)
- **No Legacy Baggage**: Clean slate without backwards compatibility concerns
- **Better UX**: More professional and consistent naming

#### 🔄 **Migration Guide**
1. **Update script loading**:
   ```bash
   # Old
   source tools/ocp_pm.sh
   
   # New  
   source proxshift.sh
   ```

2. **Update function calls**:
   ```bash
   # Old
   ocp.provision my-cluster
   ocp.list_clusters
   
   # New
   ps.provision my-cluster  
   ps.clusters
   ```

3. **Update playbook references**:
   ```bash
   # Old
   ansible-playbook main.yaml
   
   # New
   ansible-playbook site.yaml
   ```

All tests pass and functionality remains identical with the new interface.
