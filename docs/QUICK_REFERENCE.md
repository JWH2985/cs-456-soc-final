# SOC Quick Reference Guide

One-page cheat sheet for CS456 SOC operations.

---

## 🔑 Credentials

| Service | Username | Password |
|---------|----------|----------|
| Kibana | elastic | [ELASTIC_PASSWORD] |

**Kibana URL:** `http://[elastic-node-IP]:5601` (IP changes on restart)

---

## ⚡ Essential Commands

### Start Everything
```bash
# 1. Start VMs (wait 2-3 min)
gcloud compute instances start elastic-node logstash-node kafka-node victim-ubuntu victim-windows-np --zone=us-central1-a

# 2. Start Kafka (CRITICAL!)
gcloud compute ssh kafka-node --zone=us-central1-a
~/start-kafka.sh
exit

# 3. Get Kibana IP
gcloud compute instances describe elastic-node --zone=us-central1-a --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
```

### Stop Everything
```bash
gcloud compute instances stop elastic-node logstash-node kafka-node victim-ubuntu victim-windows-np --zone=us-central1-a
```

### Run Complete Attack Chain
```bash
gcloud compute ssh victim-ubuntu --zone=us-central1-a
./phase1-attack.sh
sleep 30
./phase2-attack.sh
exit
```

---

## 📍 VM Internal IPs (Static)

| VM | Internal IP | Purpose |
|----|-------------|---------|
| elastic-node | 10.0.1.2 | Elasticsearch + Kibana |
| logstash-node | 10.0.1.3 | Data processing |
| kafka-node | 10.0.1.4 | Message queue |
| victim-ubuntu | 10.0.1.5 | Linux target |
| victim-windows-np | 10.0.1.6 | Windows target |

---

## 🔍 Kibana Search Queries

| Query | What It Shows |
|-------|---------------|
| `alert_type: ssh_auth_failure` | Failed SSH attempts |
| `alert_type: ssh_success` | Successful logins |
| `weakuser` | All events for weakuser account |
| `koshanian` | Phase 2 lateral movement events |
| `Compress-Archive` | Data exfiltration activity |
| `host.name: victim-windows` | All Windows events |
| `winlog.event_id: 4624` | Windows successful logins |
| `winlog.event_id: 4625` | Windows failed logins |

---

## 🛠️ Common Tasks

### Get All VM IPs
```bash
gcloud compute instances list --format="table(name,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP,status)"
```

### SSH to Any VM
```bash
gcloud compute ssh <vm-name> --zone=us-central1-a
# Options: elastic-node, logstash-node, kafka-node, victim-ubuntu, victim-windows
```

### Check Kafka Status
```bash
gcloud compute ssh kafka-node --zone=us-central1-a
jps  # Should show: QuorumPeerMain, Kafka
exit
```

### Check Service Status
```bash
# On elastic-node
sudo systemctl status elasticsearch
sudo systemctl status kibana

# On logstash-node
sudo systemctl status logstash

# On victim-ubuntu
sudo systemctl status filebeat
```

### View Logs
```bash
# Logstash logs
sudo journalctl -u logstash -f

# Elasticsearch logs
sudo journalctl -u elasticsearch -f

# Filebeat logs
sudo journalctl -u filebeat -f
```

---

## 🚨 Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| Can't access Kibana | Get new IP: `gcloud compute instances describe elastic-node --zone=us-central1-a --format="get(networkInterfaces[0].accessConfigs[0].natIP)"` |
| No data in Kibana | 1. Start Kafka (`~/start-kafka.sh`)<br>2. Set time to "Last 24 hours" |
| SSH refused | Start VMs: `gcloud compute instances start ...` |
| Attack script not found | Check: `ls -la ~/phase*.sh` on victim-ubuntu |

---

## 📊 Dashboard Locations

**In Kibana:**
1. Hamburger menu (☰) → **Analytics** → **Dashboard**
2. Select:
   - **"Phase 1: SSH Brute Force Attack"**
   - Phase 2 dashboards (if created)

**In Discover:**
1. Hamburger menu (☰) → **Analytics** → **Discover**
2. Set time range: **"Last 24 hours"** or **"Today"**
3. Enter search query (see table above)

---

## 🔄 Typical Workflow

```bash
# 1. Start infrastructure
gcloud compute instances start elastic-node logstash-node kafka-node victim-ubuntu victim-windows-np --zone=us-central1-a

# 2. Wait 2-3 minutes

# 3. Start Kafka
gcloud compute ssh kafka-node --zone=us-central1-a
~/start-kafka.sh
exit

# 4. Get Kibana URL and open in browser
gcloud compute instances describe elastic-node --zone=us-central1-a --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
# Open: http://[IP]:5601
# Login: elastic / [ELASTIC_PASSWORD]

# 5. Run attacks
gcloud compute ssh victim-ubuntu --zone=us-central1-a
./phase1-attack.sh
sleep 30
./phase2-attack.sh
exit

# 6. View results in Kibana
# Navigate to Dashboard or Discover

# 7. When finished - STOP VMs
gcloud compute instances stop elastic-node logstash-node kafka-node victim-ubuntu victim-windows-np --zone=us-central1-a
```

---

## 💾 User Accounts

### victim-ubuntu (Linux)
- **weakuser** / `[WEAKUSER_PASSWORD]` (attack target)
- **Jwh29** (admin access via SSH key)

### victim-windows-np (Windows)
- **koshanian** / `[KOSHANIAN_PASSWORD]` (Phase 2 target)

---

## 🎯 Attack Script Locations

Both scripts are in: `/home/Jwh29/` on **victim-ubuntu**

```bash
/home/Jwh29/phase1-attack.sh  # SSH brute force
/home/Jwh29/phase2-attack.sh  # Lateral movement + exfil
```

---

## 📞 Quick Help

**Stuck? Common fixes:**
1. ✅ Did you start Kafka? (`~/start-kafka.sh` on kafka-node)
2. ✅ Did you wait 2-3 min after starting VMs?
3. ✅ Is time range set to "Last 24 hours" in Kibana?
4. ✅ Are you looking at the right index? (should be `soc-logs-*`)

---

**Project:** CS456 SOC Final  
**Team:** Jon Harmon, Nareg Koshanian  
**Last Updated:** March 2026
