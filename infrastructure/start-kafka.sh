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
