param(
    [Parameter(Mandatory=$true)][string]$PackageIdentifier,
    [Parameter(Mandatory=$true)][string]$PackageVersion,
    [Parameter(Mandatory=$true)][string]$Publisher,
    [Parameter(Mandatory=$true)][string]$PackageName,
    [Parameter(Mandatory=$true)][string]$InstallerUrl,
    [Parameter(Mandatory=$true)][string]$InstallerSha256,
    [string]$OutputRoot = ".\winget\manifests"
)

$ErrorActionPreference = "Stop"

$parts = $PackageIdentifier.Split('.')
if ($parts.Length -lt 2) {
    throw "PackageIdentifier should look like Publisher.PackageName"
}

$publisherRoot = $parts[0]
$packageRoot = $parts[1]
$dest = Join-Path $OutputRoot "$publisherRoot\$packageRoot\$PackageVersion"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$versionManifest = @"
PackageIdentifier: $PackageIdentifier
PackageVersion: $PackageVersion
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.6.0
"@

$installerManifest = @"
PackageIdentifier: $PackageIdentifier
PackageVersion: $PackageVersion
InstallerType: zip
Installers:
  - Architecture: x64
    InstallerUrl: $InstallerUrl
    InstallerSha256: $InstallerSha256
ManifestType: installer
ManifestVersion: 1.6.0
"@

$localeManifest = @"
PackageIdentifier: $PackageIdentifier
PackageVersion: $PackageVersion
PackageLocale: en-US
Publisher: $Publisher
PackageName: $PackageName
ShortDescription: Portable Windows installer that bootstraps a WSL developer environment.
ManifestType: defaultLocale
ManifestVersion: 1.6.0
"@

Set-Content -Path (Join-Path $dest "$PackageIdentifier.yaml") -Value $versionManifest -Encoding utf8
Set-Content -Path (Join-Path $dest "$PackageIdentifier.installer.yaml") -Value $installerManifest -Encoding utf8
Set-Content -Path (Join-Path $dest "$PackageIdentifier.locale.en-US.yaml") -Value $localeManifest -Encoding utf8

Write-Host "Created WinGet manifests in $dest"
