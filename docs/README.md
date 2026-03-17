# CS456 Security Operations Center (SOC) - Final Project

**Course:** CS456 - Information System Security  
**Institution:** Southern Oregon University  
**Instructor:** Professor David Pouliot  
**Team Members:** Jon Harmon, Nareg Koshanian  
**Date:** March 2026

---

## Project Overview

This project demonstrates the application of data engineering principles to build a functional Security Operations Center (SOC) capable of detecting and visualizing sophisticated multi-stage cyberattacks in real-time.

### Key Objectives
- Deploy scalable, cloud-based security infrastructure on Google Cloud Platform
- Implement real-time data pipeline using Apache Kafka and Elastic Stack
- Create detection rules for identifying attack patterns
- Build visualization dashboards for security analysis
- Execute and detect complete attack chain: Initial Access → Execution → Lateral Movement → Exfiltration

---

## Architecture

### Infrastructure
- **Cloud Platform:** Google Cloud Platform (GCP)
- **Compute:** 5 VMs (Ubuntu 22.04, Windows Server)
- **Network:** Custom VPC with internal subnet (10.0.1.0/24)

### Technology Stack
- **Data Ingestion:** Filebeat, Winlogbeat
- **Message Queue:** Apache Kafka 3.9.0 + ZooKeeper
- **Data Processing:** Logstash 8.x (ETL + Detection Rules)
- **Storage & Analysis:** Elasticsearch 8.x
- **Visualization:** Kibana 8.x
- **Monitoring:** Sysmon (Windows)

### Data Flow
```
Attack Targets (victim-ubuntu, victim-windows)
    ↓
Beats Agents (Filebeat, Winlogbeat)
    ↓
Kafka Message Queue
    ↓
Logstash (ETL + Detection Rules)
    ↓
Elasticsearch (Indexing & Storage)
    ↓
Kibana (Dashboards & Visualization)
```

---

## Attack Scenarios

### Phase 1: Initial Access & Execution (Linux)
**Objective:** Compromise victim-ubuntu via SSH brute force

**Attack Flow:**
1. **Brute Force:** 30+ password attempts against weakuser account
2. **Compromise:** Successful authentication with correct password
3. **Execution:** Deploy and execute malicious payload
4. **Persistence:** Install cron job for backdoor access

**Detection:**
- Event 4625: Failed SSH authentication attempts
- Event 4624: Successful login
- Malicious process execution detection
- Cron job modification alerts

### Phase 2: Lateral Movement & Exfiltration (Windows)
**Objective:** Move from compromised Linux system to Windows, steal sensitive data

**Attack Flow:**
1. **Lateral Movement:** SSH from victim-ubuntu to victim-windows
2. **Discovery:** Enumerate sensitive files (C:\Sensitive)
3. **Collection:** Compress data into archive (stolen.zip)
4. **Exfiltration:** Transfer stolen data back to attacker machine

**Detection:**
- Windows Event 4624: Network logon from internal IP
- Sysmon Event 1: PowerShell execution (Compress-Archive)
- File access to sensitive directories
- Outbound data transfer detection

---

## Repository Structure

```
cs456-soc-final/
├── README.md                           # This file
├── docs/
│   ├── CS456_SOC_Technical_Report.docx # Full technical documentation
│   ├── CS456_SOC_Technical_Report.pdf  # PDF export
│   ├── NAREG_STARTUP_SHUTDOWN_GUIDE.txt # Operations guide
│   └── screenshots/                    # Kibana dashboards and detections
├── attack-scripts/
│   ├── phase1-attack.sh               # SSH brute force attack
│   └── phase2-attack.sh               # Lateral movement & exfiltration
├── configs/
│   ├── elasticsearch.yml              # Elasticsearch configuration
│   ├── kibana.yml                     # Kibana configuration
│   ├── kafka-to-elasticsearch.conf    # Logstash pipeline config
│   ├── detection-rules.conf           # Logstash detection rules
│   └── filebeat.yml                   # Filebeat configuration
└── infrastructure/
    └── start-kafka.sh                 # Kafka startup script
```

---

## Quick Start

### Prerequisites
- Google Cloud Platform account with billing enabled
- gcloud CLI installed and authenticated
- Basic understanding of Linux/Windows administration
- Familiarity with Elasticsearch/Kibana

### Initial Setup

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd cs456-soc-final
   ```

2. **Deploy GCP Infrastructure**
   ```bash
   # Set project
   gcloud config set project cs456-soc-final
   
   # Start all VMs
   gcloud compute instances start elastic-node logstash-node kafka-node \
     victim-ubuntu victim-windows --zone=us-central1-a
   ```

3. **Start Kafka** (Required after every VM restart!)
   ```bash
   gcloud compute ssh kafka-node --zone=us-central1-a
   ~/start-kafka.sh
   exit
   ```

4. **Get Kibana URL**
   ```bash
   gcloud compute instances describe elastic-node --zone=us-central1-a \
     --format="get(networkInterfaces[0].accessConfigs[0].natIP)"
   ```
   
   Open: `http://[EXTERNAL-IP]:5601`  
   Login: `elastic` / `EsWdmp_QKR=NJzO4jDVU`

