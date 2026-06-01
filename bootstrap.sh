#!/usr/bin/env bash


REPO_URL="https://raw.githubusercontent.com/diserere/dotfiles/refs/heads/main"
SCRIPT_NAME="install.sh"

if INSTALL_SCRIPT=$(wget -nv -O- --header="Authorization: token ${GITHUB_DOTFILES_TOKEN}" "${REPO_URL}/${SCRIPT_NAME}"); then
    bash <(printf '%s\n' "$INSTALL_SCRIPT")
else
    echo "Ошибка: Не удалось загрузить основной скрипт установки ${SCRIPT_NAME}" >&2
    exit 1
fi

