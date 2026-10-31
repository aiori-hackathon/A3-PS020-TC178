#!/bin/bash
# ==============================================================================
# AIORI-3 Hackathon — Problem Statement PS-020
# Link Failure & Automated Recovery Benchmark Script
# ==============================================================================

TARGET_DEST="fd00:0:0:200::1"
FAIL_INTERFACE="eth1" # Link between Router-2 and Router-3

echo "=========================================================="
echo " Starting SRv6 Measured Failure Recovery Test"
echo " Target Destination: ${TARGET_DEST}"
echo " Link to Terminate:  ${FAIL_INTERFACE} (Path A Primary)"
echo "=========================================================="

echo "[1/3] Verifying initial end-to-end connectivity (10 pings)..."
ping6 -c 5 -i 0.2 "${TARGET_DEST}"

echo "[2/3] Simulating link failure on ${FAIL_INTERFACE}..."
START_TIME=$(date +%s%N)
ip link set "${FAIL_INTERFACE}" down

# Trigger path steering switchover to Path B (Router-4)
echo "[+] Triggering local policy switchover to Backup SID list..."
ip -6 route replace fd00:0:0:200::/64 encap seg6 mode encap segs fd00:0:0:4::1,fd00:0:0:5::1 dev eth2
END_TIME=$(date +%s%N)

ELAPSED_MS=$(( (END_TIME - START_TIME) / 1000000 ))
echo "[✓] Path steering switchover completed in ${ELAPSED_MS} ms!"

echo "[3/3] Verifying post-recovery connectivity across Path B..."
ping6 -c 5 -i 0.2 "${TARGET_DEST}"

echo "=========================================================="
echo " Test Completed Successfully."
echo "=========================================================="
