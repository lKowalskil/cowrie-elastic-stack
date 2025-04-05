#!/bin/bash

CONFIG_FILE="./cowrie/config/cowrie.cfg"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Создаем базовую конфигурацию cowrie.cfg..."
    cat > "$CONFIG_FILE" << 'EOL'
[ssh]
# listen 22/tcp and 2222/tcp
listen_endpoints = tcp:22:interface=0.0.0.0 tcp:2222:interface=0.0.0.0

[telnet]
enabled = true
# listen 23/tcp and 2323/tcp
listen_endpoints = tcp:23:interface=0.0.0.0 tcp:2323:interface=0.0.0.0

[output_jsonlog]
enabled = true
logfile = var/log/cowrie/cowrie.json
epoch_timestamp = false
EOL
    echo "Конфигурация создана."
else
    # Проверяем наличие секции output_jsonlog и при необходимости добавляем её
    if ! grep -q "\[output_jsonlog\]" "$CONFIG_FILE"; then
        echo "Добавляем секцию [output_jsonlog] в конфигурацию..."
        cat >> "$CONFIG_FILE" << 'EOL'

[output_jsonlog]
enabled = true
logfile = var/log/cowrie/cowrie.json
epoch_timestamp = false
EOL
        echo "Секция добавлена."
    fi
fi

echo "Конфигурация проверена и исправлена."
