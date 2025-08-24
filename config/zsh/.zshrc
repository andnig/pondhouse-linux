source ~/source/shell
source ~/.local/share/omarchy/default/bash/functions
source ~/source/custom-functions

if [[ -n "$KITTY_INSTALLATION_DIR" ]]; then
  export KITTY_SHELL_INTEGRATION="enabled"
  autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
  kitty-integration
  unfunction kitty-integration
fi


# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export FZF_BASE=$HOME/.fzf/bin/fzf

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_TMUX_AUTOSTART=true
ZSH_TMUX_AUTOQUIT=false

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(watson git dotenv dotnet zsh-autosuggestions zsh-syntax-highlighting ubuntu history-substring-search colored-man-pages colorize pip python kubectl zsh-vi-mode fzf-zsh-plugin tmux)
# fpath+=${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions/src
# source $ZSH/oh-my-zsh.sh

autoload -Uz compinit && compinit

# Manual plugin loading
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh
source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
source ~/.zsh/plugins/tmux/tmux.plugin.zsh
# source /usr/share/zsh/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh
# source ~/.zsh/plugins/fzf-zsh-plugin/fzf-zsh-plugin.plugin.zsh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
  export SUDO_EDITOR="$EDITOR"
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

alias jq="sed -E 's/[\x00-\x1F\x7F]//g' | tr -d '\000-\037' | jq"

alias ssh="TERM=screen ssh"
alias vim=nvim

alias fo=find_and_open.sh
alias on="cd $HOME/.notes && nvim ."
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
export SSH_AUTH_SOCK=~/.1password/agent.sock
# Alternative: If you don't want to use the 1Password SSH agent, you can use the following code to start a local ssh-agent and add your keys to ~/.ssh/.
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

# 1Password
eval "$(op completion zsh)"; compdef _op op
# sign in to 1Password account if not already signed in
if ! op account list &> /dev/null; then
  eval "$(op signin)"
fi

# n version manager
export PATH="$HOME/.local/.npm-global/bin:$PATH"
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

# export OPENAI_API_KEY=$(op read 'op://personal/fmttrscnldn4rbsgrhvgj6qnae/password')
# export ANTHROPIC_API_KEY=$(cat ~/.secrets/anthropic.secret)
# export GEMINI_API_KEY=$(op read 'op://personal/l63esue26zwv22e75cgnazid2m/password')

# Dotnet tools
export PATH="$PATH:~/.dotnet/tools"
# Dotnet tools end

eval "$(zoxide init --cmd cd zsh)"

bindkey -s ^s "tmux-sessionizer.sh\n"
bindkey -s ^f "tmux-windowizer.sh\n"
bindkey -s ^w "tmux-windowizer.sh\n"

eval "$(uv generate-shell-completion zsh)"