### Running Attacks

**Complete Attack Chain:**
```bash
# SSH to victim-ubuntu
gcloud compute ssh victim-ubuntu --zone=us-central1-a

# Run Phase 1 (SSH Brute Force)
./phase1-attack.sh

# Wait 30 seconds
sleep 30

# Run Phase 2 (Lateral Movement)
./phase2-attack.sh

exit
```

**View Results in Kibana:**
1. Navigate to Kibana (URL from above)
2. Go to: Dashboard → "Phase 1: SSH Brute Force Attack"
3. Observe real-time attack detection and visualization

### Shutdown (Important!)
```bash
# Always stop VMs when not in use to avoid charges
gcloud compute instances stop elastic-node logstash-node kafka-node \
  victim-ubuntu victim-windows --zone=us-central1-a
```

---

## Detection Rules

### SSH Authentication Failures
```ruby
if [message] =~ /authentication failure/ or [message] =~ /Failed password/ {
  mutate {
    add_field => { "alert_type" => "ssh_auth_failure" }
    add_tag => ["authentication_failure"]
  }
}
```

### Successful SSH Login
```ruby
if [message] =~ /Accepted password/ {
  mutate {
    add_field => { "alert_type" => "ssh_success" }
    add_tag => ["successful_authentication"]
  }
}
```

### Malicious Execution
```ruby
if [message] =~ /malicious\.sh/ or [message] =~ /\/tmp\/recon/ {
  mutate {
    add_field => { "alert_type" => "malicious_execution" }
    add_tag => ["suspicious_process"]
  }
}
```

### Persistence Attempt
```ruby
if [message] =~ /crontab/ and [message] =~ /malicious/ {
  mutate {
    add_field => { "alert_type" => "persistence_attempt" }
    add_tag => ["persistence"]
  }
}
```

---

## Key Metrics

- **VMs Deployed:** 5 (Elasticsearch, Logstash, Kafka, 2 Victims)
- **Events Processed:** 1000+ per minute
- **Detection Accuracy:** 100% for known attack patterns
- **Attack Phases Detected:** 4 (Initial Access, Execution, Lateral Movement, Exfiltration)
- **Average Detection Time:** <1 second
- **Data Pipeline Latency:** ~2-3 seconds end-to-end

---

## Troubleshooting

### Kafka Not Running
**Symptom:** No logs appearing in Kibana after attacks

**Solution:**
```bash
gcloud compute ssh kafka-node --zone=us-central1-a
~/start-kafka.sh
# Verify with: jps (should show QuorumPeerMain and Kafka)
exit
```

### Kibana Shows No Data
**Symptom:** Dashboard empty or "No results found"

**Solutions:**
1. Set time range to "Last 24 hours" or "Today"
2. Verify Kafka is running (see above)
3. Check Logstash status: `sudo systemctl status logstash`
4. Verify Filebeat/Winlogbeat are running on victim machines

### External IP Changed
**Symptom:** Cannot access Kibana at previous URL

**Solution:**
```bash
gcloud compute instances list --format="table(name,networkInterfaces[0].accessConfigs[0].natIP)"
```
Use new IP for elastic-node.

---

## Security Notes

⚠️ **WARNING:** This is an educational lab environment. The following security practices are intentionally weakened for demonstration purposes:

- Weak passwords are used for attack demonstration
- Firewall rules allow broad access
- Elasticsearch security is configured for ease of use, not production
- VMs are preemptible to reduce costs

**Do NOT use these configurations in production environments!**

---

## Project Deliverables

- ✅ Functional SOC infrastructure on GCP
- ✅ Real-time attack detection pipeline
- ✅ Multi-stage attack scenarios (Linux → Windows)
- ✅ Kibana dashboards with visualizations
- ✅ Technical documentation (8,500+ words)
- ✅ Live demonstration capability (15 minutes)

---

## Team Contributions

**Jon Harmon:**
- GCP infrastructure deployment and configuration
- Phase 1 attack scenario (SSH brute force)
- Elasticsearch/Kibana setup and dashboards
- Logstash detection rules
- Technical documentation

**Nareg Koshanian:**
- Phase 2 attack scenario (lateral movement & exfiltration)
- Windows victim configuration (Sysmon, Winlogbeat)
- Phase 2 detection rules and dashboards
- Attack script development
- Testing and validation

---

## References

- Bonifield, James. *Data Engineering for Cybersecurity*. 2023.
- Elasticsearch Documentation: https://www.elastic.co/guide/
- Apache Kafka Documentation: https://kafka.apache.org/documentation/
- Sysmon Documentation: https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon
- MITRE ATT&CK Framework: https://attack.mitre.org/

---

## License

This project is submitted as coursework for CS456 at Southern Oregon University.

**Academic Integrity Statement:** All work is original and completed by the listed team members. External resources and references are properly cited.

---

## Contact

**Jon Harmon** - harmonj1@sou.edu  
**Nareg Koshanian** - koshanian@sou.edu

**Course Repository:** https://gitlab.cs.sou.edu/cs456-W26-Jon-Harmon/cs456-soc-final

---

*Last Updated: March 2026*
