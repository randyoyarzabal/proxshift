# Demo Features

- Auto imports into ACM, then applies GitOps accordingly via `apply-gitops=true` label.
  - Planned to support stand-alone clusters.
- Disk are currently deleted/recreated via Bash.
  - Start/stop is pure ansible.
  - VM teardown and creation planned to deprecate Bash disk operations.
- Idempotent shell commands.
- Loosely coupled roles.
- Task includes.
- Handlers.
- Fully qualified module/role names.
- Tags for precision runs.
  - Force complete install
  - Target only post, hub, GitOps, storage related tasks.
- oc_kubeadmin role, can be improved to do kubeconfig, or SA logins.
- Check for valid clusters

## Questions

- Best way to login/act on resources for portability?  Currently using an api_key after kubeadmin login.
  - host:
  - api_key:
  - validate_certs: false
  - Other options?

## TODO

- Clean roles to make them completely "loosely coupled."
- (done) Create VMs and deprecate disk shell operations.
- Add feature to only create one disk, then add disks for ODF post-installation, if needed.
  - This will fix the bug in openshift installer where it sometimes uses the scsi1 as the root disk.
