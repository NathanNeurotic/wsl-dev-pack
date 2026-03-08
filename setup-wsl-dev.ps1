param(
    [switch]$Resume
)

$ErrorActionPreference = "Stop"

$ScriptPath   = $MyInvocation.MyCommand.Path
$ScriptDir    = Split-Path -Parent $ScriptPath
$LauncherBat  = Join-Path $ScriptDir "setup-wsl-dev.bat"

$StateDir     = Join-Path $env:ProgramData "WSLDevPack"
$WorkDir      = Join-Path $StateDir "work"
$LogsDir      = Join-Path $StateDir "logs"
$StatePath    = Join-Path $StateDir "state.json"
$RunOnceName  = "WSLDevPackResume"
$WslExe       = Join-Path $env:SystemRoot "System32\wsl.exe"
$Timestamp    = Get-Date -Format "yyyyMMdd-HHmmss"
$Transcript   = Join-Path $LogsDir "setup-$Timestamp.log"

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) { New-Item -ItemType Directory -Path $Path -Force | Out-Null }
}

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $enc)
}

function Ask-Default {
    param([string]$Prompt, [string]$Default)
    $v = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($v)) { return $Default }
    return $v.Trim()
}

function Ask-Required {
    param([string]$Prompt)
    while ($true) {
        $v = Read-Host $Prompt
        if (-not [string]::IsNullOrWhiteSpace($v)) { return $v.Trim() }
        Write-Host "A value is required."
    }
}

function Ask-YesNo {
    param([string]$Prompt, [bool]$Default = $true)
    $suffix = if ($Default) { "Y/n" } else { "y/N" }
    while ($true) {
        $v = Read-Host "$Prompt [$suffix]"
        if ([string]::IsNullOrWhiteSpace($v)) { return $Default }
        switch ($v.Trim().ToLowerInvariant()) {
            "y" { return $true }
            "yes" { return $true }
            "n" { return $false }
            "no" { return $false }
            default { Write-Host "Please answer yes or no." }
        }
    }
}

