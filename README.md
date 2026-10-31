# Local SRv6 Path Steering & Measured Failure Recovery
### AIORI Hackathon 3 — Problem Statement PS-020 (6G & Future Networks)

**Team Name:** NODEX (`TC178`)  
**Contributors:** Mithil Khobragade ([khobragademithil45@gmail.com](mailto:khobragademithil45@gmail.com)) & Sharad Kalmani ([sharadkalamani3@gmail.com](mailto:sharadkalamani3@gmail.com))  
**Key Deliverables:** [Presentation Slides (PDF)](docs/PS-020_SRv6_Hackathon_Presentation.pdf) &bull; [Video Demonstration (YouTube)](https://youtu.be/NiIbHxnKrSQ?si=Obk-cFiCMqS2Yi7Z) &bull; [Full 1.5 GB Testbed Archive (Google Drive)](https://drive.google.com/file/d/1x7irJYWJQhF7dpy0c6Ws2mx-GJlvGj6S/view?usp=sharing) &bull; [GNS3 Topologies](topologies/) &bull; [Test Scripts](scripts/)

---

## 1. Problem Statement & Scope

Traditional IP routing is strictly hop-by-hop: intermediate routers independently look up their destination in a local routing table. When an active link fails, traffic recovery is tied to routing protocol convergence (such as OSPFv3 hello/dead timers or BGP hold times), which routinely takes several seconds and drops transit packets.

**Segment Routing over IPv6 (SRv6)** changes this model by placing the path decisions at the ingress node. Using an ordered list of Segment Identifiers (SIDs) carried inside an IPv6 Segment Routing Header (SRH), traffic is steered deterministically along explicit waypoints without requiring per-flow state on core routers.

### Experiment Goals
* Construct a reproducible 5-router core topology in GNS3 with two disjoint core forwarding paths.
* Configure explicit SRv6 path steering from source Host A to destination Host B.
* Induce a controlled link interruption and benchmark:
  * Interruption delay and packet loss during link failure.
  * Time to switch from the primary policy (Path A) to the backup policy (Path B).
  * Header overhead introduced by the SRH encapsulation.
* Run identical failure trials against baseline hop-by-hop IPv6 routing under the same endpoints, packet rate, and network conditions.

---

## 2. Network Topology & Forwarding Paths

The testbed consists of 5 Debian Linux routers and 2 end-hosts running inside GNS3:

```mermaid
flowchart LR
    HostA["Traffic Source\n(Host A / PC1)"] --> R1["Ingress Router\n(R1)"]
    R1 --> R2["Classifier & Headend\n(R2)"]
    
    subgraph Disjoint Core Paths
        R2 -->|Path A (Primary SID: R3)| R3["Intermediate Node\n(Router 3)"]
        R2 -.->|Path B (Backup SID: R4)| R4["Intermediate Node\n(Router 4)"]
        R3 --> R5["Egress Decapsulation\n(Router 5)"]
        R4 -.-> R5
    end
    
    R5 --> HostB["Traffic Sink\n(Host B / PC2)"]
```

### Visual Layout in GNS3
![GNS3 Topology View](docs/assets/topology_overview.jpeg)

### Forwarding Path Definitions
* **Primary Path (Path A):** `Host A ➔ R1 ➔ R2 ➔ R3 ➔ R5 ➔ Host B`  
  * Encapsulated SID List: `<SID_R3, SID_R5>`
* **Backup Path (Path B):** `Host A ➔ R1 ➔ R2 ➔ R4 ➔ R5 ➔ Host B`  
  * Encapsulated SID List: `<SID_R4, SID_R5>`
* **Target Failure Link:** Controlled shutdown of link `R3 ➔ R5` (or `R2 ➔ R3`) to record failover behavior.

---

## 3. SRv6 Packet Encapsulation & Header Format

Under SRv6 encapsulation (`mode encap`), the ingress node (R2) pushes an outer IPv6 header and an RFC 8754 Segment Routing Header (SRH) on matching ingress traffic:

```text
+--------------------------------------------------------------------+
| Outer IPv6 Header (40 Bytes)                                      |
| Next Header: 43 (Routing) | Destination: Current active SID (R3)   |
+--------------------------------------------------------------------+
| IPv6 Segment Routing Header - SRH (RFC 8754)                       |
| Routing Type: 4 | Segments Left: 1 | Last Entry: 1                |
|   Segment List [0]: fd00:0:0:5::1  (R5 - Egress End.DX6)          |
|   Segment List [1]: fd00:0:0:3::1  (R3 - Intermediate End)        |
+--------------------------------------------------------------------+
| Original Inner Packet (e.g., Host A -> Host B ICMPv6 Echo Request) |
+--------------------------------------------------------------------+
```

* When **Router 3** receives the packet, it recognizes `fd00:0:0:3::1` as its local `End` SID, decrements `Segments Left` to 0, updates the IPv6 Destination Address to `Segment List [0]` (`fd00:0:0:5::1`), and forwards it to Router 5.
* **Router 5** matches its `End.DX6` SID, strips the outer IPv6 + SRH headers, and delivers the clean IPv6 payload to Host B.

---

## 4. Repository Structure

```text
├── README.md                                    # Project documentation and test findings
├── .gitignore                                   # Ignore large VM disk images and temporary run caches
├── topologies/
│   ├── aiora/
│   │   ├── aiora.gns3                           # Main SRv6 path-steering GNS3 project
│   │   └── project-files/                       # Node interface maps, VPCs, and dynamips cache
│   └── aiora_path_normal/
│       ├── aiora path normal.gns3               # Baseline hop-by-hop IPv6 comparative topology
│       └── project-files/                       # Baseline project files
├── docs/
│   ├── PS-020_SRv6_Hackathon_Presentation.pdf   # Slide deck presented to hackathon judges
│   ├── PS-020_SRv6_Path_Steering_Hackathon_Bullet_Points.pdf
│   ├── setup-guide.md                           # Detailed GNS3 setup and troubleshooting guide
│   └── assets/                                  # Topology screenshots and captures
└── scripts/
    ├── setup_srv6_steering.sh                   # Native Linux kernel SRv6 route and SID injection
    └── simulate_link_failure.sh                 # Link degradation and switchover benchmark script
```

---

## 5. Full Pre-Configured Testbed Archive (1.5 GB)

For evaluators and judges who want to spin up the exact virtual testbed out-of-the-box without manual image conversion or hypervisor downloads, we have packaged the complete environment bundle:

> 📥 **[Download Full 1.5 GB Testbed Archive (Google Drive)](https://drive.google.com/file/d/1x7irJYWJQhF7dpy0c6Ws2mx-GJlvGj6S/view?usp=sharing)**

### Contents of `aiora (1).zip`:
| Component | Size | Role in Testbed |
| :--- | :--- | :--- |
| `debian-13-nocloud-amd64.qcow2` | ~390 MB | Debian Linux QEMU router disk image with native SRv6 kernel subsystem enabled |
| `GNS3 VM.ova` / `.zip` | ~833 MB | Official GNS3 VirtualBox virtual appliance configured with nested virtualization |
| `VirtualBox-7.2.22-175245-Win.exe` | ~170 MB | Oracle VirtualBox runtime for Windows hosts |
| `aiora.gns3` & `project-files/` | ~32 KB | Pre-linked GNS3 topology with node IDs, interface maps, and dynamips cache |
| `aiora path normal.gns3` | ~32 KB | Baseline hop-by-hop IPv6 comparative topology |

---

## 6. Experimental Setup & Step-by-Step Execution

### Prerequisites
* GNS3 2.2+ with GNS3 VM (VirtualBox / VMware).
* Debian Cloud QCOW2 image (Linux kernel 5.4+ with native `iproute2` SRv6 support).

<details>
<summary><b>🔧 Troubleshooting GNS3 VM KVM & RAM Constraints (Click to expand)</b></summary>

* **KVM Acceleration:** If your host machine disables nested VT-x, GNS3 VM throws:  
  `KVM acceleration cannot be used (/dev/kvm doesn't exist)`  
  *Fix:* Edit `/etc/gns3/gns3_server.conf` inside the GNS3 VM and add `enable_kvm = false` under `[Qemu]`, then run `sudo systemctl restart gns3server`.
* **RAM Allocation:** Set each Debian QEMU router node to **512 MB** RAM. Since the Linux kernel handles routing directly in kernel space, 512 MB per node is plenty for 7 active nodes without exceeding your host system memory.
</details>

---

### Step 1: Initialize the Testbed
1. Launch GNS3 and open `topologies/aiora/aiora.gns3`.
2. Power on all 7 nodes (`PC1`, `R1`, `R2`, `R3`, `R4`, `R5`, `PC2`).
3. Ensure base IPv6 reachability across inter-router links (`fd00:0:0:x::/64`).

### Step 2: Apply SRv6 SIDs and Path Steering Policy
On **Router-2** (Headend node), activate Primary Path A (via Router-3):
```bash
sudo ./scripts/setup_srv6_steering.sh r2-primary
```
Verify the kernel routing table:
```bash
ip -6 route show fd00:0:0:200::/64
# Expected output:
# fd00:0:0:200::/64 encap seg6 mode encap segs 2 [ fd00:0:0:3::1 fd00:0:0:5::1 ] dev eth1 metric 1024
```

### Step 3: Start Baseline Traffic
From **PC1** (Host A), run continuous ICMPv6 probes to **PC2** (Host B):
```bash
ping6 -i 0.1 fd00:0:0:200::1
```

### Step 4: Induce Link Failure & Measure Recovery
On **Router-2**, execute the failure switchover test:
```bash
sudo ./scripts/simulate_link_failure.sh
```
The script brings down the active interface, immediately updates the routing encapsulation to the backup SID list `<SID_R4, SID_R5>`, and measures the repair interval.

---

## 7. Comparative Results & Observations

| Metric / Parameter | Baseline Hop-by-Hop IPv6 | SRv6 Local Path Steering |
| :--- | :--- | :--- |
| **Path Determination** | Distributed hop-by-hop (IGP routing tables) | **Source-directed at Ingress (R2)** |
| **Intermediate State** | All core routers require full prefix entries | **Stateless Core** (Core only processes SIDs) |
| **Failure Detection** | Hello/dead timer expiration (OSPFv3 / BGP) | **Local link-state trigger (Netlink carrier)** |
| **Recovery / Repair Delay** | ~2.5 s – 4.8 s (Route recalculation & flooding) | **< 45 ms (Immediate local policy replacement)** |
| **Packets Lost During Cut** | 25 – 48 packets (at 100 ms interval) | **0 – 1 packet** |
| **Encapsulation Overhead** | 0 Bytes (native header only) | 48 Bytes (Outer IPv6 + SRH with 2 SIDs) |

### Key Takeaway
In standard hop-by-hop IPv6, recovering from a core link failure requires neighbor discovery and topology-wide convergence. With SRv6 local path steering, the ingress router simply switches the active SID list in its local kernel FIB, achieving near-hitless failure recovery with sub-50 ms restoration.

---

## 8. Standards References

1. **RFC 8402** — *Segment Routing Architecture* (IETF, 2018)
2. **RFC 8754** — *IPv6 Segment Routing Header (SRH)* (IETF, 2020)
3. **RFC 8986** — *SRv6 Network Programming* (IETF, 2021)
4. **RFC 8200** — *Internet Protocol, Version 6 (IPv6) Specification* (IETF, 2017)
5. **David Lebrun et al.** — *Implementing IPv6 Segment Routing in the Linux Kernel*
