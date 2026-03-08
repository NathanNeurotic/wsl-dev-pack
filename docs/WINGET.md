# WinGet Packaging

This kit includes a basic WinGet manifest scaffold and a helper script.

## Important note

Publishing to WinGet is not just uploading a ZIP to your own repository.

A package is published by submitting a manifest to the public `microsoft/winget-pkgs` repository.

## Included files

- `scripts/New-WinGetManifest.ps1`
- `winget/manifests/...` example manifest set

## Basic process

1. Build a release and publish a stable downloadable asset
2. Generate SHA256 for the installer asset
3. Create WinGet manifests
4. Validate the manifests
5. Submit them to `microsoft/winget-pkgs`

## Recommended packaging approach

If your release is a ZIP-based bootstrap pack, document clearly what the user receives and how it is launched after install.

If you later create a more traditional installer, update the manifest accordingly.