function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Elevated {
    if (Test-IsAdmin) { return }
    $argList = @("-NoProfile","-ExecutionPolicy","Bypass","-File","`"$ScriptPath`"")
    if ($Resume) { $argList += "--resume" }
    Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $argList
    exit 0
}

function Save-State {
    param([hashtable]$State)
    Ensure-Dir $StateDir
    $json = $State | ConvertTo-Json -Depth 12
    Write-Utf8NoBom -Path $StatePath -Content $json
}

function Load-State {
    if (-not (Test-Path $StatePath)) { throw "State file not found: $StatePath" }
    return Get-Content $StatePath -Raw | ConvertFrom-Json
}

function Register-Resume {
    $cmd = "cmd.exe /c `"$LauncherBat`" --resume"
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v $RunOnceName /t REG_SZ /d $cmd /f | Out-Null
}

function Clear-Resume {
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" /v $RunOnceName /f 2>$null | Out-Null
}

function WinPath-To-WslPath {
    param([string]$WindowsPath)
    $full = [System.IO.Path]::GetFullPath($WindowsPath)
    $drive = $full.Substring(0,1).ToLowerInvariant()
    $rest = $full.Substring(2).Replace("\","/")
    return "/mnt/$drive$rest"
}

function Get-DistroList {
    $out = & $WslExe -l -q 2>$null
    if ($LASTEXITCODE -ne 0) { return @() }
    return @($out -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Test-DistroExists {
    param([string]$Distro)
    return (Get-DistroList) -contains $Distro
}

function Test-UbuntuLike {
    param([string]$Distro)
    return $Distro -match '^Ubuntu'
}

function Try-WslRootProbe {
    param([string]$Distro)
    & $WslExe -d $Distro -u root -- bash -lc "echo ready" 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Backup-File {
    param([string]$Path)
    if (Test-Path $Path) {
        $name = Split-Path $Path -Leaf
        $dest = Join-Path $WorkDir "$name.backup-$Timestamp"
        Copy-Item -Path $Path -Destination $dest -Force
        Write-Host "Backup created: $dest"
    }
}

function Pause-And-ExitForReboot {
    param([string]$Reason)
    Write-Host ""
    Write-Host $Reason
    Write-Host "A reboot is required."
    Write-Host "This script is registered to resume automatically after sign-in."
    exit 0
}

Ensure-Dir $StateDir
Ensure-Dir $WorkDir
Ensure-Dir $LogsDir
Start-Transcript -Path $Transcript -Append | Out-Null

try {
    Ensure-Elevated

    if ($Resume) {
        $stateObj = Load-State
        $State = @{}
        $stateObj.PSObject.Properties | ForEach-Object { $State[$_.Name] = $_.Value }
        Write-Host "Resuming previous setup..."
    } else {
        Write-Host ""
        Write-Host "=== WSL Dev Pack v2 ==="
        Write-Host ""
        Write-Host "Manual prerequisites:"
        Write-Host "  1. Run this from Windows."
        Write-Host "  2. Internet access must be available."
        Write-Host "  3. You must be able to approve UAC elevation."
        Write-Host "  4. Virtualization must be enabled if WSL2 is not already working."
        Write-Host "  5. You must be able to reboot and sign back into this same Windows account."
        Write-Host ""
        if (-not (Ask-YesNo "Have you completed the prerequisites?" $false)) {
            throw "Prerequisites were not confirmed."
        }

        $defaultUser = [Environment]::UserName
        $State = @{
            Distro                  = Ask-Default "WSL distro name" "Ubuntu"
            LinuxUser               = Ask-Default "Linux username" $defaultUser
            MemoryGB                = Ask-Default "WSL memory limit in GB" "8"
            Processors              = Ask-Default "WSL CPU count" "4"
            GitName                 = Ask-Default "Git user.name" $defaultUser
            GitEmail                = Ask-Required "Git user.email"
            RepoRoot                = ""
            SetupSSH                = $true
            RunGhLogin              = $true
            UploadGitHubSSHKey      = $true
            GitHubSSHKeyTitle       = ""
            CloneRepo               = $false
            RepoUrl                 = ""
            RepoDest                = ""
            BootstrapExistingRepo   = $false
            ExistingRepoPath        = ""
            CreateDevContainer      = $true
            CreateVSCodeExtensions  = $true
            CheckDockerDesktop      = $true
            NopasswdSudo            = $true
            CreatedCloudInit        = $false
        }

        $State.RepoRoot               = Ask-Default "Default repo root inside WSL" "/home/$($State.LinuxUser)/Github"
        $State.SetupSSH               = Ask-YesNo "Generate SSH key if missing?" $true
        $State.RunGhLogin             = Ask-YesNo "Run 'gh auth login' at the end?" $true
        $State.UploadGitHubSSHKey     = Ask-YesNo "Upload the SSH public key to GitHub automatically after login?" $true
        if ($State.UploadGitHubSSHKey) {
            $State.GitHubSSHKeyTitle = Ask-Default "GitHub SSH key title" "$env:COMPUTERNAME WSL"
        }
        $State.NopasswdSudo           = Ask-YesNo "Grant passwordless sudo to the Linux user?" $true
        $State.CheckDockerDesktop     = Ask-YesNo "Perform Docker Desktop / WSL integration checks?" $true
        $State.CloneRepo              = Ask-YesNo "Clone a Git repository?" $false
        if ($State.CloneRepo) {
            $State.RepoUrl = Ask-Required "Repository URL"
            $leaf = [System.IO.Path]::GetFileNameWithoutExtension($State.RepoUrl.TrimEnd('/'))
            if ([string]::IsNullOrWhiteSpace($leaf)) { $leaf = "repo" }
            $State.RepoDest = Ask-Default "Clone destination inside WSL" "$($State.RepoRoot)/$leaf"
            $State.BootstrapExistingRepo = $true
            $State.ExistingRepoPath = $State.RepoDest
        } else {
            $State.BootstrapExistingRepo = Ask-YesNo "Bootstrap an existing repository path with generic devcontainer files?" $false
            if ($State.BootstrapExistingRepo) {
                $State.ExistingRepoPath = Ask-Required "Existing repo path inside WSL"
            }
        }
        if ($State.BootstrapExistingRepo) {
            $State.CreateDevContainer     = Ask-YesNo "Create a generic .devcontainer scaffold?" $true
            $State.CreateVSCodeExtensions = Ask-YesNo "Create a generic .vscode/extensions.json recommendation file?" $true
        } else {
            $State.CreateDevContainer     = $false
            $State.CreateVSCodeExtensions = $false
        }

        Save-State $State
    }

    Write-Host ""
    Write-Host "=== Writing Windows-side WSL config ==="
    $wslConfigPath = Join-Path $env:USERPROFILE ".wslconfig"
    Backup-File $wslConfigPath
    $wslConfigContent = @"
[wsl2]
memory=$($State.MemoryGB)GB
processors=$($State.Processors)
localhostForwarding=true
"@
    [System.IO.File]::WriteAllText($wslConfigPath, $wslConfigContent, (New-Object System.Text.UTF8Encoding($false)))

    $needsInstall = -not (Test-DistroExists $State.Distro)

    if ($needsInstall -and (Test-UbuntuLike $State.Distro)) {
        Write-Host "Preparing first-boot Ubuntu user automation..."
        $cloudInitDir = Join-Path $env:USERPROFILE ".cloud-init"
        Ensure-Dir $cloudInitDir
        $userDataPath = Join-Path $cloudInitDir "$($State.Distro).user-data"
        $sudoLine = if ($State.NopasswdSudo) { "ALL=(ALL) NOPASSWD:ALL" } else { "ALL=(ALL) ALL" }
        $cloudInit = @"
#cloud-config
users:
  - default
  - name: $($State.LinuxUser)
    groups: [sudo]
    shell: /bin/bash
    sudo: "$sudoLine"
    lock_passwd: true
package_update: true
package_upgrade: false
"@
        [System.IO.File]::WriteAllText($userDataPath, $cloudInit, (New-Object System.Text.UTF8Encoding($false)))
        $State.CreatedCloudInit = $true
        Save-State $State
    }

    if ($needsInstall) {
        Write-Host ""
        Write-Host "=== Installing / enabling WSL and distro ==="
        Register-Resume
        & $WslExe --set-default-version 2 2>$null | Out-Null
        & $WslExe --install -d $State.Distro
        $installExit = $LASTEXITCODE

        if ($installExit -ne 0) {
            dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
            dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
            Save-State $State
            Pause-And-ExitForReboot "Windows WSL features were enabled."
        }

        Start-Sleep -Seconds 5
        if (-not (Test-DistroExists $State.Distro)) {
            Save-State $State
            Pause-And-ExitForReboot "The distro is not visible yet."
        }
        if (-not (Try-WslRootProbe $State.Distro)) {
            Save-State $State
            Pause-And-ExitForReboot "The distro is installed but not yet ready for provisioning."
        }
    }

    Write-Host ""
    Write-Host "=== Building Linux provisioning payload ==="

    $bashrcPathWin    = Join-Path $WorkDir "bashrc"
    $wslConfPathWin   = Join-Path $WorkDir "wsl.conf"
    $provisionPathWin = Join-Path $WorkDir "provision.sh"

    $bashrcContent = @'
# ~/.bashrc: executed by bash(1) for non-login shells.

case $- in
    *i*) ;;
      *) return ;;
esac

HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=2000
HISTFILESIZE=4000
shopt -s checkwinsize

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

parse_git_branch() {
    git branch 2>/dev/null | sed -n "/\* /s///p"
}

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes ;;
esac

if [ "${color_prompt:-}" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;33m\] $(parse_git_branch)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w $(parse_git_branch)\$ '
fi
unset color_prompt

case "$TERM" in
    xterm*|rxvt*)
        PS1="\[\e]0;\u@\h: \w\a\]$PS1"
        ;;
esac

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias la='ls -A'
alias l='ls -CF'
alias ll='ls -lah'

alias g='git'
alias gs='git status'
alias gp='git pull'
alias gpush='git push'
alias gd='git diff'
alias gc='git commit'
alias gco='git checkout'
alias gb='git branch'
alias gl='git log --oneline --graph --decorate --all'
alias gaa='git add .'
alias gcm='git commit -m'
alias gpl='git pull'
alias gps='git push'

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

if [ -z "${SSH_AUTH_SOCK:-}" ]; then
    eval "$(ssh-agent -s)" >/dev/null 2>&1
fi

if [ -n "${SSH_AUTH_SOCK:-}" ]; then
    ssh-add -l >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        ssh-add ~/.ssh/id_ed25519 >/dev/null 2>&1
    fi
fi

eval "$(zoxide init bash)"
'@

    $wslConfContent = @"
[boot]
systemd=true

[user]
default=$($State.LinuxUser)

[automount]
enabled = true
root = /mnt/
options = "metadata,uid=1000,gid=1000,umask=022,fmask=11,case=off"
mountFsTab = false

[interop]
enabled = true
appendWindowsPath = false
"@

    Write-Utf8NoBom -Path $bashrcPathWin -Content $bashrcContent
    Write-Utf8NoBom -Path $wslConfPathWin -Content $wslConfContent

    $bashrcPathWsl  = WinPath-To-WslPath $bashrcPathWin
    $wslConfPathWsl = WinPath-To-WslPath $wslConfPathWin

    $cloneRepoFlag = if ($State.CloneRepo) { "1" } else { "0" }
    $bootstrapFlag = if ($State.BootstrapExistingRepo) { "1" } else { "0" }
    $createDevFlag = if ($State.CreateDevContainer) { "1" } else { "0" }
    $createVSCFlag = if ($State.CreateVSCodeExtensions) { "1" } else { "0" }
    $setupSSHFlag  = if ($State.SetupSSH) { "1" } else { "0" }
    $nopassFlag    = if ($State.NopasswdSudo) { "1" } else { "0" }

    $provisionContent = @"
#!/usr/bin/env bash
set -euo pipefail

LINUX_USER='$($State.LinuxUser.Replace("'","'\"'\"'"))'
GIT_NAME='$($State.GitName.Replace("'","'\"'\"'"))'
GIT_EMAIL='$($State.GitEmail.Replace("'","'\"'\"'"))'
REPO_ROOT='$($State.RepoRoot.Replace("'","'\"'\"'"))'
SETUP_SSH='$setupSSHFlag'
NOPASSWD_SUDO='$nopassFlag'
CLONE_REPO='$cloneRepoFlag'
REPO_URL='$($State.RepoUrl.Replace("'","'\"'\"'"))'
REPO_DEST='$($State.RepoDest.Replace("'","'\"'\"'"))'
BOOTSTRAP_REPO='$bootstrapFlag'
BOOTSTRAP_REPO_PATH='$($State.ExistingRepoPath.Replace("'","'\"'\"'"))'
CREATE_DEVCONTAINER='$createDevFlag'
CREATE_VSCODE_EXT='$createVSCFlag'
BASHRC_SRC='$bashrcPathWsl'
WSLCONF_SRC='$wslConfPathWsl'

