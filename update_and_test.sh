#!/bin/bash
set -e

echo "Применение исправлений..."
chmod +x /root/cowrie-elastic-stack/fix_cowrie_logs.sh
/root/cowrie-elastic-stack/fix_cowrie_logs.sh

echo "Ожидание 30 секунд для инициализации сервисов..."
sleep 30

echo "Проверка логов контейнеров..."
docker logs cowrie-elastic-stack-cowrie-1 --tail 10
docker logs cowrie-elastic-stack-filebeat-1 --tail 10
docker logs cowrie-elastic-stack-logstash-1 --tail 10

echo "Проверка файла cowrie.json..."
ls -la ./cowrie/log/cowrie.json
tail -n 5 ./cowrie/log/cowrie.json

echo "Проверка индексов в Elasticsearch..."
curl -s -X GET "http://localhost:9200/_cat/indices?v"

echo "Проверка записей в индексе cowrie..."
COWRIE_INDEX=$(curl -s -X GET "http://localhost:9200/_cat/indices?v" | grep "cowrie" | head -n 1 | awk '{print $3}')
if [ ! -z "$COWRIE_INDEX" ]; then
    echo "Документ из индекса $COWRIE_INDEX:"
    curl -s -X GET "http://localhost:9200/$COWRIE_INDEX/_search?size=1&sort=@timestamp:desc" | jq .
else
    echo "Индекс cowrie не найден!"
    # Генерируем тестовое подключение к cowrie для создания записей
    echo "Генерация тестового подключения к SSH..."
    ssh -o StrictHostKeyChecking=no root@localhost -p 22 || true
fi

echo "Проверка записей в индексе heralding..."
HERALDING_INDEX=$(curl -s -X GET "http://localhost:9200/_cat/indices?v" | grep "heralding" | head -n 1 | awk '{print $3}')
if [ ! -z "$HERALDING_INDEX" ]; then
    echo "Документ из индекса $HERALDING_INDEX:"
    curl -s -X GET "http://localhost:9200/$HERALDING_INDEX/_search?size=1&sort=@timestamp:desc" | jq .
else
    echo "Индекс heralding не найден!"
    # Генерируем тестовое подключение к heralding для создания записей
    echo "Генерация тестового HTTP подключения..."
    curl -s -o /dev/null http://localhost:80
fi

echo "Проверка успешно завершена!"
echo "Откройте Kibana по адресу: http://$(hostname -I | awk '{print $1}'):5601"
