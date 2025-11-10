# TODO remove
# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# # Initialization code that may require console input (password prompts, [y/n]
# # confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# TODO remove
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
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
plugins=(
  # aws
  # colorize
  # dotenv
  # git
  # helm
  # history
  # kubectl
  # kubectx
  # macos
  # npm
  # nvm
  # zsh-syntax-highlighting
)

# Homebrew home path
[ -s "/home/linuxbrew/.linuxbrew/bin/brew" ] && export BREW_HOME="/home/linuxbrew/.linuxbrew" # linux
[ -s "/opt/homebrew/bin/brew" ] && export BREW_HOME="/opt/homebrew" # mac

# Enable autocompletions of homebrew
[ -s "$BREW_HOME/share/zsh/site-functions" ] \
&& export FPATH="$BREW_HOME/share/zsh/site-functions:${FPATH}"

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi
export EDITOR="cursor --wait"

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

#  android studio / jvm / expo
[ -s "/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home" ] \
&& export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

[ -s "$HOME/Library/Android/sdk" ] \
&& export ANDROID_HOME="$HOME/Library/Android/sdk" \
&& export PATH=$PATH:$ANDROID_HOME/emulator \
&& export PATH=$PATH:$ANDROID_HOME/platform-tools

# asdf
[ -s "$BREW_HOME" ] \
&& [ -s "$BREW_HOME/opt/asdf/libexec/asdf.sh" ] \
&& source "$BREW_HOME/opt/asdf/libexec/asdf.sh"

# aws
[ -s "$BREW_HOME/bin/aws_completer" ] \
&& autoload bashcompinit \
&& bashcompinit \
&& autoload -Uz compinit \
&& compinit \
&& complete -C "$BREW_HOME/bin/aws_completer" aws

# brew
if command -v brew >/dev/null 2>&1; then
  alias brew="brew list --installed-on-request > $HOME/.brew-list && brew"
fi

# clear
alias cls="clear"

# cd
alias cd..="cd .."

# code/cursor
[ -s "/Applications/Cursor.app" ] \
&& export PATH="$PATH:/Applications/Cursor.app/Contents/Resources/app/bin"
if command -v cursor >/dev/null 2>&1; then
  alias code="cursor"
fi

# git
if command -v git >/dev/null 2>&1; then
  alias gc="git checkout"
  alias gcb="git checkout -b"
  alias gcm="git commit -m"
  alias gd="git diff"
  alias gds="git diff --staged" # equivalent to git diff --cached
  alias gdc="git diff --cached" # equivalent to git diff --staged
  alias gst="git status"
  alias gsw="git switch"
  alias gswc="git switch -c"
  alias "git push -f"="echo "Aliased to git push --force-with-lease" && git push --force-with-lease"
  alias "git pull"="echo "Aliased to git pull --rebase" && git pull --rebase"
fi

# go
[ -d "$HOME/go" ] \
&& export GOPATH=$HOME/go \
&& export PATH=$GOPATH/bin:$PATH

# granted / assume
if command -v assume >/dev/null 2>&1; then
  alias assume=". assume"
fi

# homebrew
[ -s "$BREW_HOME/bin/brew" ] \
&& eval "$($BREW_HOME/bin/brew shellenv)"

# flux
if command -v flux >/dev/null 2>&1; then
  . <(flux completion zsh)
  alias f="flux"
  # alias fg="flux get" # `fg` is an existing command for putting a background job in the foreground
  # alias fga="flux get -A" # This could be confusing, as `fg` is already not allowed
fi

# kubectl
if command -v kubectl >/dev/null 2>&1; then
  alias k="kubectl"
  alias kg="kubectl get"
  alias kga="kubectl get -A"
  alias kgar="kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found"

  # kubectl apply
  alias kaf="kubectl apply -f"
  alias kak="kubectl apply -k"

  # kubectl delete
  alias kdelf="kubectl delete -f"
  alias kdelk="kubectl delete -k"
fi

# kubectx
if command -v kubectx >/dev/null 2>&1; then
  alias kctx="kubectx"
fi

# kubens
if command -v kubens >/dev/null 2>&1; then
  alias kns="kubens"
fi

# enable iterm2 shell integration
[ -s "$HOME/.iterm2_shell_integration.zsh" ] \
&& source "$HOME/.iterm2_shell_integration.zsh"

# mysql-client
[ -d "/usr/local/opt/mysql-client/bin" ] \
&& export PATH="$PATH:/usr/local/opt/mysql-client/bin"

[ -d "$BREW_HOME/opt/mysql-client/bin" ] \
&& export PATH="$PATH:$BREW_HOME/opt/mysql-client/bin"

# nvm with nvmrc
[ -d "$HOME/.nvm" ] \
&& export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] \
&& \. "$NVM_DIR/nvm.sh"  # This loads nvm without brew

[ -s "$BREW_HOME" ] \
&& [ -s "$BREW_HOME/opt/nvm/nvm.sh" ] \
&& \. "$BREW_HOME/opt/nvm/nvm.sh"  # This loads nvm with brew

# nvm / nvmrc
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"
  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# TODO remove
# powerlevel10k
# [ -s "$HOME/.p10k.zsh" ] \
# && source $HOME/.p10k.zsh

# rancher desktop
[ -s "$HOME/.rd/bin" ] \
&& export PATH="$PATH:$HOME/.rd/bin"