backup_if_exists() {
    local path="$1"
    if [ -e "$path" ]; then
        cp -f "$path" "$path.bak.$(date +%Y%m%d-%H%M%S)"
    fi
}

apt-get update
apt-get upgrade -y

apt-get install -y \
  build-essential git curl wget ca-certificates pkg-config unzip zip python3 python3-pip \
  software-properties-common ripgrep fd-find fzf bat tree jq htop tmux zoxide gh bash-completion

if ! id -u "$LINUX_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo "$LINUX_USER"
fi

if [ "$NOPASSWD_SUDO" = "1" ]; then
    echo "$LINUX_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$LINUX_USER-nopasswd"
    chmod 440 "/etc/sudoers.d/90-$LINUX_USER-nopasswd"
fi

mkdir -p "$REPO_ROOT"
chown -R "$LINUX_USER:$LINUX_USER" "/home/$LINUX_USER" "$REPO_ROOT" || true

backup_if_exists /etc/wsl.conf
install -m 644 "$WSLCONF_SRC" /etc/wsl.conf

backup_if_exists "/home/$LINUX_USER/.bashrc"
install -m 644 "$BASHRC_SRC" "/home/$LINUX_USER/.bashrc"
chown "$LINUX_USER:$LINUX_USER" "/home/$LINUX_USER/.bashrc"

