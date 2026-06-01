#!/usr/bin/env bash

# Безопасный режим
set -euo pipefail

echo "========================================="
echo "   Dotfiles Bootstrapper via GitHub API  "
echo "========================================="

# Имена файлов и путей (для удобства кастомизации)
ENV_FILE_NAME=".env"
INSTALLER_NAME="install.sh"
GITHUB_RAW_BASE="https://githubusercontent.com"
REPO_OWNER="diserere"
REPO_NAME="dotfiles-template" # ПОЗЖЕ: поменяйте на ваш приватный репо!
REPO_BRANCH="main"

# Конструируем URL
PRIVATE_INSTALLER_URL="${GITHUB_RAW_BASE}/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/${INSTALLER_NAME}"

# 1. Поиск токена в файлах .env (сначала в текущей папке, затем в предполагаемой ~/.dotfiles)
if [ -z "${GITHUB_DOTFILES_TOKEN:-}" ]; then
    # Ищем файл в текущей директории или в домашней ~/.dotfiles/
    for env_path in "./${ENV_FILE_NAME}" "${HOME}/.dotfiles/${ENV_FILE_NAME}"; do
        if [ -f "$env_path" ]; then
            echo "Found ${ENV_FILE_NAME} at ${env_path}. Loading variables..."
            # Извлекаем токен из .env без вызова полноценного source (чтобы не сломать set -u)
            GITHUB_DOTFILES_TOKEN=$(grep -E '^GITHUB_DOTFILES_TOKEN=' "$env_path" | cut -d'=' -f2- | tr -d '"'\') || true
            if [ -n "$GITHUB_DOTFILES_TOKEN" ]; then
                break
            fi
        fi
    done
fi

# 2. Если в файлах не нашли — запрашиваем у пользователя скрытно
if [ -z "${GITHUB_DOTFILES_TOKEN:-}" ]; then
    echo "GitHub token not found in files or environment."
    # read -rs -p "Please enter your GitHub PAT: " GITHUB_DOTFILES_TOKEN
    read -r -p "Please enter your GitHub PAT: " GITHUB_DOTFILES_TOKEN
    echo "" # Перевод строки после скрытого ввода
fi

# Финальная проверка
if [ -z "$GITHUB_DOTFILES_TOKEN" ]; then
    echo "Error: Token cannot be empty." >&2
    exit 1
fi

echo "Validating GitHub token..."

# 3. Валидация токена через wget
if ! wget -q --spider --header="Authorization: token $GITHUB_DOTFILES_TOKEN" https://github.com; then
    echo "Error: GitHub token validation failed (Invalid or Expired token)." >&2
    exit 1
fi

echo "Token successfully validated!"
echo "Streaming installer from repository..."

# Экспортируем переменную для дочернего процесса bash
export GITHUB_DOTFILES_TOKEN

# 4. Запуск инсталлера БЕЗ пайпа (сохраняем интерактивность stdin для install.sh)
bash <(wget -qO- --header="Authorization: token $GITHUB_DOTFILES_TOKEN" "$PRIVATE_INSTALLER_URL")


