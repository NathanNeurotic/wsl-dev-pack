# Self-Hosted Windows Runner for WSL Smoke Tests

For production-grade WSL validation, use a self-hosted Windows runner.

## Recommended host requirements

- Windows 11
- virtualization enabled in BIOS/UEFI
- WSL allowed
- Administrator rights
- reliable internet access
- permission to reboot
- enough disk for WSL distro install and package installs

## Recommended labels

Assign these labels to the runner:

- `self-hosted`
- `windows`
- `wsl`

## Why self-hosted

A full WSL install-and-verify flow is more reliable on a dedicated Windows machine you control than on generic hosted CI infrastructure.

## Suggested maintenance

- snapshot the machine before major changes
- keep Windows updated
- keep WSL updated
- clear old distributions and logs between test runs where appropriate
