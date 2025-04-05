#!/bin/sh
set -e

echo "Очищаем старую конфигурацию и настраиваем honeypot-ы..."

# Останавливаем все контейнеры
docker compose down

# Очищаем директории логов
echo "Очищаем директории логов..."
rm -rf cowrie/log/* dionaea/log/*

# Создаём нужные директории и файлы
mkdir -p cowrie/log dionaea/log cowrie/downloads

# Устанавливаем права доступа
chmod -R 777 cowrie/log dionaea/log cowrie/downloads

echo "Запускаем контейнеры..."
docker compose up -d

# Ждем, пока контейнеры запустятся
sleep 10

echo "Генерируем тестовые события напрямую..."
# Создаем тестовые файлы логов напрямую в директориях хоста
echo "{\"message\":\"test cowrie log\",\"timestamp\":\"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\",\"test\":true}" > cowrie/log/test.json
echo "{\"message\":\"test dionaea log\",\"timestamp\":\"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\",\"test\":true}" > dionaea/log/test.json

# Проверяем, что файлы созданы
echo "Проверяем наличие файлов логов в хост-системе..."
ls -la cowrie/log
ls -la dionaea/log

# Проверка, что Elasticsearch запущен
echo "Проверка доступности Elasticsearch..."
MAX_RETRIES=30
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if curl -s "http://localhost:9200/_cluster/health" > /dev/null; then
    echo "Elasticsearch доступен!"
    break
  fi
  echo "Ожидание Elasticsearch (попытка $RETRY_COUNT/$MAX_RETRIES)..."
  sleep 5
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "Elasticsearch недоступен после всех попыток!"
  exit 1
fi

# Проверяем индексы
echo "Проверяем Elasticsearch индексы (возможно, потребуется несколько минут для появления)..."
curl -X GET "http://localhost:9200/_cat/indices?v"

echo "Проверяем логи контейнеров..."
docker compose logs filebeat | tail -n 30
docker compose logs logstash | tail -n 30
docker compose logs logcheck | tail -n 10

# Исправление проблемы с отсутствием логов в образах
echo "Проверяем настройку логов внутри контейнеров..."

# Cowrie: проверка и принудительное создание логов (используем sh)
docker compose exec -T cowrie sh -c "ls -la /cowrie/cowrie-git/var/log/cowrie/ || true"
docker compose exec -T cowrie sh -c "echo '{\"event\":\"test\",\"src_ip\":\"127.0.0.1\",\"timestamp\":\"'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'\"}' > /cowrie/cowrie-git/var/log/cowrie/cowrie.json"

# Dionaea: проверка и принудительное создание логов (используем sh)
docker compose exec -T dionaea sh -c "ls -la /opt/dionaea/var/log/dionaea/ || mkdir -p /opt/dionaea/var/log/dionaea/"
docker compose exec -T dionaea sh -c "echo '{\"event\":\"test\",\"src_ip\":\"127.0.0.1\",\"timestamp\":\"'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'\"}' > /opt/dionaea/var/log/dionaea/dionaea.json"

echo "Перезапускаем filebeat для подхвата новых логов..."
docker compose restart filebeat

echo "Открываем Kibana на http://localhost:5601"
echo "Дождитесь полной загрузки Kibana и индексации логов (может занять до 5 минут)"
echo ""
echo "Если логи по-прежнему не видны, выполните следующие шаги для отладки:"
echo "1. docker compose logs filebeat        # Проверьте сообщения об ошибках"
echo "2. docker compose logs logstash        # Проверьте обработку входящих событий"
echo "3. docker compose exec -T filebeat sh -c 'ls -la /cowrie-logs/ /dionaea-logs/'"