#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo "   Dotfiles Bootstrapper via GitHub API  "
echo "========================================="

ENV_FILE_NAME=".env"
INSTALLER_NAME="install.sh"
GITHUB_RAW_BASE="https://raw.githubusercontent.com"
REPO_OWNER="diserere"
REPO_NAME="dotfiles-template"
REPO_BRANCH="main"

PRIVATE_INSTALLER_URL="${GITHUB_RAW_BASE}/${REPO_OWNER}/${REPO_NAME}/${REPO_BRANCH}/${INSTALLER_NAME}"

# 1. Поиск токена в файлах
if [ -z "${GITHUB_DOTFILES_TOKEN:-}" ]; then
    for env_path in "./${ENV_FILE_NAME}" "${HOME}/.dotfiles/${ENV_FILE_NAME}"; do
        if [ -f "$env_path" ]; then
            echo "Found ${ENV_FILE_NAME} at ${env_path}."
            # Ищем только раскомментированные строки
            TOKEN_FROM_FILE=$(grep -E '^GITHUB_DOTFILES_TOKEN=' "$env_path" | cut -d'=' -f2- | tr -d '"'\') || true
            if [ -n "$TOKEN_FROM_FILE" ]; then
                echo "Found valid GITHUB_DOTFILES_TOKEN in ${env_path}."
                GITHUB_DOTFILES_TOKEN="$TOKEN_FROM_FILE"
                break
            fi
        fi
    done
fi

# 2. Если не нашли — запрашиваем скрытно (верните -s после отладки!)
if [ -z "${GITHUB_DOTFILES_TOKEN:-}" ]; then
    echo "GitHub token not found in files or environment."
    # read -rs -p "Please enter your GitHub PAT: " GITHUB_DOTFILES_TOKEN
    read -r -p "Please enter your GitHub PAT: " GITHUB_DOTFILES_TOKEN
    echo "" 
fi

if [ -z "$GITHUB_DOTFILES_TOKEN" ]; then
    echo "Error: Token cannot be empty." >&2
    exit 1
fi

echo "Validating GitHub token..."

# 3. НАДЕЖНАЯ ВАЛИДАЦИЯ:
# LANG=C гарантирует английский вывод wget независимо от системы
# --spider не скачивает тело, а только проверяет статус
# Если токен невалидный, wget вернет системную ошибку (код 8), и цикл "if !" поймает её
if ! LANG=C wget -q --spider --header="Authorization: token $GITHUB_DOTFILES_TOKEN" https://api.github.com; then
    echo "Error: GitHub token validation failed (Invalid or Expired token)." >&2
    exit 1
fi

echo "Token successfully validated (HTTP 200)!"
echo "Streaming installer from repository..."

export GITHUB_DOTFILES_TOKEN

# bash <(wget -nv -O- --header="Authorization: token $GITHUB_DOTFILES_TOKEN" "$PRIVATE_INSTALLER_URL")
if INSTALL_SCRIPT=$(wget -nv -O- --header="Authorization: token ${GITHUB_DOTFILES_TOKEN}" "${PRIVATE_INSTALLER_URL}"); then
    bash <(printf '%s\n' "$INSTALL_SCRIPT")
else
    echo "Ошибка: Не удалось загрузить основной скрипт установки ${PRIVATE_INSTALLER_URL}" >&2
    exit 1
fi

