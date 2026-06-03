# Modular Dotfiles Template for Linux/macOS

A security-first environment bootstrapping and customization framework powered by **Bash** and **GNU Stow**. Designed with an Agent-First/Context-as-Code architecture.

## Architecture & Concept

This project implements a **dual-remote system**:
1. **Public Template (This Repo)**: Contains structural folders, public utility scripts, and an installer core. Absolutely no secrets.
2. **Private Working Copy**: A private fork/copy created by the user to store personal credentials, internal corporate configurations, and specific keys.

### Execution Flow
1. **Bootstrap**: The user copy-pastes `bootstrap.sh` to a fresh machine. It validates the GitHub PAT token against the GitHub API.
2. **Streaming**: If validated, `bootstrap.sh` safely streams `install.sh` from the user's repository directly into memory.
3. **Installation**: The modular `install.sh` provisions packages and links configuration profiles.

## Directory Layout
```text
.
├── AI.md
├── ARCHITECTURE.md
├── BACKLOG.md
├── bash
│   └── .bash_aliases
├── bootstrap.sh
├── .env.example
├── git
│   └── .gitconfig
├── .gitignore
├── install.sh
├── README.md
├── tests
│   ├── .env.tests.example
│   └── run_smoke_tests.sh
└── TEST_SUITE.md
```
* `bootstrap.sh` — Ultra-lightweight pre-flight authenticator (uses only `wget`).
* `install.sh` — Core interactive installer (packages, cloning, dotfiles staging).
* `bash/`, `git/`, `screen/` — Configuration profiles targeted for GNU Stow symlinking.
* `AI.md` & `ARCHITECTURE.md` — Technical constraints and decisions for AI Agents.
* `TEST_SUITE.md` — Acceptance criteria and manual/automated testing matrices.

## How to Run (Bootstrap Entrypoint)
- Export your token or let the script prompt you securely:
```bash
export GITHUB_DOTFILES_TOKEN="your_github_pat"
```
- Execute bootstrapper directly: copy and paste into linux console [bootstrap.sh](bootstrap.sh)

## How to get actual repo tree to update layout (Note for Repo Owner)
```bash
tree -a --gitignore -I .git
```