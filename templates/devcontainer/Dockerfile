FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update && apt-get install -y \
    git curl wget ca-certificates jq ripgrep fd-find fzf bat tree htop tmux zoxide bash-completion \
    && rm -rf /var/lib/apt/lists/*
