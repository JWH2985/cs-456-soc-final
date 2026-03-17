# CS456 SOC Final Project - Quick Reference Guide
**Project:** Security Operations Center Implementation  
**Created:** February 21, 2026  
**Student:** Jon (jwh29)  
**GCP Project ID:** cs456-soc-final

---

## 🔐 CRITICAL PASSWORDS & CREDENTIALS

### Elasticsearch Credentials
- **elastic user password:** `EsWdmp_QKR=NJzO4jDVU`
  - Use for: Kibana web login, API access, testing
  
- **kibana_system password:** `Vl*VB-7kR4p*rW-Qos03`
  - Use for: Kibana config file only (internal auth to Elasticsearch)

### Important Notes
- elastic = YOUR login to Kibana web interface
- kibana_system = Kibana server's login to Elasticsearch (behind the scenes)
- NEVER confuse these two!

---

## 🌐 VM INFRASTRUCTURE

### VMs Deployed (Zone: us-central1-a)

| VM Name | Purpose | Size | IP Address |
|---------|---------|------|------------|
| **elastic-node** | Elasticsearch + Kibana | e2-medium | Internal: 10.0.1.X<br>External: 34.27.108.121 |
| **logstash-node** | Data processing (ETL) | e2-small | TBD |
| **kafka-node** | Message queue | e2-small | TBD |
| **victim-ubuntu** | Attack target (Linux) | e2-micro (preemptible) | TBD |
| **victim-windows** | Attack target (Windows) | e2-medium (preemptible) | TBD |

### Network Details
- **VPC:** soc-network (custom mode)
- **Subnet:** soc-subnet (10.0.1.0/24)
- **Firewall Rules:**
  - `soc-internal`: VM-to-VM communication (ports: 22, 5044, 5601, 9092, 9200, 9300)
  - `soc-ssh`: SSH access from anywhere (port 22)
  - `soc-kibana`: Kibana web access (port 5601)

---

## 🔗 ACCESS INFORMATION

### Kibana Web Interface
**URL:** http://34.27.108.121:5601  
**Login:**
- Username: `elastic`
- Password: `EsWdmp_QKR=NJzO4jDVU`

**Note:** Use InPrivate/Incognito browser if you encounter JavaScript errors

### SSH Access to VMs
```bash
# Generic format
gcloud compute ssh <vm-name> --zone=us-central1-a

# Examples
gcloud compute ssh elastic-node --zone=us-central1-a
gcloud compute ssh kafka-node --zone=us-central1-a
gcloud compute ssh victim-ubuntu --zone=us-central1-a
```

---

## ⚡ QUICK START COMMANDS

### Start Your Work Session
```powershell
# Start all VMs (PowerShell)
gcloud compute instances start elastic-node logstash-node kafka-node victim-ubuntu victim-windows --zone=us-central1-a

# Wait 2-3 minutes for services to start
# Then access Kibana at: http://34.27.108.121:5601
```

### End Your Work Session (SAVE MONEY!)
```powershell
# Stop all VMs
gcloud compute instances stop elastic-node logstash-node kafka-node victim-ubuntu victim-windows --zone=us-central1-a
```

### Check VM Status
```powershell
# List all VMs with status
gcloud compute instances list

# Get IP addresses
gcloud compute instances list --format="table(name,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP,status)"
```

---

## 📊 CURRENT SYSTEM STATUS

### ✅ Completed Components
- [x] GCP project created with billing
- [x] Custom VPC network configured
- [x] 5 VMs deployed
- [x] Elasticsearch installed and running (status: green)
- [x] Kibana installed and accessible
- [x] Successfully tested queries in Dev Tools

### ⏳ To Be Completed (Next Sessions)
- [ ] Kafka installation and configuration
- [ ] Logstash installation and pipelines
- [ ] Filebeat on victim-ubuntu
- [ ] Winlogbeat + Sysmon on victim-windows
- [ ] Attack scenario implementation
- [ ] Detection rules
- [ ] Kibana dashboards
- [ ] ML anomaly detection

---

## 🏗️ ARCHITECTURE OVERVIEW

```
┌─────────────────────────────────────────────────────────┐
│                    Attack Flow                          │
│                                                         │
│  SSH Brute Force → Compromise → Malicious Payload      │
│  (victim-ubuntu)                                        │
│         ↓                                               │
│    Auth Logs + Syslog                                   │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│              Data Pipeline (Your Phase 1)                │
│                                                         │
│  Filebeat → Kafka → Logstash → Elasticsearch → Kibana  │
│  (victim)   (queue) (process)   (storage)      (viz)    │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                  Detection & Response                    │
│                                                         │
│  • Signature detection (multiple failed SSH)            │
│  • Behavioral detection (unusual downloads)             │
│  • ML anomaly detection (abnormal patterns)             │
│  • Real-time alerting                                   │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 TROUBLESHOOTING

### Elasticsearch Issues
```bash
# Check Elasticsearch status
sudo systemctl status elasticsearch

# View logs
sudo journalctl -u elasticsearch -n 50

