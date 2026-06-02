#!/usr/bin/env bash

# Включаем строгий режим (Guardrails из AI.md)
set -euo pipefail

# Цвета для красивого и читаемого лога
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

BOOTSTRAP="./bootstrap.sh"

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}   STARTING SEMI-AUTOMATED TEST SUITE (SMOKE)       ${NC}"
echo -e "${CYAN}====================================================${NC}"

# Функция-помощник для чистоты окружения перед каждым кейсом
cleanup_env() {
    if [ -f .env ]; then rm -f .env; fi
    unset GITHUB_DOTFILES_TOKEN
}

# -----------------------------------------------------------------
# TC-1.1: Пустой ввод токена (Проверка валидации на пустоту)
# -----------------------------------------------------------------
echo -e "\n${YELLOW}### TC-1.1: Empty Token Interactive Input${NC}"
cleanup_env

echo -e "${GREEN}> Команда: Передаем пустую строку в интерактивный read${NC}"
# Эмулируем нажатие Enter (пустой ввод)
echo "" | $BOOTSTRAP || true 
# Мы добавили '|| true', так как скрипт должен упасть с ошибкой (exit code > 0), 
# но мы не хотим, чтобы из-за этого прервался сам тестовый пайплайн.


# -----------------------------------------------------------------
# TC-1.3: Токен из локального файла .env (Валидный кейс)
# -----------------------------------------------------------------
echo -e "\n${YELLOW}### TC-1.3: Token from Local .env (File Parsing)${NC}"
cleanup_env

echo -e "${GREEN}> Команда: Создаем временный .env с фейковым токеном${NC}"
echo 'GITHUB_DOTFILES_TOKEN="fake-token"' > .env

echo -e "${GREEN}> Текущее содержимое файла .env:${NC}"
cat .env

echo -e "${GREEN}> Команда: Запуск bootstrap.sh (Ожидаем чтение из .env)${NC}"
# Запускаем. Так как токен "fake-token", GitHub API вернет ошибку (или успех, если подменить URL).
# Скрипт дойдет до шага скачивания инсталлятора.
$BOOTSTRAP || true


# -----------------------------------------------------------------
# TC-1.4: Закомментированный токен в .env (Проверка регулярного выражения)
# -----------------------------------------------------------------
echo -e "\n${YELLOW}### TC-1.4: Commented Token in .env (RegEx Verification)${NC}"
cleanup_env

echo -e "${GREEN}> Команда: Создаем .env, где все строки закомментированы${NC}"
echo '# GITHUB_DOTFILES_TOKEN="github_pat_11AGNKC6..."' > .env
echo '# GITHUB_DOTFILES_TOKEN="fake-token"' >> .env

echo -e "${GREEN}> Текущее содержимое файла .env:${NC}"
cat .env

echo -e "${GREEN}> Команда: Передаем 'q' в read, когда .env проигнорирован${NC}"
# Скрипт должен проигнорировать закомментированный .env и спросить ввод. Мы вводим 'q'.
echo "q" | $BOOTSTRAP || true

echo -e "\n${CYAN}====================================================${NC}"
echo -e "${CYAN}   TEST SUITE FINISHED. REVIEW LOGS ABOVE.          ${NC}"
echo -e "${CYAN}====================================================${NC}"
