# Release Process

## Release checklist

1. Update `CHANGELOG.md`.
2. Confirm `README.md` and `README-FIRST.md` match current behavior.
3. Validate the installer on at least one clean Windows environment.
4. Validate the installer on at least one already-configured WSL environment.
5. Run `powershell -ExecutionPolicy Bypass -File .\scripts\Invoke-WSLSmoke.ps1 -Distro Ubuntu` on the validation machine after install.
6. Push a release tag matching `v*` to trigger `.github/workflows/release-package-attest.yml`.
7. Confirm the generated GitHub release contains the expected ZIP contents and attestation.
8. Paste the release notes template below.

## Notes

- Windows smoke validation remains a manual release gate because the installer requires elevation, optional reboot handling, and other interactive Windows-only steps.

## Suggested release notes template

### Highlights
- Summarize the main improvements in this release.

### Added
- New features

### Changed
- Behavior changes
- Prompt changes
- New templates or scaffolds

### Fixed
- Bugs fixed
- Resume flow fixes
- Provisioning fixes

### Notes
- Known limitations
- Manual follow-up steps if any
