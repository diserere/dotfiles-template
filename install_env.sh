#!/bin/env bash

# Путь к конфигурационному файлу
PROFILE_FILE="$HOME/.profile"
ENV_FILE="$HOME/.env_private"

# Маркер, по которому скрипт будет понимать, что секция уже добавлена
MARKER="# [CUSTOM_ENV] Loading private environment variables"

echo "Начало настройки окружения..."

# 1. Создаем сам файл переменных, если его еще нет
if [ ! -f "$ENV_FILE" ]; then
    cat << 'EOF' > "$ENV_FILE"
# Ваши персональные переменные окружения

export API_KEY="default_value_change_me"

EOF
    echo "Создан шаблон файла: $ENV_FILE"
    echo "Не забудьте отредактировать его и внести реальные ключи."
else
    echo "Файл $ENV_FILE уже существует. Пропускаем создание."
fi

# 2. Проверяем наличие маркера в ~/.profile
if grep -qF "$MARKER" "$PROFILE_FILE"; then
    echo "Настройка в $PROFILE_FILE уже была выполнена ранее. Пропускаем."
else
    # Добавляем блок интеграции в конец ~/.profile
    cat << EOF >> "$PROFILE_FILE"

$MARKER
if [ -f "$ENV_FILE" ]; then
    . "$ENV_FILE"
fi
EOF
    echo "Интеграция успешно добавлена в $PROFILE_FILE"
fi

echo "Настройка завершена успешно!"

