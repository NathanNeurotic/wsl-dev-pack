# Production Add-On Kit

This add-on kit extends WSL Dev Pack with production-oriented scaffolding for:

- self-hosted Windows WSL smoke testing
- release packaging with GitHub artifact attestations
- signing workflow placeholders
- WinGet manifest generation helpers
- supporting documentation for CI, signing, and distribution

## Included files

- `.github/workflows/windows-self-hosted-wsl-smoke.yml`
- `.github/workflows/release-package-attest.yml`
- `.github/workflows/release-signing-placeholder.yml`
- `scripts/Invoke-WSLSmoke.ps1`
- `scripts/New-WinGetManifest.ps1`
- `docs/CI-TESTING.md`
- `docs/SELF_HOSTED_WINDOWS_RUNNER.md`
- `docs/SIGNING.md`
- `docs/WINGET.md`
- `winget/manifests/...`

## Intended use

Merge these files into the main repository after reviewing them and adapting any placeholders to your release process.
