#!/usr/bin/env bash

# Включаем строгий режим (Guardrails из AI.md)
set -euo pipefail

# === ОПРЕДЕЛЕНИЕ ДЕФОЛТНЫХ ПУТЕЙ ===
# Автоматически находим корень репозитория относительно этого скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_BOOTSTRAP="${SCRIPT_DIR}/../bootstrap.sh"
LOCAL_CONFIG="${SCRIPT_DIR}/.env.tests"

# === ЗНАЧЕНИЯ ПО УМОЛЧАНИЮ ===
VALID_TOKEN_SECRET="placeholder"
INVALID_TOKEN_SECRET="fake-invalid-token-12345"
BOOTSTRAP="$DEFAULT_BOOTSTRAP"

# === ПОДКЛЮЧЕНИЕ ЛОКАЛЬНОГО КОНФИГА (ЕСЛИ ОН ЕСТЬ) ===
if [ -f "$LOCAL_CONFIG" ]; then
    # Безопасно извлекаем переменные, игнорируя комментарии
    CONFIG_TOKEN=$(grep -E '^VALID_TOKEN_SECRET=' "$LOCAL_CONFIG" | head -n 1 | cut -d'"' -f2 || true)
    CONFIG_PATH=$(grep -E '^BOOTSTRAP_PATH=' "$LOCAL_CONFIG" | head -n 1 | cut -d'"' -f2 || true)
    
    if [ -n "$CONFIG_TOKEN" ]; then
        VALID_TOKEN_SECRET="$CONFIG_TOKEN"
        echo "Using token from local config: $VALID_TOKEN_SECRET"
    fi
    if [ -n "$CONFIG_PATH" ]; then
        BOOTSTRAP="$CONFIG_PATH"
    fi
fi

# === БАЗОВЫЕ ANSI-КОДЫ ЦВЕТОВ ===
ANSI_BLACK='\033[0;30m'
ANSI_RED='\033[0;31m'
ANSI_GREEN='\033[0;32m'
ANSI_YELLOW='\033[1;33m'
ANSI_BLUE='\033[0;34m'
ANSI_MAGENTA='\033[0;35m'
ANSI_CYAN='\033[0;36m'
ANSI_WHITE='\033[0;37m'
ANSI_NC='\033[0m'

# === СЕМАНТИЧЕСКАЯ ПАЛИТРА (НАСТРАИВАЙ ТУТ) ===
COLOR_HEADER=$ANSI_MAGENTA      # Главные разделители блоков и финал
COLOR_CASE=$ANSI_CYAN           # Названия тест-кейсов (например, ### TC-1.1)
COLOR_EXPECTED=$ANSI_YELLOW     # Строки с ожидаемым результатом [EXPECTED]
COLOR_COMMAND=$ANSI_GREEN       # Описание выполняемых команд и шагов
COLOR_NC=$ANSI_NC               # Сброс цвета (обязательно в конце строк)

echo -e "${COLOR_HEADER}====================================================${COLOR_NC}"
echo -e "${COLOR_HEADER}   STARTING SEMI-AUTOMATED TEST SUITE (SMOKE v4)    ${COLOR_NC}"
echo -e "${COLOR_HEADER}====================================================${COLOR_NC}"
echo -e "${COLOR_COMMAND}> Целевой скрипт: $BOOTSTRAP${COLOR_NC}"

# Валидация: существует ли вообще тестируемый скрипт по указанному пути
if [ ! -f "$BOOTSTRAP" ]; then
    echo -e "${ANSI_RED}Ошибка: Скрипт bootstrap не найден по адресу $BOOTSTRAP${COLOR_NC}"
    exit 1
fi

cleanup_env() {
    # Стираем .env в папке откуда запущен тест, чтобы не сломать логику парсинга в bootstrap.sh
    if [ -f .env ]; then rm -f .env; fi
    unset GITHUB_DOTFILES_TOKEN
}

# =================================================================
# БЛОК 1: ИНИЦИАЛИЗАЦИЯ И ВАЛИДАЦИЯ ТОКЕНА
# =================================================================

# --- TC-1.1 ---
echo -e "\n${COLOR_CASE}### TC-1.1: Empty Token Interactive Input${COLOR_NC}"
cleanup_env
echo -e "${COLOR_EXPECTED}[EXPECTED]: Ошибка 'Token cannot be empty', exit code > 0.${COLOR_NC}"
echo -e "${COLOR_COMMAND}> Запуск с отправкой пустого ввода (Enter):${COLOR_NC}"
echo "" | "$BOOTSTRAP" || true

