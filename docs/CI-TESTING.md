# CI and Testing Strategy

This kit adds production-oriented CI scaffolding for WSL Dev Pack.

## Important limitation

A true WSL2 end-to-end smoke test is best run on a **self-hosted Windows runner** with:

- virtualization enabled
- administrator rights
- reboot tolerance
- permission to run WSL and Docker Desktop

The included WSL smoke workflow is therefore configured for a **self-hosted Windows runner label**, not a GitHub-hosted runner.

## Included workflows

### `windows-self-hosted-wsl-smoke.yml`
Runs the installer in a controlled Windows environment and performs post-install verification.

Recommended runner labels:

- `self-hosted`
- `windows`
- `wsl`

### `release-package-attest.yml`
Builds a release ZIP and generates GitHub artifact attestations.

### `release-signing-placeholder.yml`
Scaffold for Windows signing integration. It is intentionally a placeholder because real signing depends on your certificate or signing provider.

## Suggested strategy

Use a layered approach:

1. Lint on pull requests
2. Package and attest on tags
3. Run full WSL smoke tests on a self-hosted Windows runner
4. Sign release artifacts only after build validation passes
