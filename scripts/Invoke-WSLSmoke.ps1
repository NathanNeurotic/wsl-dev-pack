param(
    [string]$Distro = "Ubuntu"
)

$ErrorActionPreference = "Stop"

Write-Host "=== WSL smoke test ==="

wsl --status
wsl -l -v

Write-Host "Checking distro: $Distro"
wsl -d $Distro -- bash -lc "echo ok-from-wsl"

Write-Host "Checking systemd"
wsl -d $Distro -- bash -lc "systemctl is-system-running || true"

Write-Host "Checking mounts"
wsl -d $Distro -- bash -lc "mount | grep /mnt/c || true"

Write-Host "Checking git and ssh"
wsl -d $Distro -- bash -lc "git --version"
wsl -d $Distro -- bash -lc "ssh -V"

Write-Host "Smoke test complete."
