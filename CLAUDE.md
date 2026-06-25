# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A modular dotfiles bootstrapping framework for Linux/macOS. It uses a **dual-remote architecture**: this public repo contains the structural template and installer logic; users maintain a private fork/copy with their actual secrets. The bootstrapper authenticates via GitHub PAT, then streams the installer from the private repo.

## Commands

### Running the full bootstrap (end-to-end)
```bash
export GITHUB_DOTFILES_TOKEN="your_github_pat"
./bootstrap.sh
```

### Running the smoke test suite
```bash
# Without a valid token (runs TC-1.1 through TC-1.4, TC-2.1 — all negative/skip paths):
./tests/run_smoke_tests.sh

# With a valid token (includes TC-2.2 happy path):
# Copy tests/.env.tests.example to tests/.env.tests and set VALID_TOKEN_SECRET
./tests/run_smoke_tests.sh
```

### Running install_env.sh (standalone environment setup)
```bash
./install_env.sh
```
This creates `~/.env_private` and appends a loader block to `~/.profile`. Idempotent — safe to re-run.

## Architecture

### Execution Pipeline
```
bootstrap.sh  →  validates GitHub PAT  →  streams install.sh via wget  →  install.sh provisions system
```

### Key Design Decisions (see ARCHITECTURE.md for full ADRs)

1. **Thin Bootstrap / Thick Installer**: `bootstrap.sh` does only token discovery, validation, and streaming. No git cloning, no package installs, no `.env` creation. All provisioning logic lives in `install.sh`.

2. **Token Discovery Order**: inline env var → `./.env` → `~/.dotfiles/.env` → interactive prompt. Commented lines in `.env` are ignored (regex `^GITHUB_DOTFILES_TOKEN=`).

3. **Streaming Execution**: `bootstrap.sh` downloads `install.sh` into a variable via `wget` with the PAT in the Authorization header, then executes via `bash <(printf ...)`. This avoids writing the installer to disk and keeps stdin unblocked for `install.sh`'s interactive prompts.

4. **Idempotency**: All scripts must be safe to re-run. `install_env.sh` uses a marker (`# [CUSTOM_ENV]`) to detect if the profile block was already added.

### Directory Roles
- `bootstrap.sh` — entrypoint, ultra-lightweight (~70 lines, only uses `wget`)
- `install.sh` — modular installer (packages, Chrome prompt, future: Stow symlinking)
- `install_env.sh` — standalone: creates `~/.env_private` + wires it into `~/.profile`
- `bash/.bash_aliases` — dotfile profile (targeted for GNU Stow symlinking to `$HOME`)
- `git/.gitconfig` — dotfile profile (targeted for GNU Stow symlinking to `$HOME`)
- `tests/run_smoke_tests.sh` — semi-automated test harness with ANSI-colored output
- `tests/.env.tests.example` — template for local test config (real file `.env.tests` is gitignored)

## Coding Standards (from AI.md)

- Every script starts with `set -euo pipefail`
- No hardcoded secrets — `.env` is gitignored; use `.env.example` for templates
- Idempotent operations: check before create/install
- `LANG=C` prefix on `wget` in `bootstrap.sh` ensures English error messages regardless of system locale

## Testing

The test suite (`tests/run_smoke_tests.sh`) covers:
- **Block 1** (Token Discovery): TC-1.1 (empty input), TC-1.2 (inline env), TC-1.3 (file parsing), TC-1.4 (commented lines ignored)
- **Block 2** (Validation & Streaming): TC-2.1 (invalid token rejected), TC-2.2 (valid token — requires real PAT in `tests/.env.tests`)

TC-2.2 is **skipped** unless you provide a real token in `tests/.env.tests` (copy from `.env.tests.example`).

## Git Workflow

- **Style:** GitHub Flow + trunk-based. Short-lived feature branches, everything stacks into `main`. `main` is always deployable (the bootstrapper streams from it).
- **Branch prefixes** — Conventional Commits: `feat/...`, `fix/...`, `docs/...`, `chore/...`. Reserved for future use: `refactor/...`, `test/...`, `ci/...`, `build/...`, `hotfix/...`.
- **No direct commits to `main`.** Only via feature branch + PR.
- **Atomic commits.** One commit = one logical step. Messages follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `chore:`, etc.) with a body that includes context: `Why:`, behavior, edge cases, risks. Always add trailer `Co-Authored-By: Claude <noreply@anthropic.com>`. See existing commits as reference.
- **Merge — fast-forward only.** No merge commits, no squash-merge into `main`. Linear history.
- **PR workflow, but final merge is local ff:**
  1. Open PR (`gh pr create`) for description and discussion.
  2. Before merge: `git fetch`, rebase feature branch onto fresh `main`, `git push --force-with-lease`.
  3. Locally: `git checkout main && git pull --ff-only && git merge --ff-only <branch>` → `git push origin main`.
  4. PR closes automatically as merged — no merge commit in history.
- **`gh` is available and authenticated.** Pre-installed `ssh` protocol for git. Call `gh pr create`, `gh pr view`, `gh pr merge --delete-branch`, etc. directly.
- **Sync at session start.** Before any git operation: `git fetch` + verify local `main` matches `origin/main`. If local is ahead — that's an anomaly (shouldn't happen with our style), stop and discuss before any rebase/merge.
- **No merge commits** even if GitHub suggests "Merge pull request". Only rebase + ff or local ff.

## Current Project Phase

Phase 1 (Secure Authentication Setup) is the active focus — see `BACKLOG.md` for roadmap status.
