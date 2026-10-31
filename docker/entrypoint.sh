#!/bin/bash
# ==============================================================================
# Entrypoint for SRv6 Docker Node
# Configures kernel parameters, interfaces, and SRv6 SIDs based on NODE_ROLE
# ==============================================================================

set -e

echo "[*] Booting container ${HOSTNAME} with role: ${NODE_ROLE:-generic}"

# Enable IPv6 forwarding and seg6 on all interfaces if container has NET_ADMIN
sysctl -w net.ipv6.conf.all.forwarding=1 2>/dev/null || true
sysctl -w net.ipv6.conf.all.seg6_enabled=1 2>/dev/null || true
sysctl -w net.ipv6.conf.default.seg6_enabled=1 2>/dev/null || true

for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo'); do
    sysctl -w net.ipv6.conf."${iface}".seg6_enabled=1 2>/dev/null || true
done

# Role-specific network configurations
case "${NODE_ROLE}" in
    "pc1")
        echo "[+] Setting default route on PC1 -> R1 (fd00:0:0:100::254)"
        ip -6 route add default via fd00:0:0:100::254 dev eth0 2>/dev/null || true
        ;;

    "router-1")
        echo "[+] Configuring Router-1 transit routes"
        ip -6 route add fd00:0:0:200::/64 via fd00:0:0:12::2 dev eth1 2>/dev/null || true
        ;;

    "router-2")
        echo "[+] Configuring Headend Policy on Router-2"
        # Primary Path A via Router-3 (SID R3: fd00:0:0:3::1, SID R5: fd00:0:0:5::1)
        ip -6 route replace fd00:0:0:200::/64 encap seg6 mode encap segs fd00:0:0:3::1,fd00:0:0:5::1 dev eth1 2>/dev/null || true

        # Helper scripts for interactive testing inside container
        cat << 'EOF' > /root/switch_to_backup.sh
#!/bin/bash
echo "[!] Switching Router-2 steering policy to Path B (via Router-4)..."
ip -6 route replace fd00:0:0:200::/64 encap seg6 mode encap segs fd00:0:0:4::1,fd00:0:0:5::1 dev eth2
echo "[✓] Traffic steered through Router-4!"
EOF
        chmod +x /root/switch_to_backup.sh

        cat << 'EOF' > /root/switch_to_primary.sh
#!/bin/bash
echo "[+] Restoring Router-2 steering policy to Path A (via Router-3)..."
ip -6 route replace fd00:0:0:200::/64 encap seg6 mode encap segs fd00:0:0:3::1,fd00:0:0:5::1 dev eth1
echo "[✓] Traffic restored through Router-3!"
EOF
        chmod +x /root/switch_to_primary.sh
        ;;

    "router-3")
        echo "[+] Configuring Transit End SID on Router-3 (fd00:0:0:3::1)"
        ip -6 route add fd00:0:0:3::1/128 encap seg6local action End dev eth0 2>/dev/null || true
        ;;

    "router-4")
        echo "[+] Configuring Backup Transit End SID on Router-4 (fd00:0:0:4::1)"
        ip -6 route add fd00:0:0:4::1/128 encap seg6local action End dev eth0 2>/dev/null || true
        ;;

    "router-5")
        echo "[+] Configuring Egress Decap SID on Router-5 (fd00:0:0:5::1 -> PC2)"
        ip -6 route add fd00:0:0:5::1/128 encap seg6local action End.DX6 nh6 fd00:0:0:200::1 dev eth2 2>/dev/null || true
        ;;

    "pc2")
        echo "[+] Setting default route on PC2 -> R5 (fd00:0:0:200::254)"
        ip -6 route add default via fd00:0:0:200::254 dev eth0 2>/dev/null || true
        ;;
esac

echo "[✓] Node ${HOSTNAME} is ready."

# Keep container alive
exec tail -f /dev/null
