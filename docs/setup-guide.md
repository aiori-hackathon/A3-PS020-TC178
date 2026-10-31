# GNS3 Environment Setup & Reproduction Guide

This guide provides instructions to reproduce the **PS-020: Local SRv6 Path Steering** testbed in GNS3.

---

## 📥 Required Software & Images

Because operating system disk images and hypervisor installers exceed standard Git storage limits (>100MB), please obtain the components from the official direct sources below:

| Component | Recommended Version | Official Source |
| :--- | :--- | :--- |
| **VirtualBox** | 7.0.x / 7.2.x | [Oracle VirtualBox Downloads](https://www.virtualbox.org/wiki/Downloads) |
| **GNS3 GUI & Server** | 2.2.40+ | [GNS3 Official Releases](https://github.com/GNS3/gns3-gui/releases) |
| **GNS3 VM (VirtualBox)** | 2.2.40+ | [GNS3 VM Releases](https://github.com/GNS3/gns3-vm/releases) |
| **Debian Linux Node** | Debian 12 / 13 (Cloud QCOW2) | [Debian Official Cloud Images](https://cloud.debian.org/images/cloud/) |

---

## ⚙️ GNS3 VM Configuration & Troubleshooting

### 1. Resolving KVM Acceleration Warning
If running GNS3 VM without nested hardware virtualization enabled, you may encounter:
> *`KVM acceleration cannot be used (/dev/kvm doesn't exist)`*

**Solution:**
1. Open terminal inside the GNS3 VM (or SSH into it: `gns3@<vm-ip>`).
2. Edit `/etc/gns3/gns3_server.conf`:
   ```ini
   [Qemu]
   enable_kvm = false
   ```
3. Restart the GNS3 server daemon:
   ```bash
   sudo systemctl restart gns3server
   ```

### 2. RAM Sizing for 7 Nodes (5 Routers + 2 Hosts)
Each Debian QEMU node default template may allocate 2048 MB of RAM. To run the full 7-node topology comfortably within an 8 GB or 16 GB host machine:
* Reduce RAM per Debian QEMU router node to **512 MB** or **768 MB** (Linux kernel SRv6 operations require <150 MB of memory).
* Allocate at least **4096 MB** of RAM to the GNS3 VM in VirtualBox settings.

---

## 🚀 Loading the Project

1. Launch GNS3 and connect to your GNS3 VM.
2. Go to **File -> Open Project** (`Ctrl+O`).
3. Select either:
   * `topologies/aiora/aiora.gns3` (SRv6 Path Steering Topology)
   * `topologies/aiora_path_normal/aiora path normal.gns3` (Baseline IPv6 Topology)
4. Power on all nodes.
5. Apply the SRv6 configuration using the provided scripts in `scripts/`.