echo 'fs.inotify.max_user_watches=524288' > /etc/sysctl.d/99-inotify.conf
sysctl --system >/dev/null || true

sudo -u "$LINUX_USER" git config --global user.name "$GIT_NAME"
sudo -u "$LINUX_USER" git config --global user.email "$GIT_EMAIL"
sudo -u "$LINUX_USER" git config --global core.autocrlf false
sudo -u "$LINUX_USER" git config --global core.filemode false
sudo -u "$LINUX_USER" git config --global core.preloadindex true
sudo -u "$LINUX_USER" git config --global gc.auto 256
sudo -u "$LINUX_USER" git config --global init.defaultBranch master
sudo -u "$LINUX_USER" git config --global pull.rebase false

mkdir -p "/home/$LINUX_USER/.ssh"
chmod 700 "/home/$LINUX_USER/.ssh"
cat > "/home/$LINUX_USER/.ssh/config" <<'EOF_SSHCFG'
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF_SSHCFG
chown "$LINUX_USER:$LINUX_USER" "/home/$LINUX_USER/.ssh/config"
chmod 600 "/home/$LINUX_USER/.ssh/config"

if [ "$SETUP_SSH" = "1" ] && [ ! -f "/home/$LINUX_USER/.ssh/id_ed25519" ]; then
    sudo -u "$LINUX_USER" ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "/home/$LINUX_USER/.ssh/id_ed25519" -N ""
