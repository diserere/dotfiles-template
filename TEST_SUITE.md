# Test Suite: Bootstrapper & Authentication Matrix

This file defines the acceptance criteria and test cases for `bootstrap.sh`. AI agents must ensure all modifications pass this test suite without regressions.

## Environment Layout for Testing
- Host OS: Ubuntu 26.04 Desktop (clean install)
- Network: Active internet connection
- Workspace: Working directory with optional `.env` file

---

## 🧪 Test Suite 1: Token Discovery (Pre-execution States)

### TC-1.1: Clean Environment (Fallback to Interactive Prompt)
* **Pre-conditions**: No `GITHUB_DOTFILES_TOKEN` in env. No local `.env` file exists.
* **Action**: Run `./bootstrap.sh`
* **Expected Result**: 
  - Output displays: `GitHub token not found in files or environment.`
  - Script pauses and prompts: `Please enter your GitHub PAT:`
  - Input must be masked (`-s` flag active).

### TC-1.2: Inline Token Injection (Environment Priority)
* **Pre-conditions**: Local `.env` file contains a fake token, but command is run with inline export.
* **Action**: Run `GITHUB_DOTFILES_TOKEN="valid_or_invalid_token" ./bootstrap.sh`
* **Expected Result**: 
  - Script bypasses both file checking and interactive prompt.
  - Instantly proceeds to "Validating GitHub token..." stage.

### TC-1.3: Token from Local `.env` (File Parsing)
* **Pre-conditions**: Local `./.env` exists and contains un-commented line: `GITHUB_DOTFILES_TOKEN="any_token_here"`
* **Action**: Run `./bootstrap.sh`
* **Expected Result**:
  - Output displays: `Found valid GITHUB_DOTFILES_TOKEN in ./.env.`
  - Script skips interactive prompt and proceeds to validation.

### TC-1.4: Commented Token in `.env` (RegEx Verification)
* **Pre-conditions**: Local `./.env` exists, but lines are commented out: `# GITHUB_DOTFILES_TOKEN="..."`
* **Action**: Run `./bootstrap.sh`
* **Expected Result**:
  - Script detects the file, but ignores commented lines.
  - Falls back to TC-1.1 behavior (shows token not found and prompts user).

---

## 🧪 Test Suite 2: Validation & Error Handling

### TC-2.1: Empty Input Handling
* **Pre-conditions**: Script triggers interactive prompt (TC-1.1).
* **Action**: Press `[ENTER]` without typing anything.
* **Expected Result**:
  - Script terminates immediately.
  - Error message to stderr: `Error: Token cannot be empty.`
  - Exit code: `1`

### TC-2.2: Invalid Token Handling (Regression Fix for Bug #1)
* **Pre-conditions**: Token is provided via input or file, but it is invalid (e.g., `qwe` or `fake-token`).
* **Action**: Run validation stage.
* **Expected Result**:
  - `wget` query to GitHub API catches HTTP 401.
  - Error message to stderr: `Error: GitHub token validation failed (HTTP Status: 401).`
  - Script terminates immediately with exit code `1`. (Must NOT stream installer).

### TC-2.3: Happy Path (End-to-End Execution)
* **Pre-conditions**: Valid GitHub PAT is provided (via Env, File, or Input).
* **Action**: Run script to completion.
* **Expected Result**:
  - Output displays: `Token successfully validated (HTTP 200)!`
  - Output displays: `Streaming installer from repository...`
  - Downstream `install.sh` is downloaded and executed successfully.
  - **Crucial**: Standard Input (`stdin`) remains unblocked inside `install.sh` for subsequent interactive menus.
