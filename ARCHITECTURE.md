# Architecture Decision Records (ADR)

## ADR 1: Thin Bootstrap vs Thick Installer
* **Context**: The user installs environment on a fresh machine. They copy-paste the code from GitHub README into the terminal.
* **Decision**: `bootstrap.sh` must remain ultra-lightweight and compact. Its only jobs are:
  1. Detect/Prompt for GitHub Personal Access Token (PAT).
  2. Validate the token.
  3. Stream and execute `install.sh` from the private repository via `wget` using the token.
* **Consequences**: No git cloning, no local `.env` creation, and no heavy logic inside `bootstrap.sh`. All business logic is deferred to `install.sh`.

## ADR 2: Modular and Interactive Installer
* **Context**: Users (and QA engineers during debugging) need to re-run the setup multiple times without triggering full system updates.
* **Decision**: `install.sh` will be split into modular stages (e.g., Package Installation, GNU Stow Symlinking, Environment Verification). The script will prompt the user interactively for each stage, allowing safe re-runs (idempotency).
