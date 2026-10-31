# GNS3 Testbed Setup & Troubleshooting Guide

This guide provides instructions to reproduce the **PS-020: Local SRv6 Path Steering** testbed in GNS3.

---

## 1. Quick Requirements

* **GNS3 GUI & Server:** v2.2.40 or higher
* **GNS3 VM:** VirtualBox or VMware Workstation appliance
* **Router Image:** Debian Cloud QCOW2 (Linux kernel 5.4+ with `iproute2` SRv6 support)

> 💡 *All required binaries (`GNS3 VM.ova`, `VirtualBox installer`, `debian-13-nocloud-amd64.qcow2`, and the pre-configured project files) are bundled in the [1.5 GB Testbed Archive](https://drive.google.com/file/d/1x7irJYWJQhF7dpy0c6Ws2mx-GJlvGj6S/view?usp=sharing).*

---

## 2. GNS3 VM Troubleshooting

### KVM Acceleration Warning
If running the GNS3 VM on Windows without nested hardware virtualization, you may encounter:
```text
KVM acceleration cannot be used (/dev/kvm doesn't exist)
```

**Fix:**
1. Open the GNS3 VM shell (or SSH as user `gns3`).
2. Edit `/etc/gns3/gns3_server.conf`:
   ```ini
   [Qemu]
   enable_kvm = false
   ```
3. Restart the service:
   ```bash
   sudo systemctl restart gns3server
   ```

### Node Memory Allocation
The default QEMU Debian appliance template might reserve 2048 MB RAM per instance. To run all 7 nodes simultaneously on standard workstation hardware:
* Reduce RAM per router node to **512 MB** (Linux kernel SRv6 forwarding requires under 120 MB runtime memory).
* Allocate at least **4096 MB** RAM to the GNS3 VM in your hypervisor settings.

---

## 3. Importing and Running the Lab

1. Launch GNS3 and ensure the GNS3 VM indicator is green.
2. Go to **File -> Open Project** (`Ctrl+O`).
3. Browse to the cloned repository and open:
   * Primary lab: `topologies/aiora/aiora.gns3`
   * Baseline lab: `topologies/aiora_path_normal/aiora path normal.gns3`
4. Click **Start all nodes** (green play button).
5. Open consoles for `PC1`, `Router-2`, and `PC2`.
6. Apply routing rules using the scripts in `scripts/`:
   ```bash
   # On Router-2
   sudo ./scripts/setup_srv6_steering.sh r2-primary
   ```
7. Verify end-to-end traffic from `PC1`:
   ```bash
   ping6 fd00:0:0:200::1
   ```