# rust
[ -s "$HOME/.cargo/env" ] \
&& source "$HOME/.cargo/env"
[ -d "$HOME/.cargo/bin" ] \
&& export PATH="$PATH:$HOME/.cargo/bin"

# ruby (for some pre-commit hooks)
[ -s "$BREW_HOME" ] \
&& [ -s "$BREW_HOME/opt/ruby/bin" ] \
&& export PATH="$BREW_HOME/opt/ruby/bin:$PATH"

search-file() {
  # If no arguments provided, show help
  if [ $# -eq 0 ]; then
    echo "Usage: search-file <searchstring> [path]"
    echo "  searchstring: The string to search for in filenames"
    echo "  path: Optional path to search in (defaults to current directory)"
    return 0
  fi

  # Set default path to current directory if not provided
  local search_string="$1"
  local search_path="${2:-.}"
  local absolute_search_path=$(cd "$search_path" && pwd)

  # Check if fd is installed and use it, otherwise fall back to find
  if command -v fd >/dev/null 2>&1; then
    if [[ "$absolute_search_path" == "$HOME" ]]; then
      command fd -HI "$search_string" "$search_path" --exclude '/Library/' ${@:3}
    else
      command fd -HI "$search_string" "$search_path" ${@:3}
    fi
  else
    if [[ "$absolute_search_path" == "$HOME" ]]; then
      command find "$search_path" -path "$search_path/Library" -prune -o -iname "*$search_string*" -print ${@:3}
    else
      command find "$search_path" -iname "*$search_string*" -print ${@:3}
    fi
  fi
}

search-in-file() {
  # If no arguments provided, show help
  if [ $# -eq 0 ]; then
    echo "Usage: search-in-file <searchstring> [path] [--ext <extension>] [args...]"
    echo "  searchstring: The string to search for"
    echo "  path: Optional path to search in (defaults to current directory)"
    echo "  --ext: Optional file extension filter (e.g., --ext js)"
    echo "  args: Additional arguments passed to rg/grep"
    return 0
  fi

  local search_string="$1"
  local search_path="."
  local file_extension=""
  local remaining_args=()

  # If $2 exists and doesn't start with --, it's the path
  if [ $# -ge 2 ] && [[ "$2" != "--"* ]]; then
    search_path="$2"
    local start_idx=3
  else
    local start_idx=2
  fi

  # Look for --ext flag in remaining arguments
  local i=$start_idx
  while [ $i -le $# ]; do
    if [[ "${@[$i]}" == "--ext" ]] && [ $i -lt $# ]; then
      # Found --ext, get the next argument as extension
      ((i++))
      file_extension="${@[$i]}"
      file_extension="${file_extension#.}"  # Remove leading dot if present
    else
      # Keep other arguments
      remaining_args+=("${@[$i]}")
    fi
    ((i++))
  done

  local absolute_search_path=$(cd "$search_path" && pwd)

  # Check if ripgrep (rg) is installed and use it, otherwise fall back to grep
  if command -v rg >/dev/null 2>&1; then
    # Use ripgrep with case-insensitive search
    local rg_args=(-i --hidden --no-ignore)
    if [[ -n "$file_extension" ]]; then
      rg_args+=(-g "*.${file_extension}")
    fi
    # Exclude Library directory when searching from home
    if [[ "$absolute_search_path" == "$HOME" ]]; then
      rg_args+=(-g "!Library/**")
    fi
    command rg "${rg_args[@]}" "$search_string" "$search_path" "${remaining_args[@]}"
  else
    # Fall back to grep with case-insensitive search
    local grep_args=(-ril --binary-files=without-match)
    if [[ -n "$file_extension" ]]; then
      grep_args+=(--include="*.${file_extension}")
    fi
    # Exclude Library directory when searching from home
    if [[ "$absolute_search_path" == "$HOME" ]]; then
      grep_args+=(--exclude-dir=Library)
    fi
    command grep "${grep_args[@]}" "${remaining_args[@]}" "$search_path" "$search_string"
  fi
}

copy() {
  command rsync -aP --append-verify "$@"
}

# sops wrapper function
sops() {
  local age_keys_file="$HOME/.config/sops/age/keys.txt"

  if [[ ! -f "$age_keys_file" ]]; then
    echo "⚠️  Warning: Age keys file not found at $age_keys_file"
    echo "   Please ensure your SOPS age keys are properly configured before using sops."
    return 1
  fi

  # Call the actual sops command with all arguments
  command sops "$@"
}

# task (taskfile.dev)
[ -s "$BREW_HOME/bin/task" ] \
&& eval "$(task --completion zsh)"

# opentofu / terraform
if command -v terraform >/dev/null 2>&1; then
  alias tf="terraform"
  alias tfa="terraform apply"
  alias tfp="terraform plan"
  alias tfi="terraform init"
  alias tfd="terraform destroy"
  alias tff="terraform fmt"
  alias tft="terraform validate"
fi

# ---
# This should only run on mac:

# download zsh-syntax-highlighting plugin
# [ -s "$HOME/.oh-my-zsh" ] && ( [ -s "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ] || git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting)

# ensure nerdfonts are installed
# [ -s "$BREW_HOME" ] && [ -s "$BREW_HOME/Caskroom/font-meslo-lg-nerd-font" ] || brew install --cask font-meslo-lg-nerd-font

# TODO remove
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# TODO enable
eval "$(starship init zsh)"
