# Project Backlog & AI Context

## Core Stack
- OS: Linux (Ubuntu/Debian)
- Tooling: GNU Stow, Bash, Git
- Method: Agent-Driven Development (Context-as-Code)

## Project Roadmap

- [ ] **Phase 1: Secure Authentication Setup (`bootstrap.sh` focus)** <!-- CURRENT FOCUS -->
  - [ ] Implement `bootstrap.sh` token discovery (check env -> prompt user secretly).
  - [ ] Implement token validation mechanism (lightweight `wget`/`curl` check).
  - [ ] Implement secure streaming execution of downstream `install.sh` using the token.
- [ ] **Phase 2: Modular `install.sh` & Git Cloning**
  - [ ] Write `.env.example` template.
  - [ ] Implement interactive stages in `install.sh` (Clone, Create local `.env`, Package Install, Stow).
- [ ] **Phase 3: Stow Architecture Redesign**
  - [ ] Map internal directories (`bash`, `git`, `screen`) to match `$HOME` layout.
- [ ] **Phase 4: Cross-Platform Compatibility (Low Priority)**

## Active Tasks (Phase 1)
- [ ] Write the lightweight code for `bootstrap.sh`.