fi

chmod 600 "/home/$LINUX_USER/.ssh/id_ed25519" 2>/dev/null || true
chmod 644 "/home/$LINUX_USER/.ssh/id_ed25519.pub" 2>/dev/null || true
chown -R "$LINUX_USER:$LINUX_USER" "/home/$LINUX_USER/.ssh"

if [ "$CLONE_REPO" = "1" ] && [ -n "$REPO_URL" ] && [ -n "$REPO_DEST" ] && [ ! -e "$REPO_DEST/.git" ]; then
    mkdir -p "$(dirname "$REPO_DEST")"
    chown -R "$LINUX_USER:$LINUX_USER" "$(dirname "$REPO_DEST")"
    sudo -u "$LINUX_USER" git clone "$REPO_URL" "$REPO_DEST"
fi

if [ "$BOOTSTRAP_REPO" = "1" ] && [ -n "$BOOTSTRAP_REPO_PATH" ] && [ -d "$BOOTSTRAP_REPO_PATH" ]; then
    mkdir -p "$BOOTSTRAP_REPO_PATH/.vscode"
    mkdir -p "$BOOTSTRAP_REPO_PATH/.devcontainer"

    if [ "$CREATE_VSCODE_EXT" = "1" ]; then
        cat > "$BOOTSTRAP_REPO_PATH/.vscode/extensions.json" <<'EOF_EXT'
{
  "recommendations": [
    "ms-vscode-remote.remote-containers",
    "ms-azuretools.vscode-docker",
    "ms-vscode.remote-explorer"
  ]
}
EOF_EXT
    fi

    if [ "$CREATE_DEVCONTAINER" = "1" ]; then
        cat > "$BOOTSTRAP_REPO_PATH/.devcontainer/devcontainer.json" <<'EOF_DCJSON'
{
  "name": "Generic Dev Container",
  "build": {
    "dockerfile": "Dockerfile",
    "context": ".."
  },
  "postCreateCommand": "bash .devcontainer/post-create.sh",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode-remote.remote-containers",
        "ms-azuretools.vscode-docker",
        "ms-vscode.remote-explorer"
      ]
    }
  },
  "remoteUser": "vscode"
}
EOF_DCJSON

        cat > "$BOOTSTRAP_REPO_PATH/.devcontainer/Dockerfile" <<'EOF_DOCKERFILE'
FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get install -y \
    git curl wget ca-certificates jq ripgrep fd-find fzf bat tree htop tmux zoxide bash-completion \
    && rm -rf /var/lib/apt/lists/*
EOF_DOCKERFILE

        cat > "$BOOTSTRAP_REPO_PATH/.devcontainer/post-create.sh" <<'EOF_POST'
#!/usr/bin/env bash
set -euo pipefail
git config --global --add safe.directory "$(pwd)" || true
echo "Devcontainer bootstrap complete."
EOF_POST
        chmod +x "$BOOTSTRAP_REPO_PATH/.devcontainer/post-create.sh"
    fi

    chown -R "$LINUX_USER:$LINUX_USER" "$BOOTSTRAP_REPO_PATH/.vscode" "$BOOTSTRAP_REPO_PATH/.devcontainer" || true
fi

echo "=== LINUX PROVISION COMPLETE ==="
"@

    Write-Utf8NoBom -Path $provisionPathWin -Content $provisionContent
    $provisionPathWsl = WinPath-To-WslPath $provisionPathWin

    Write-Host ""
    Write-Host "=== Provisioning Linux side ==="
    & $WslExe --set-default-version 2 2>$null | Out-Null
    & $WslExe -d $State.Distro -u root -- bash $provisionPathWsl
    if ($LASTEXITCODE -ne 0) { throw "Linux provisioning failed." }

    if ($State.CreatedCloudInit -and (Test-UbuntuLike $State.Distro)) {
        $userDataPath = Join-Path (Join-Path $env:USERPROFILE ".cloud-init") "$($State.Distro).user-data"
        if (Test-Path $userDataPath) { Remove-Item $userDataPath -Force }
    }

    & $WslExe --shutdown

    Write-Host ""
    Write-Host "=== Verification ==="
    & $WslExe -d $State.Distro -u $State.LinuxUser -- bash -lc "systemctl is-system-running || true"
    & $WslExe -d $State.Distro -u $State.LinuxUser -- bash -lc "mount | grep /mnt/c || true"
    & $WslExe -d $State.Distro -u $State.LinuxUser -- bash -lc "type z || true"
    & $WslExe -d $State.Distro -u $State.LinuxUser -- bash -lc "git config --global --list | grep -E 'user.name|user.email|core.autocrlf|core.filemode|core.preloadindex|gc.auto|init.defaultbranch|pull.rebase' || true"

    if ($State.CheckDockerDesktop) {
        Write-Host ""
        Write-Host "=== Docker Desktop / WSL checks ==="
        $dockerExe = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerExe) {
            Write-Host "Docker Desktop appears installed: $dockerExe"
        } else {
            Write-Host "Docker Desktop was not found in the standard Program Files path."
        }

        $dockerSettings = Join-Path $env:APPDATA "Docker\settings-store.json"
        if (Test-Path $dockerSettings) {
            Write-Host "Docker settings file found: $dockerSettings"
        } else {
            Write-Host "Docker settings-store.json not found in the default AppData path."
        }

        & $WslExe -d $State.Distro -u $State.LinuxUser -- bash -lc "docker version >/dev/null 2>&1 && echo 'Docker CLI reachable from WSL: yes' || echo 'Docker CLI reachable from WSL: no'"
        Write-Host "If Docker CLI is not reachable, open Docker Desktop and enable WSL integration for the target distro."
    }

    if ($State.RunGhLogin) {
        Write-Host ""
        Write-Host "=== GitHub login ==="
        & $WslExe -d $State.Distro -u $State.LinuxUser -- bash -lc "gh auth login"
    }

    if ($State.UploadGitHubSSHKey -and $State.SetupSSH) {
        Write-Host ""
        Write-Host "=== GitHub SSH key upload ==="
        $titleEsc = $State.GitHubSSHKeyTitle.Replace("'", "'\"'\"'")
        $cmd = @"
PUB=~/.ssh/id_ed25519.pub
if [ -f "\$PUB" ]; then
  KEY_CONTENT=\$(cat "\$PUB")
  if gh api user/keys --jq '.[].key' 2>/dev/null | grep -Fxq "\$KEY_CONTENT"; then
    echo 'SSH public key already exists on GitHub.'
  else
    gh ssh-key add "\$PUB" --title '$titleEsc' --type authentication
  fi
else
  echo 'No public SSH key file was found for upload.'
fi
"@
        & $WslExe -d $State.Distro -u $State.LinuxUser -- bash -lc $cmd
    }

    Write-Host ""
    Write-Host "=== Setup complete ==="
    Write-Host "Logs: $Transcript"
    Write-Host ""
    Write-Host "Suggested post-checks:"
    Write-Host "  source ~/.bashrc"
    Write-Host "  ssh -T git@github.com"
    Write-Host "  zoxide add $($State.RepoRoot)"
    Write-Host "  z $(Split-Path -Leaf $State.RepoRoot)"
    if ($State.CloneRepo -and $State.RepoDest) {
        Write-Host "  cd $($State.RepoDest)"
        Write-Host "  git status"
    }
    if ($State.BootstrapExistingRepo -and $State.ExistingRepoPath) {
        Write-Host "  cd $($State.ExistingRepoPath)"
        Write-Host "  ls -la .devcontainer .vscode"
    }

    Clear-Resume
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
}
