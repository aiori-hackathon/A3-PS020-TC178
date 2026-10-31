#!/bin/bash
# ==============================================================================
# AIORI-3 Hackathon — Problem Statement PS-020
# Local SRv6 Path Steering Configuration Script
# Team: NODEX | Code: TC178
# ==============================================================================

set -e

echo "[+] Initializing Linux Kernel SRv6 Subsystem..."

# 1. Enable IPv6 forwarding and Segment Routing (seg6) on all interfaces
sysctl -w net.ipv6.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.seg6_enabled=1
sysctl -w net.ipv6.conf.default.seg6_enabled=1

for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo'); do
    sysctl -w net.ipv6.conf."${iface}".seg6_enabled=1
    echo "    Enabled seg6 on ${iface}"
done

# 2. Node Address and SID Definitions
# Prefix space: fd00:0:0:x::/64
# Host A (PC1): fd00:0:0:100::1/64
# Host B (PC2): fd00:0:0:200::1/64
#
# Segment Identifiers (SIDs):
# R1: fd00:0:0:1::1
# R2: fd00:0:0:2::1
# R3: fd00:0:0:3::1 (Primary intermediate hop)
# R4: fd00:0:0:4::1 (Backup intermediate hop)
# R5: fd00:0:0:5::1 (Egress decap router)

NODE_ROLE=${1:-"r2"}

case "${NODE_ROLE}" in
    "r2-primary")
        echo "[+] Configuring Ingress SRv6 Policy on Router-2 (Path A - via Router-3)..."
        # Encap mode: Source encodes SID list <R3, R5> to reach PC2 destination
        ip -6 route replace fd00:0:0:200::/64 encap seg6 mode encap segs fd00:0:0:3::1,fd00:0:0:5::1 dev eth1
        echo "[✓] Primary Path Steering Activated: PC1 -> R1 -> R2 -> [R3] -> R5 -> PC2"
        ;;

    "r2-backup")
        echo "[!] Steering Traffic to Backup Path (Path B - via Router-4)..."
        # Encap mode: Source reroutes SID list <R4, R5>
        ip -6 route replace fd00:0:0:200::/64 encap seg6 mode encap segs fd00:0:0:4::1,fd00:0:0:5::1 dev eth2
        echo "[✓] Backup Path Steering Activated: PC1 -> R1 -> R2 -> [R4] -> R5 -> PC2"
        ;;

    "r3-end")
        echo "[+] Binding End SID on Router-3..."
        ip -6 route add fd00:0:0:3::1/128 encap seg6local action End dev eth0
        ;;

    "r4-end")
        echo "[+] Binding End SID on Router-4..."
        ip -6 route add fd00:0:0:4::1/128 encap seg6local action End dev eth0
        ;;

    "r5-decap")
        echo "[+] Binding End.DX6 (Decapsulation and Forwarding) on Egress Router-5..."
        ip -6 route add fd00:0:0:5::1/128 encap seg6local action End.DX6 nh6 fd00:0:0:200::1 dev eth1
        ;;

    *)
        echo "Usage: $0 {r2-primary | r2-backup | r3-end | r4-end | r5-decap}"
        exit 1
        ;;
esac

echo "[✓] Configuration applied successfully."
