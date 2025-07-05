#!/bin/bash

# WSL2 Bash Init Setup Script
# This script fixes the issue where WSL doesn't automatically load ~/.bashrc
# and sets up proper bash initialization

# Backup existing files
backup_suffix=".backup.$(date +%Y%m%d_%H%M%S)"

if [ -f ~/.bash_profile ]; then
    cp ~/.bash_profile ~/.bash_profile$backup_suffix
fi

if [ -f ~/.profile ]; then
    cp ~/.profile ~/.profile$backup_suffix
fi

if [ -f ~/.bashrc ]; then
    cp ~/.bashrc ~/.bashrc$backup_suffix
fi

# Create/update ~/.bash_profile to source ~/.bashrc
cat > ~/.bash_profile << 'EOF'
# ~/.bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# User specific environment and startup programs
PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH
EOF

# Create/update ~/.profile to also source ~/.bashrc
cat > ~/.profile << 'EOF'
# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login exists.

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
EOF

# Ensure ~/.bashrc exists and has proper structure
if [ ! -f ~/.bashrc ]; then
    cat > ~/.bashrc << 'EOF'
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
EOF
else
    # Add sourcing check to existing ~/.bashrc if not present
    if ! grep -q "# UTool bash init setup" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# ==========================================
# UTool bash init setup
# ==========================================
EOF
    fi
fi

# Create ~/.bash_logout for cleanup
cat > ~/.bash_logout << 'EOF'
# ~/.bash_logout: executed by bash(1) when login shell exits.

# when leaving the console clear the screen to increase privacy
if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
fi
EOF

echo ""
echo "✅ Bash initialization setup completed!"
echo ""
echo "📋 What was configured:"
echo "  • ~/.bash_profile - Sources ~/.bashrc for login shells"
echo "  • ~/.profile - Sources ~/.bashrc for POSIX compatibility"  
echo "  • ~/.bashrc - Main bash configuration file"
echo "  • ~/.bash_logout - Cleanup when exiting"
echo ""
echo "🔧 This fixes the WSL issue where ~/.bashrc isn't automatically loaded"
echo "   Now ~/.bashrc will be loaded for both login and non-login shells"
echo ""
echo "💡 To apply changes immediately, run one of:"
echo "   source ~/.bash_profile"
echo "   exec bash"
echo "   or restart your terminal"
echo ""
echo "🎉 WSL2 Bash initialization setup complete!"
