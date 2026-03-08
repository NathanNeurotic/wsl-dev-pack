# WSL Dev Pack v2

A portable Windows-first installer pack for bootstrapping or repairing a WSL developer machine from almost any starting point.

## Manual prerequisites before running

The user must do these themselves before continuing:

1. Run this from **Windows**, not from inside a Linux shell.
2. Internet access must be available.
3. The user must be able to approve **Administrator/UAC elevation**.
4. If WSL2 is not already working, **virtualization must be enabled in BIOS/UEFI**.
5. The user must be able to reboot and sign back into the **same Windows account** if the script requires it.
6. Any important WSL terminals should be closed before running the pack.
7. If the machine is work-managed, policy may block WSL, virtualization, Microsoft Store, winget, Docker Desktop, or GitHub auth.

## What the pack can do

- Prompt for user-only variables
- Confirm prerequisites before continuing
- Self-elevate
- Write `%USERPROFILE%\.wslconfig`
- Install WSL and the selected distro if missing
- Resume automatically after reboot through `RunOnce`
- Provision:
  - `/etc/wsl.conf`
  - `~/.bashrc`
  - Git defaults
  - SSH config + SSH key generation
  - GitHub CLI
  - `zoxide`
  - common CLI tools
  - `fs.inotify.max_user_watches=524288`
- Optionally:
  - run `gh auth login`
  - upload the SSH public key to GitHub automatically
  - clone any Git repository
  - scaffold a generic `.devcontainer`
  - scaffold a generic `.vscode/extensions.json`
  - perform Docker Desktop / WSL integration checks
- Create backups where practical
- Write logs under `C:\ProgramData\WSLDevPack\logs`

## Included files

- `setup-wsl-dev.bat` — launcher
- `setup-wsl-dev.ps1` — main orchestrator
- `README-FIRST.md` — this file
- `CHANGELOG.md`
- `templates/devcontainer/*`
- `templates/codex/*`

## Recommended usage

1. Extract the ZIP.
2. Read this file.
3. Double-click `setup-wsl-dev.bat`.
4. Answer the prompts carefully.
5. Reboot if the script tells you to.
6. If interactive GitHub auth is enabled, complete the browser/device flow.
