# CI and Testing Strategy

This repo keeps CI lightweight and keeps Windows install validation as a manual release gate.

## Why Windows smoke is manual

The installer is designed for a real Windows session with:

- administrator/UAC approval
- optional reboot and same-user sign-in
- WSL install and distro first boot
- optional interactive GitHub authentication
- access to Docker Desktop if those checks are enabled

Those requirements make hosted CI a poor fit, so this repo does not include an always-on GitHub Actions WSL smoke workflow.

## Included workflows

### `lint.yml`
Runs shell linting on pull requests.

### `release-package-attest.yml`
Builds the release ZIP, generates GitHub artifact attestations, and publishes the release asset when a `v*` tag is pushed.

### `release-signing-placeholder.yml`
Scaffold for Windows signing integration. It is intentionally a placeholder because real signing depends on your certificate or signing provider.

## Manual Windows validation

Before pushing a release tag:

1. Validate the installer on at least one clean Windows environment by double-clicking `setup-wsl-dev.bat` from Explorer as a standard user. Confirm the UAC prompt appears before any crash and the installer reaches the prerequisite prompt.
2. Validate the installer on at least one already-configured WSL environment.
3. Trigger one visible failure case, such as declining the prerequisite confirmation, and confirm the terminal stays open long enough to read the error.
4. Exercise the resume path and confirm relaunches use `-Resume` and complete successfully after the required reboot/sign-in step.
5. Run `scripts/Invoke-WSLSmoke.ps1 -Distro Ubuntu` after install.
6. Confirm the release ZIP contains the expected files.

If you later operate a trusted Windows environment and want automated smoke coverage, add a separate private workflow that you control and maintain.
