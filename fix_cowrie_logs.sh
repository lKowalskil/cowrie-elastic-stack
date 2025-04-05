#!/bin/bash

echo "Останавливаем контейнеры..."
docker compose down

echo "Исправляем структуру cowrie logs..."
rm -rf ./cowrie/log
mkdir -p ./cowrie/log
touch ./cowrie/log/cowrie.json
chmod 666 ./cowrie/log/cowrie.json

echo "Обновляем конфигурацию cowrie..."
if [ -f ./cowrie/config/cowrie.cfg ]; then
    # Проверяем наличие секции output_jsonlog и при необходимости обновляем её
    if grep -q "\[output_jsonlog\]" ./cowrie/config/cowrie.cfg; then
        sed -i '/\[output_jsonlog\]/,/^\[/ s/enabled = .*/enabled = true/' ./cowrie/config/cowrie.cfg
        sed -i '/\[output_jsonlog\]/,/^\[/ s/logfile = .*/logfile = \/cowrie\/cowrie-git\/var\/log\/cowrie\/cowrie.json/' ./cowrie/config/cowrie.cfg
    else
        # Добавляем секцию в конец файла
        cat >> ./cowrie/config/cowrie.cfg << 'EOL'

[output_jsonlog]
enabled = true
logfile = /cowrie/cowrie-git/var/log/cowrie/cowrie.json
epoch_timestamp = false
EOL
    fi
else
    # Создаем файл с базовой конфигурацией
    cat > ./cowrie/config/cowrie.cfg << 'EOL'
[ssh]
enabled = true
# listen 22/tcp and 2222/tcp
listen_endpoints = tcp:22:interface=0.0.0.0 tcp:2222:interface=0.0.0.0

[telnet]
enabled = true
# listen 23/tcp and 2323/tcp
listen_endpoints = tcp:23:interface=0.0.0.0 tcp:2323:interface=0.0.0.0

[output_jsonlog]
enabled = true
logfile = /cowrie/cowrie-git/var/log/cowrie/cowrie.json
epoch_timestamp = false
EOL
fi

echo "Запуск контейнеров..."
docker compose up -d