# Test connection
curl -u elastic:EsWdmp_QKR=NJzO4jDVU http://localhost:9200
```

### Kibana Issues
```bash
# Check Kibana status
sudo systemctl status kibana

# View logs
sudo journalctl -u kibana -n 50

# Restart if needed
sudo systemctl restart kibana
```

### Common Fixes
1. **Kibana won't start:** Check password in `/etc/kibana/kibana.yml`
2. **JavaScript errors in browser:** Use InPrivate/Incognito mode
3. **Can't connect to Elasticsearch:** Verify firewall rules with `gcloud compute firewall-rules list`
4. **VMs won't start:** Check billing is enabled and quotas not exceeded

---

## 📝 IMPORTANT FILE LOCATIONS

### On elastic-node
```
/etc/elasticsearch/elasticsearch.yml    # Elasticsearch config
/etc/kibana/kibana.yml                 # Kibana config
/var/log/elasticsearch/                # Elasticsearch logs
```

### Configuration Files (Current State)

**elasticsearch.yml:**
```yaml
cluster.name: cs456-soc
node.name: elastic-node
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
xpack.security.enabled: true
xpack.security.enrollment.enabled: true
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false
```

**kibana.yml (active lines):**
```yaml
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "Vl*VB-7kR4p*rW-Qos03"
```

---

## 📅 PROJECT TIMELINE

### Week 1: Infrastructure & Data Pipeline (Current)
**Days 1-2 (Completed):** ✅
- GCP setup
- Network configuration
- Elasticsearch + Kibana installation

**Days 2-3 (Next Session):**
- Kafka setup
- Logstash installation
- Basic pipeline testing

**Days 4-5:**
- Victim machine configuration
- Filebeat setup
- Initial attack scenario

**Days 6-7:**
- Attack automation
- Detection rules
- Initial dashboards

### Week 2: Detection, Analytics & Demo Prep
**Days 8-9:**
- Advanced detection rules
- ML anomaly detection
- Threat intelligence integration

**Days 10-11:**
- Dashboard refinement
- Alerting configuration
- Attack timeline visualization

**Days 12-13:**
- Performance benchmarking
- Technical report writing
- Cold storage setup

**Day 14:**
- Demo rehearsal
- Final touches

---

## 🎯 ATTACK SCENARIO PHASES (Your Responsibility)

### Phase 1: Initial Access
- **Method:** SSH brute force attack
- **Target:** victim-ubuntu weak credentials
- **Detection:** Multiple failed SSH attempts → success pattern
- **Tools:** Hydra, custom Python script

### Phase 2: Execution
- **Method:** Download and execute malicious script
- **Detection:** Suspicious wget/curl activity, new process execution
- **Logs:** Process creation, network connections

---

## 🧪 TESTING & VERIFICATION

### Test Elasticsearch
```bash
# In Kibana Dev Tools Console
GET _cluster/health
GET _cat/indices
GET _cat/nodes
```

### Test Data Pipeline (Once Configured)
```bash
# Generate test SSH attempts
ssh testuser@victim-ubuntu

# Check if logs appear in Elasticsearch
# Kibana → Discover → select index pattern
```

---

## 💡 HELPFUL TIPS

1. **Always use InPrivate/Incognito** for Kibana to avoid cache issues
2. **Stop VMs when not working** - saves significant money
3. **Document everything** as you build - helps with final report
4. **Test incrementally** - verify each component before moving to next
5. **Use Git** to version control all config files
6. **Screenshot dashboards** as you build them for the report
7. **Keep passwords in a secure location** (password manager recommended)

---

## 📚 NEXT SESSION CHECKLIST

When you return to work on this project:

1. **Start VMs:**
   ```powershell
   gcloud compute instances start elastic-node logstash-node kafka-node victim-ubuntu victim-windows --zone=us-central1-a
   ```

2. **Wait 2-3 minutes** for services to fully start

3. **Verify Kibana is accessible:**
   - Open InPrivate browser
   - Navigate to http://34.27.108.121:5601
   - Login with elastic credentials

4. **SSH to kafka-node** and begin Kafka installation:
   ```bash
   gcloud compute ssh kafka-node --zone=us-central1-a
   ```

5. **Reference the main project document** for installation steps

---

## 📞 SUPPORT RESOURCES

- **Elastic Documentation:** https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html
- **Kafka Documentation:** https://kafka.apache.org/documentation/
- **GCP Documentation:** https://cloud.google.com/compute/docs
- **Professor Pouliot:** For project-specific questions
- **Course Textbook:** "Data Engineering for Cybersecurity" - Chapters 4, 6, 8

---

## ⚠️ CRITICAL REMINDERS

- ⚠️ **NEVER commit passwords to Git**
- ⚠️ **ALWAYS shut down VMs when done working**
- ⚠️ **External IP may change** if VMs are stopped/started (update this doc)
- ⚠️ **Preemptible VMs can be terminated** - victim VMs use this to save cost
- ⚠️ **Budget alert set at $100** - monitor spending in GCP console

---

**Last Updated:** February 21, 2026, 11:45 PM PST  
**Status:** Infrastructure phase complete, ready for Kafka setup
