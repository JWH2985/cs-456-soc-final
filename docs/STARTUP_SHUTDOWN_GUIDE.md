# SOC Infrastructure Startup & Shutdown Guide

**For:** CS456 SOC Final Project  
**Team:** Jon Harmon, Nareg Koshanian

---

## 🔐 Login Credentials

### Kibana Web Interface
- **URL:** `http://[ELASTIC-NODE-EXTERNAL-IP]:5601`
  - *Note: IP changes every time VMs restart (see "Get Current IPs" below)*
- **Username:** `elastic`

### GCP Project
- **Project ID:** `cs456-soc-final`
- **Zone:** `us-central1-a`

---

## 🚀 Complete Startup Procedure

### Step 1: Authenticate with Google Cloud (First Time Only)

```bash
# Login to GCP
gcloud auth login

# Set the project
gcloud config set project cs456-soc-final
```

### Step 2: Start All VMs

```bash
gcloud compute instances start elastic-node logstash-node kafka-node \
  victim-ubuntu victim-windows-np --zone=us-central1-a
```

⏱️ **Wait 2-3 minutes** for VMs to fully boot.

### Step 3: Get Current External IPs

```bash
gcloud compute instances list \
  --format="table(name,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP,status)"
```

**Look for `elastic-node`'s EXTERNAL_IP** - this is your Kibana URL.

### Step 4: Start Kafka ⚠️ CRITICAL

**Kafka does NOT auto-start!** You must manually start it after every VM restart.

```bash
# SSH to kafka-node
gcloud compute ssh kafka-node --zone=us-central1-a

# Run startup script
~/start-kafka.sh

# Verify (should see QuorumPeerMain and Kafka)
jps

# Exit
exit
```

**Expected output from `jps`:**
```
1234 QuorumPeerMain
5678 Kafka
9012 Jps
```

### Step 5: Verify Everything is Running

**Open Kibana:**
- Navigate to: `http://[ELASTIC-NODE-EXTERNAL-IP]:5601`
- Login
- You should see the Kibana home screen

✅ **All systems ready!**

---

## 🔬 Running Attack Scenarios

### Phase 1: SSH Brute Force Attack

```bash
# SSH to victim-ubuntu
gcloud compute ssh victim-ubuntu --zone=us-central1-a

# Run Phase 1 attack
./phase1-attack.sh

# Exit
exit
```

**Expected behavior:**
- 30+ password attempts (failures)
- 1 successful authentication
- Malicious payload deployment
- Persistence mechanism installation

### Phase 2: Lateral Movement & Exfiltration

```bash
# SSH to victim-ubuntu
gcloud compute ssh victim-ubuntu --zone=us-central1-a

# Run Phase 2 attack
./phase2-attack.sh

# Exit
exit
```

**Expected behavior:**
- SSH from Ubuntu → Windows
- File discovery (C:\Sensitive)
- Data compression (stolen.zip)
- Exfiltration via SCP

### Complete Attack Chain (Both Phases)

```bash
# SSH to victim-ubuntu
gcloud compute ssh victim-ubuntu --zone=us-central1-a

# Run both phases
./phase1-attack.sh
sleep 30
./phase2-attack.sh

# Exit
exit
```

---

## 📊 Viewing Results in Kibana

### Access Dashboards

1. Open Kibana (see credentials above)
2. Click hamburger menu (☰) → **Analytics** → **Dashboard**
3. Select:
   - **"Phase 1: SSH Brute Force Attack"** (Jon's dashboard)
   - **Phase 2 dashboards**

### Search Raw Events

1. Click hamburger menu (☰) → **Analytics** → **Discover**
2. Set time range: **"Last 24 hours"** or **"Today"**
3. Search examples:
   ```
   alert_type: ssh_auth_failure
   koshanian
   weakuser
   Compress-Archive
   host.name: victim-windows
   ```

---

## 🛑 Shutdown Procedure

**⚠️ ALWAYS SHUT DOWN WHEN FINISHED!**

Running VMs cost money. Always stop them when not actively working.

```bash
gcloud compute instances stop elastic-node logstash-node kafka-node \
  victim-ubuntu victim-windows-np --zone=us-central1-a
```

**Confirm all VMs stopped:**
```bash
gcloud compute instances list --format="table(name,status)"
```

All should show **TERMINATED**.

---

## 🔧 Troubleshooting

### ❌ "Can't connect to Kibana"

**Problem:** External IP changed after VM restart

**Solution:**
```bash
gcloud compute instances describe elastic-node --zone=us-central1-a \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
```

Use the new IP to access Kibana.

---

### ❌ "No data in Kibana dashboards"

**Problem:** Kafka isn't running

**Solution:**
```bash
# SSH to kafka-node
gcloud compute ssh kafka-node --zone=us-central1-a

# Start Kafka
~/start-kafka.sh

# Verify
jps  # Should show QuorumPeerMain and Kafka

exit
```

**Also check time range:** Set to "Last 24 hours" or "Today" in Kibana.

---

### ❌ "SSH connection refused"

**Problem:** VMs are stopped

**Solution:** Run the startup procedure from Step 2.

---

### ❌ "Kafka startup script not found"

**Problem:** Script doesn't exist on kafka-node

**Solution:** Recreate it manually:

```bash
# SSH to kafka-node
gcloud compute ssh kafka-node --zone=us-central1-a

# Create script
cat > ~/start-kafka.sh << 'EOF'
#!/bin/bash
echo "Starting Kafka services..."
cd ~/kafka_2.13-3.9.0

echo "[1/2] Starting ZooKeeper..."
bin/zookeeper-server-start.sh -daemon config/zookeeper.properties
sleep 5

echo "[2/2] Starting Kafka..."
bin/kafka-server-start.sh -daemon config/server.properties
sleep 10

echo "Checking status..."
jps

echo ""
echo "✅ Done! ZooKeeper and Kafka should be running."
EOF

# Make executable
chmod +x ~/start-kafka.sh

# Test it
~/start-kafka.sh

exit
```

---

## 📝 Quick Command Reference

### Get Kibana URL
```bash
gcloud compute instances describe elastic-node --zone=us-central1-a \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
# Then open: http://[IP]:5601
```

### SSH to Any VM
```bash
gcloud compute ssh <vm-name> --zone=us-central1-a
# Replace <vm-name> with: elastic-node, logstash-node, kafka-node, victim-ubuntu, or victim-windows
```

### Check VM Status
```bash
gcloud compute instances list --format="table(name,status,networkInterfaces[0].accessConfigs[0].natIP)"
```

### Restart a Single VM
```bash
gcloud compute instances start <vm-name> --zone=us-central1-a
gcloud compute instances stop <vm-name> --zone=us-central1-a
```

---

## 💡 Best Practices

1. **Always start Kafka first** - Nothing will work without it
2. **Check time range in Kibana** - Set to "Last 24 hours" to see recent events
3. **Stop VMs when done** - Prevents unnecessary costs
4. **Wait 2-3 minutes after starting VMs** - Services need time to initialize
5. **Refresh dashboards** - Click the refresh button after running attacks

---

## 📧 Support

**Questions or Issues?**
- **Jon Harmon:** harmonj1@sou.edu
- **Nareg Koshanian:** koshanian@sou.edu

---

**Last Updated:** March 2026  
**Project Due:** March 16, 2026
