#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo "   Dotfiles Bootstrapper via GitHub API  "
echo "========================================="

ENV_FILE_NAME=".env"
INSTALLER_NAME="install.sh"
GITHUB_RAW_BASE="https://githubusercontent.com"
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

# 3. НАДЕЖНАЯ ВАЛИДАЦИЯ: Запрашиваем заголовки и вытаскиваем HTTP-код
# Если токен плохой, GitHub вернет "HTTP/... 401 Unauthorized"
HTTP_STATUS=$(wget -S --spider --header="Authorization: token $GITHUB_DOTFILES_TOKEN" https://github.com 2>&1 | grep "HTTP/" | awk '{print $2}' | tail -n1) || echo "400"

if [ "$HTTP_STATUS" != "200" ]; then
    echo "Error: GitHub token validation failed (HTTP Status: $HTTP_STATUS)." >&2
    exit 1
fi

echo "Token successfully validated (HTTP 200)!"
echo "Streaming installer from repository..."

export GITHUB_DOTFILES_TOKEN

bash <(wget -qO- --header="Authorization: token $GITHUB_DOTFILES_TOKEN" "$PRIVATE_INSTALLER_URL")
