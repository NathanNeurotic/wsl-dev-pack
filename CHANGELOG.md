# Changelog

## v2.0.1
- Fixed the Windows launcher so it self-elevates before creating `C:\ProgramData\WSLDevPack` directories or transcript logs
- Standardized installer relaunches and `RunOnce` resume registration on the PowerShell `-Resume` switch
- Kept launcher failures visible in both `setup-wsl-dev.ps1` and `setup-wsl-dev.bat` instead of closing immediately
- Requested the GitHub CLI public-key scopes needed for automatic SSH key upload
- Expanded the manual Windows release gate to include Explorer launch, visible failure handling, and resume-path validation

## v2.0.0
- Added optional Docker Desktop / WSL integration checks
- Added optional generic devcontainer scaffolding
- Added optional generic VS Code workspace extension recommendations
- Added optional GitHub SSH key upload via GitHub CLI
- Added optional generic repo cloning
- Added portable release-friendly structure with templates and logs
- Simplified release automation to a single attested tag workflow
- Kept Windows smoke validation as a manual release gate

## v1.0.0
- Basic WSL bootstrap
- Bash / Git / SSH / zoxide provisioning
