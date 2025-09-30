# 🔐 ProxShift Vault Password Guide

## Automatic Vault Decryption

ProxShift provides **flexible vault password handling**:

### ✅ **With Vault Password File (Recommended)**

```bash
# 1. Create your vault password file
echo "your-secure-password" > config/.vault_pass

# 2. Encrypt your credentials
ansible-vault encrypt config/vault-credentials.yml --vault-password-file config/.vault_pass

# 3. Run ProxShift - automatic decryption!
ocp.provision ocp-sno1
```

**Result**: ✅ Seamless automatic decryption

### ⚠️ **Without Vault Password File**

If `config/.vault_pass` is missing:

```bash
ocp.provision ocp-sno1
```

**Output**:
```
⚠️  Vault password file not found: /path/to/config/.vault_pass
   Ansible will prompt for vault password interactively
Vault password: [user types password]
```

**Result**: ✅ Interactive password prompt

## 🎯 **Behavior Summary**

| Scenario | ProxShift Behavior | User Experience |
|----------|-------------------|-----------------|
| **Vault file exists** | Automatic decryption | Seamless operation |
| **Vault file missing** | Interactive prompt | Manual password entry |
| **File unreadable** | Interactive prompt | Manual password entry |

## 🔧 **Technical Details**

ProxShift implements **smart vault detection**:

1. **Check** if `$PROXSHIFT_VAULT_PASS` file exists
2. **If exists**: Set `ANSIBLE_VAULT_PASSWORD_FILE` for automatic decryption  
3. **If missing**: Let Ansible prompt user for password
4. **Result**: Always works, whether automated or interactive

## 💡 **Best Practices**

- ✅ **Create** `config/.vault_pass` for automation
- ✅ **Use strong** random passwords (20+ characters)  
- ✅ **Keep secure** - never commit vault passwords
- ✅ **Test both** automated and interactive modes

This ensures ProxShift works for both **automated CI/CD** and **interactive development**!
