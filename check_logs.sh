#!/bin/bash

echo "Checking container statuses..."
docker compose ps

echo -e "\nChecking if cowrie.json exists..."
ls -la ./cowrie/log/cowrie.json

echo -e "\nChecking if cowrie is logging..."
tail -n 5 ./cowrie/log/cowrie.json

echo -e "\nChecking Heralding logs..."
ls -la ./heralding/logs/

echo -e "\nChecking Elasticsearch indices..."
curl -X GET "http://localhost:9200/_cat/indices?v"

echo -e "\nChecking latest document from cowrie index..."
COWRIE_INDEX=$(curl -s -X GET "http://localhost:9200/_cat/indices?v" | grep "cowrie" | head -n 1 | awk '{print $3}')
if [ ! -z "$COWRIE_INDEX" ]; then
  echo "Latest document from index $COWRIE_INDEX:"
  curl -X GET "http://localhost:9200/$COWRIE_INDEX/_search?size=1&sort=@timestamp:desc" | jq .
else 
  echo "No cowrie index found!"
fi

echo -e "\nChecking latest document from heralding index..."
HERALDING_INDEX=$(curl -s -X GET "http://localhost:9200/_cat/indices?v" | grep "heralding" | head -n 1 | awk '{print $3}')
if [ ! -z "$HERALDING_INDEX" ]; then
  echo "Latest document from index $HERALDING_INDEX:"
  curl -X GET "http://localhost:9200/$HERALDING_INDEX/_search?size=1&sort=@timestamp:desc" | jq .
else
  echo "No heralding index found!"
fi

echo -e "\nChecking logs from filebeat..."
docker logs cowrie-elastic-stack-filebeat-1 | tail -n 20

echo -e "\nChecking logs from logstash..."
docker logs cowrie-elastic-stack-logstash-1 | tail -n 20
