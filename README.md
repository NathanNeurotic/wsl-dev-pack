<img width="1536" height="1024" alt="ChatGPT Image Mar 9, 2026, 11_43_38 AM (1)" src="https://github.com/user-attachments/assets/026aa135-3cbc-4acf-8fb0-19ae1d4719fd" />

# WSL Dev Pack
A portable installer pack that bootstraps a complete Windows WSL development environment from almost any starting point.

It can install or repair a developer setup automatically, including Git, SSH, GitHub CLI, terminal tooling, Docker Desktop integration checks, and optional repository scaffolding.

## Features

### WSL setup
- Installs WSL if not already installed
- Installs a chosen Linux distribution, with Ubuntu as the default
- Configures WSL2
- Writes `%USERPROFILE%\.wslconfig`
- Writes `/etc/wsl.conf`
- Enables `systemd`

### Linux environment bootstrap
Installs common developer tools, including:

- git
- curl
- wget
- gh (GitHub CLI)
- python3 / pip
- ripgrep
- fd-find
- fzf
- bat
- tree
- jq
- htop
- tmux
- zoxide
- bash-completion

### Git and SSH setup
Optionally configures:

- Git username and email
- SSH configuration
- SSH key generation
- GitHub SSH key upload

### GitHub CLI integration
Optional flows include:

- `gh auth login`
- automatic SSH public key registration on GitHub

### Docker Desktop integration checks
Checks for:

- Docker Desktop installation
- Docker Desktop settings presence
- WSL integration availability
- Docker CLI visibility from WSL

The pack reports findings, but does not force Docker Desktop settings changes.

### Repository bootstrap
Optional flows include:

- cloning any Git repository
- scaffolding a generic `.devcontainer`
- scaffolding `.vscode/extensions.json`

### Shell environment
Creates a ready-to-use `.bashrc` including:

- git branch prompt
- ssh-agent auto start
- ssh key auto load
- zoxide integration
- useful git aliases

## What this project is for

This project is intended for:

- developer onboarding
- portable dev environment installers
- quick machine rebuilds
- WSL recovery
- reproducible local setup

## What this project does not do

This pack intentionally does not:

- install IDEs
- store credentials
- configure API keys
- install Docker Desktop automatically
- modify repositories without explicit user input

## Manual prerequisites

Users must complete these prerequisites themselves before running the installer:

- Windows 10 or Windows 11
- Administrator privileges
- Internet access
- BIOS or UEFI virtualization enabled if WSL2 is not already working
- Permission to reboot and sign back into the same Windows account if required

## Quick start

1. Download the latest release ZIP.
2. Extract the archive.
3. Double-click `setup-wsl-dev.bat` (supported entrypoint).
4. Follow the prompts.

## Typical workflow

```text
Download pack
↓
Run installer
↓
Install WSL
↓
Configure Linux environment
↓
Login to GitHub CLI
↓
Upload SSH key
↓
Clone repo
↓
Start development
```

## Repository structure

```text
WSL-Dev-Pack
│
├─ setup-wsl-dev.bat
├─ setup-wsl-dev.ps1
├─ README-FIRST.md
├─ CHANGELOG.md
│
├─ templates
│   ├─ devcontainer
│   │   ├─ devcontainer.json
│   │   ├─ Dockerfile
│   │   └─ post-create.sh
│   │
│   └─ codex
│       └─ README-CODEX.md
```

## Logging and safety

The installer includes:

- confirmation prompts
- backups where practical
- transcript logging after elevation succeeds
- non-destructive repo scaffolding
- visible launcher failures instead of an instant close

Logs are stored in the following location after elevation succeeds:

```text
C:\ProgramData\WSLDevPack\logs
```

## Supported distros

Tested primarily with Ubuntu. Other WSL distributions may work, but are not guaranteed.

## Recommended use cases

### Developer onboarding
Send the pack to new contributors so they can install everything with a single script.

### Open-source projects
Bundle the pack with your project to simplify contributor setup.

### Internal engineering teams
Provide a consistent development environment across machines.

### Rebuilding a broken WSL environment
Use the pack to repair or recreate common WSL setups.

## Contributing

Contributions are welcome. Useful areas for improvement include:

- additional distro support
- devcontainer customization
- Docker Desktop validation
- IDE integrations
- CI environment support

See `CONTRIBUTING.md` for workflow guidance.

## Security

Please review `SECURITY.md` before disclosing vulnerabilities.

## License

MIT License. See `LICENSE`.
