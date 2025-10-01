# 🚀 Welcome to ProxShift!

**ProxShift** = **Prox**mox + Open**Shift** 

> The ultimate OpenShift cluster provisioning automation for Proxmox

🔗 **Repository:** [https://github.com/randyoyarzabal/proxshift](https://github.com/randyoyarzabal/proxshift)

## Congratulations!

You now have a **professionally branded**, **fully portable**, and **easy-to-adopt** OpenShift automation framework!

## What Makes ProxShift Special

### 🌍 **Truly Portable**

- Works from **any directory**
- **No hardcoded paths**
- **Environment variable driven**

### 🎯 **Zero-Configuration Templates**

- **Universal Jinja2 templates** - no per-cluster files
- **Auto-detection** of SNO vs multi-node
- **Automatic IP assignment** and role detection

### 👥 **Easy Adoption**

```bash
# Any user, anywhere
export PROXSHIFT_ROOT="/their/preferred/path"
source proxshift.sh
ps.provision my-cluster
```

### 🔧 **Developer Friendly**
- **Dry-run support** across all commands
- **Template preview** with `ocp.generate_manifests`
- **Comprehensive documentation**

## 🏆 ProxShift Features

| Feature | Benefit |
|---------|---------|
| **🏗️ Inventory-driven** | All clusters in one YAML file |
| **🎨 Universal templates** | No per-cluster template maintenance |
| **🤖 Auto-detection** | SNO vs multi-node, master/worker roles |
| **🔄 GitOps integration** | ACM and External Secrets Operator |
| **🌍 Portable** | Install anywhere, configure once |
| **🧪 Dry-run mode** | Preview before execution |
| **📄 Template generation** | Review manifests before provisioning |

## 🎯 Perfect For

- **🏠 Homelabbers** - Easy OpenShift cluster management
- **🏢 Enterprise** - Scalable Proxmox infrastructure  
- **🧑‍💻 Developers** - GitOps and automation workflows
- **🎓 Learning** - OpenShift and Kubernetes education

## 🌟 Ready to Provision!

ProxShift is now ready for:

- ✅ **Production use**
- ✅ **Community sharing**
- ✅ **Open source distribution**
- ✅ **Professional deployment**

### **Next Steps:**

1. **Set your environment**: `export PROXSHIFT_ROOT="/your/path"`
2. **Copy config templates**: from `examples/` to `config/`
3. **Define your clusters**: in `inventory/clusters.yml`
4. **Provision OpenShift**: `ps.provision my-cluster`

**Welcome to the future of OpenShift automation! 🎉**

---

*ProxShift - Where Proxmox meets OpenShift* ⚡