# --- TC-1.2 ---
echo -e "\n${COLOR_CASE}### TC-1.2: Token from Environment Variable (Inline)${COLOR_NC}"
cleanup_env
echo -e "${COLOR_EXPECTED}[EXPECTED]: Скрипт подхватит токен из env. Если токен невалидный — выдаст 'validation failed'.${COLOR_NC}"
echo -e "${COLOR_COMMAND}> Запуск: GITHUB_DOTFILES_TOKEN=\"...\" bootstrap.sh${COLOR_NC}"
GITHUB_DOTFILES_TOKEN="$INVALID_TOKEN_SECRET" "$BOOTSTRAP" || true

# --- TC-1.3 ---
echo -e "\n${COLOR_CASE}### TC-1.3: Token from Local .env (File Parsing)${COLOR_NC}"
cleanup_env
echo -e "${COLOR_EXPECTED}[EXPECTED]: Скрипт найдет .env, прочитает токен, выдаст ошибку валидации.${COLOR_NC}"
echo "GITHUB_DOTFILES_TOKEN=\"$INVALID_TOKEN_SECRET\"" > .env
echo -e "${COLOR_COMMAND}> Текущее содержимое файла .env:${COLOR_NC}"
cat .env
echo -e "${COLOR_COMMAND}> Запуск bootstrap.sh:${COLOR_NC}"
"$BOOTSTRAP" || true

# --- TC-1.4 ---
echo -e "\n${COLOR_CASE}### TC-1.4: Commented Token in .env (RegEx Verification)${COLOR_NC}"
cleanup_env
echo -e "${COLOR_EXPECTED}[EXPECTED]: Скрипт проигнорирует строки с #, потребует ввод. Передаем 'q' -> ошибка валидации короткого токена.${COLOR_NC}"
echo "# GITHUB_DOTFILES_TOKEN=\"github_pat_valid_placeholder_123\"" > .env
echo "# GITHUB_DOTFILES_TOKEN=\"$INVALID_TOKEN_SECRET\"" >> .env
echo -e "${COLOR_COMMAND}> Текущее содержимое файла .env:${COLOR_NC}"
cat .env
echo -e "${COLOR_COMMAND}> Передаем 'q' в интерактивный read:${COLOR_NC}"
echo "q" | "$BOOTSTRAP" || true


# =================================================================
# БЛОК 2: ЗАГРУЗКА И ВЫПОЛНЕНИЕ ОСНОВНОГО ИНСТАЛЛЯТОРА
# =================================================================

echo -e "\n${COLOR_HEADER}====================================================${COLOR_NC}"
echo -e "${COLOR_HEADER}   БЛОК 2: DOWNLOADING & STREAMING INSTALLER        ${COLOR_NC}"
echo -e "${COLOR_HEADER}====================================================${COLOR_NC}"

# --- TC-2.1: Невалидный токен (Негативный кейс) ---
echo -e "\n${COLOR_CASE}### TC-2.1: Installer Streaming with Invalid Token${COLOR_NC}"
cleanup_env
echo -e "${COLOR_EXPECTED}[EXPECTED]: Падение на этапе валидации токена через API (HTTP Error), стриминг не начинается.${COLOR_NC}"
echo -e "${COLOR_COMMAND}> Запуск с заведомо невалидным токеном в env:${COLOR_NC}"
GITHUB_DOTFILES_TOKEN="$INVALID_TOKEN_SECRET" "$BOOTSTRAP" || true

# --- TC-2.2: Успешный сквозной сценарий (Позитивный кейс) ---
echo -e "\n${COLOR_CASE}### TC-2.2: Successful Token Validation & Installer Stream${COLOR_NC}"
cleanup_env
if [ "$VALID_TOKEN_SECRET" = "placeholder" ]; then
    echo -e "${COLOR_CASE}[SKIP] Пропущено. Для выполнения этого теста укажите реальный токен в файле tests/.env.tests${COLOR_NC}"
else
    echo -e "${COLOR_EXPECTED}[EXPECTED]: Успешная валидация (HTTP 200). 'Streaming installer...'. Появление запроса sudo password от install.sh.${COLOR_NC}"
    echo -e "${COLOR_COMMAND}> Запуск с валидным токеном из локального конфига:${COLOR_NC}"
    GITHUB_DOTFILES_TOKEN="$VALID_TOKEN_SECRET" "$BOOTSTRAP"
fi

echo -e "\n${COLOR_HEADER}====================================================${COLOR_NC}"
echo -e "${COLOR_HEADER}   TEST SUITE FINISHED. REVIEW LOGS ABOVE.          ${COLOR_NC}"
echo -e "${COLOR_HEADER}====================================================${COLOR_NC}"
cleanup_env
