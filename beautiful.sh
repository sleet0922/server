#!/bin/bash

cat > "$HOME/.bashrc" << 'EOF'
# ~/.bashrc: executed by bash(1) for non-login shells.

PS1='${debian_chroot:+($debian_chroot)}\[\033[01;92m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

if [ ! -f ~/.dircolors ]; then
    dircolors -p > ~/.dircolors
fi
sed -i 's/^DIR.*01;34/DIR 01;36/' ~/.dircolors
eval "$(dircolors ~/.dircolors)"
export LS_OPTIONS='--color=auto'

alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias la='ls $LS_OPTIONS -la'
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'
alias update='apt update && apt upgrade -y'
alias cls='clear'

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

export LESS_TERMCAP_mb=$'\E[01;92m'
export LESS_TERMCAP_md=$'\E[01;92m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;92m'
EOF

# 应用配置
source "$HOME/.bashrc"

echo "~/.bashrc已更新并生效"
