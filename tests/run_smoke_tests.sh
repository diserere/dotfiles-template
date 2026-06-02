#!/usr/bin/env bash

# Включаем строгий режим (Guardrails из AI.md)
set -euo pipefail

# === НАСТРОЙКА ТЕСТОВЫХ ДАННЫХ ===
# ЗАМЕНИ "placeholder" на свой реальный токен для проверки успешного сценария!
VALID_TOKEN_SECRET="placeholder" 
INVALID_TOKEN_SECRET="fake-invalid-token-12345"

# Цвета для красивого и читаемого лога
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

BOOTSTRAP="./bootstrap.sh"

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}   STARTING SEMI-AUTOMATED TEST SUITE (SMOKE v2)    ${NC}"
echo -e "${CYAN}====================================================${NC}"

cleanup_env() {
    if [ -f .env ]; then rm -f .env; fi
    unset GITHUB_DOTFILES_TOKEN
}

# =================================================================
# БЛОК 1: ИНИЦИАЛИЗАЦИЯ И ВАЛИДАЦИЯ ТОКЕНА
# =================================================================

# --- TC-1.1 ---
echo -e "\n${YELLOW}### TC-1.1: Empty Token Interactive Input${NC}"
cleanup_env
echo -e "${MAGENTA}[EXPECTED]: Ошибка 'Token cannot be empty', exit code > 0.${NC}"
echo -e "${GREEN}> Запуск с отправкой пустого ввода (Enter):${NC}"
echo "" | $BOOTSTRAP || true

# --- TC-1.2 (ДОБАВЛЕН) ---
echo -e "\n${YELLOW}### TC-1.2: Token from Environment Variable (Inline)${NC}"
cleanup_env
echo -e "${MAGENTA}[EXPECTED]: Скрипт подхватит токен из env. Если токен невалидный — выдаст 'validation failed'.${NC}"
echo -e "${GREEN}> Запуск: GITHUB_DOTFILES_TOKEN=\"...\" $BOOTSTRAP${NC}"
GITHUB_DOTFILES_TOKEN="$INVALID_TOKEN_SECRET" $BOOTSTRAP || true

# --- TC-1.3 ---
echo -e "\n${YELLOW}### TC-1.3: Token from Local .env (File Parsing)${NC}"
cleanup_env
echo -e "${MAGENTA}[EXPECTED]: Скрипт найдет .env, прочитает токен, выдаст ошибку валидации.${NC}"
echo "GITHUB_DOTFILES_TOKEN=\"$INVALID_TOKEN_SECRET\"" > .env
echo -e "${GREEN}> Текущее содержимое файла .env:${NC}"
cat .env
echo -e "${GREEN}> Запуск bootstrap.sh:${NC}"
$BOOTSTRAP || true

# --- TC-1.4 ---
echo -e "\n${YELLOW}### TC-1.4: Commented Token in .env (RegEx Verification)${NC}"
cleanup_env
echo -e "${MAGENTA}[EXPECTED]: Скрипт проигнорирует строки с #, потребует ввод. Передаем 'q' -> ошибка валидации короткого токена.${NC}"
echo "# GITHUB_DOTFILES_TOKEN=\"github_pat_valid_placeholder_123\"" > .env
echo "# GITHUB_DOTFILES_TOKEN=\"$INVALID_TOKEN_SECRET\"" >> .env
echo -e "${GREEN}> Текущее содержимое файла .env:${NC}"
cat .env
echo -e "${GREEN}> Передаем 'q' в интерактивный read:${NC}"
echo "q" | $BOOTSTRAP || true


# =================================================================
# БЛОК 2: ЗАГРУЗКА И ВЫПОЛНЕНИЕ ОСНОВНОГО ИНСТАЛЛЯТОРА
# =================================================================

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${CYAN}   БЛОК 2: DOWNLOADING & STREAMING INSTALLER        ${NC}"
echo -e "${CYAN}====================================================${NC}"

# --- TC-2.1: Невалидный токен (Негативный кейс) ---
echo -e "\n${YELLOW}### TC-2.1: Installer Streaming with Invalid Token${NC}"
cleanup_env
echo -e "${MAGENTA}[EXPECTED]: Падение на этапе валидации токена через API (HTTP Error), стриминг не начинается.${NC}"
echo -e "${GREEN}> Запуск с заведомо невалидным токеном в env:${NC}"
GITHUB_DOTFILES_TOKEN="$INVALID_TOKEN_SECRET" $BOOTSTRAP || true

# --- TC-2.2: Успешный сквозной сценарий (Позитивный кейс) ---
echo -e "\n${YELLOW}### TC-2.2: Successful Token Validation & Installer Stream${NC}"
cleanup_env
if [ "$VALID_TOKEN_SECRET" = "placeholder" ]; then
    echo -e "${YELLOW}[SKIP] Пропущено. Для выполнения этого теста укажите реальный токен в переменной VALID_TOKEN_SECRET.${NC}"
else
    echo -e "${MAGENTA}[EXPECTED]: Успешная валидация (HTTP 200). 'Streaming installer...'. Появление запроса sudo password от install.sh.${NC}"
    echo -e "${GREEN}> Запуск с валидным токеном в env (прервите тест через Ctrl+C, когда появится запрос sudo):${NC}"
    GITHUB_DOTFILES_TOKEN="$VALID_TOKEN_SECRET" $BOOTSTRAP
fi

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${CYAN}   TEST SUITE FINISHED. REVIEW LOGS ABOVE.          ${NC}"
echo -e "${CYAN}====================================================${NC}"
cleanup_env
