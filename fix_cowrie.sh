#!/bin/bash
set -e

echo "Останавливаем контейнеры..."
docker compose down

echo "Исправляем cowrie.json..."
rm -rf ./cowrie/log/cowrie.json
touch ./cowrie/log/cowrie.json
chmod 666 ./cowrie/log/cowrie.json

echo "Перезапускаем контейнеры..."
docker compose up -d

echo "Готово! Проверьте логи через несколько минут."
