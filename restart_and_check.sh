#!/bin/bash

echo "Остановка контейнеров..."
docker compose down

echo "Настройка директорий и файлов..."
mkdir -p ./cowrie/log
rm -rf ./cowrie/log/cowrie.json
touch ./cowrie/log/cowrie.json
chmod 666 ./cowrie/log/cowrie.json

mkdir -p ./heralding/logs
touch ./heralding/logs/log_session.json
touch ./heralding/logs/log_auth.csv
touch ./heralding/logs/log_session.csv
chmod 666 ./heralding/logs/log_session.json 
chmod 666 ./heralding/logs/log_auth.csv 
chmod 666 ./heralding/logs/log_session.csv

# Проверка наличия индексов в Elasticsearch если контейнер уже запущен ранее
if docker ps -a | grep -q "cowrie-elastic-stack-elasticsearch-1"; then
    echo "Проверка индексов Elasticsearch..."
    docker start cowrie-elastic-stack-elasticsearch-1
    sleep 5
    curl -X GET "http://localhost:9200/_cat/indices?v"
fi

echo "Запуск контейнеров..."
docker compose up -d

echo "Ожидание 20 секунд для запуска всех сервисов..."
sleep 20

echo "Проверка конфигурации cowrie.cfg..."
bash ./check_cowrie_config.sh

echo "Проверка логов Cowrie..."
docker logs cowrie-elastic-stack-cowrie-1 | tail -n 10

echo "Проверка логов Heralding..."
docker logs cowrie-elastic-stack-heralding-1 | tail -n 10

echo "Проверка логов Filebeat..."
docker logs cowrie-elastic-stack-filebeat-1 | tail -n 10

echo "Проверка логов Logstash..."
docker logs cowrie-elastic-stack-logstash-1 | tail -n 10

echo "Готово! Через несколько минут данные должны появиться в Kibana."
echo "Для доступа к Kibana откройте: http://$(hostname -I | awk '{print $1}'):5601"
echo "Для подробной проверки логов используйте: ./check_logs.sh"
