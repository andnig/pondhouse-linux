source ~/source/shell
source ~/.local/share/omarchy/default/bash/functions
source ~/source/custom-functions

bindkey "^?" backward-delete-char
bindkey "^[[3~" delete-char

if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
  export KITTY_SHELL_INTEGRATION="enabled"
  autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
  kitty-integration
  unfunction kitty-integration
fi


# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export FZF_BASE=$HOME/.fzf/bin/fzf

autoload -Uz compinit && compinit

# Manual plugin loading
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
# source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# When inside tmux, import desktop session vars from systemd user environment.
# Tmux server may have started from SSH or other context lacking these.
if [[ -n "$TMUX" ]] && command -v systemctl &>/dev/null; then
  eval "$(systemctl --user show-environment 2>/dev/null | grep -E '^(OMARCHY_PATH|HYPRLAND_INSTANCE_SIGNATURE|WAYLAND_DISPLAY|DISPLAY|XDG_CURRENT_DESKTOP|XDG_SESSION_TYPE|XDG_SESSION_DESKTOP)=')"
  [[ -n "$OMARCHY_PATH" ]] && export PATH="$OMARCHY_PATH/bin:$PATH"
fi

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
# else
#   Editor set in other ways
#   export EDITOR='nvim'
#   export SUDO_EDITOR="$EDITOR"
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


alias t='tmux attach || tmux new -s Work'

alias jq="sed -E 's/[\x00-\x1F\x7F]//g' | tr -d '\000-\037' | jq"

alias ssh="TERM=screen ssh"
alias vim=nvim

alias fo=find_and_open.sh
alias on="cd $HOME/.notes && nvim ."
alias os="cd $HOME/.sync"
alias nn="new_note.sh"

# File system
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias cat='bat --style=plain,header'
alias cl='clear'
alias cd="zd"
zd() {
  if [ $# -eq 0 ]; then
    builtin cd ~ && return
  elif [ -d "$1" ]; then
    builtin cd "$1"
  else
    z "$@" && printf " \U000F17A9 " && pwd || echo "Error: Directory not found"
  fi
}
open() {
  xdg-open "$@" >/dev/null 2>&1
}

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Find packages without leaving the terminal
alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"

alias locate="plocate"

function ntfy() {
    echo "Sending notification with message: $1"
    curl -d $1 "https://ntfy.devopsandmore.com/devops_notify"
}

# SSH Agent
# export SSH_AUTH_SOCK=~/.1password/agent.sock
# Alternative: If you don't want to use the 1Password SSH agent, you can use the following code to start a local ssh-agent and add your keys to ~/.ssh/. Disable the line above in this case.
# export SSH_AUTH_SOCK=~/.ssh/ssh-agent.$HOST.sock
# ALREADY_RUNNING=$(ssh-add -l > /dev/null; echo $?)
#
# if [[ $ALREADY_RUNNING != "0" ]]; then
#     if [[ -S $SSH_AUTH_SOCK ]]; then
#         # not expecting the socket to exist as the forwarding command isn't running (http://www.tldp.org/LDP/abs/html/fto.html)
#         rm $SSH_AUTH_SOCK
#     fi
#     ssh-add -l 2>/dev/null >/dev/null
#     if [ $? -ge 2 ]; then
#         ssh-agent -a "$SSH_AUTH_SOCK" >/dev/null
#         ssh-add
#     fi
# fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

eval "$(starship init zsh)"
source <(kubectl completion zsh)
source <(fzf --zsh)
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

if command -v try &> /dev/null; then
  eval "$(try init ~/Work/tries)"
fi

# 1Password
eval "$(op completion zsh)"; compdef _op op
# sign in to 1Password account if not already signed in
if ! op account list &> /dev/null; then
  eval "$(op signin)"
fi

# n version manager
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.local/n/bin:$PATH"
export N_PREFIX="$HOME/.local/n"

export GTK_THEME=Adwaita:dark

# custom scripts
export PATH="$HOME/scripts:$PATH"

export PATH=$HOME/.nimble/bin:$PATH

export NOTES="$HOME/.notes"
export TASKS="$HOME/.tasks"
export DOTFILES="$HOME/.dotfiles"
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/.ripgreprc"

export LD_LIBRARY_PATH=/usr/local/cuda-12.8/lib64:$LD_LIBRARY_PATH
export PATH=/usr/local/cuda-12.8/bin:$PATH
export CUDA_HOME=/usr/local/cuda-12.8

export PATH="$HOME/.dotnet:$PATH"
export DOTNET_ROOT="$(dirname $(which dotnet))"

export BAT_THEME=ansi

# To get the IDs, run: op item list and look for the IDs in the first column
# export OPENAI_API_KEY=$(op read 'op://personal/fmttrscnldn4rbsgrhvgj6qnae/password')
# export ANTHROPIC_API_KEY=$(op read 'op://personal/5vsjugsw43b5l5r4ybtxo2l5nm')
# export GEMINI_API_KEY=$(op read 'op://personal/l63esue26zwv22e75cgnazid2m/password')

# Dotnet tools
export PATH="$PATH:~/.dotnet/tools"
# Dotnet tools end

eval "$(zoxide init --cmd cd zsh)"

bindkey -s ^s "tmux-sessionizer.sh\n"
bindkey -s ^f "tmux-windowizer.sh\n"
bindkey -s ^w "tmux-windowizer.sh\n"

eval "$(uv generate-shell-completion zsh)"

# For QEMU/KVM libvirt
export LIBVIRT_DEFAULT_URI='qemu:///system'

# Auto-attach tmux on interactive login, but not over SSH or if already in tmux
if [[ -z $SSH_CONNECTION && -z $TMUX ]]; then
  tmux attach || tmux new -s Work
fi
