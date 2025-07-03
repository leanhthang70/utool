#!/bin/bash

# WSL2 Add Alias Script
# This script adds useful aliases for development environments

echo "Adding useful aliases for WSL2 development environment..."

# Backup existing .bashrc
if [ -f ~/.bashrc ]; then
    cp ~/.bashrc ~/.bashrc.backup.$(date +%Y%m%d_%H%M%S)
    echo "Backed up existing .bashrc"
fi

# Add aliases to .bashrc
cat >> ~/.bashrc << 'EOF'

# ==========================================
# UTool WSL2 Development Aliases
# ==========================================

# General aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gb='git branch'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline'

# Rails aliases
alias be='bundle exec'
alias ber='bundle exec rails'
alias bers='bundle exec rails server'
alias berc='bundle exec rails console'
alias berd='bundle exec rails db:migrate'
alias bert='bundle exec rails test'
alias berspec='bundle exec rspec'

# Docker aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dex='docker exec -it'
alias dlog='docker logs'

# System aliases
alias update='sudo apt update && sudo apt upgrade'
alias install='sudo apt install'
alias search='apt search'
alias h='history'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Navigation aliases
alias home='cd ~'
alias root='cd /'
alias downloads='cd ~/Downloads'
alias documents='cd ~/Documents'

# Process aliases
alias ps='ps aux'
alias psg='ps aux | grep'
alias top='htop'

# Network aliases
alias ports='netstat -tuln'
alias myip='curl -s checkip.amazonaws.com'

# Development aliases
alias serve='python3 -m http.server'
alias tree='tree -C'
alias cls='clear'
alias c='clear'

echo "UTool WSL2 aliases loaded successfully!"
EOF

echo "Aliases added to ~/.bashrc"
echo "Please run 'source ~/.bashrc' or restart your terminal to apply changes"
echo "Or run: exec bash"

# Apply immediately
source ~/.bashrc
echo "Aliases applied to current session!"
