# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

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
    aws
    colorize
    dotenv
    git
    helm
    history
    kubectl
    kubectx
    macos
    npm
    nvm
    zsh-syntax-highlighting
)

# Homebrew home path
[ -s "/home/linuxbrew/.linuxbrew/bin/brew" ] && export BREW_HOME="/home/linuxbrew/.linuxbrew" # linux
[ -s "/opt/homebrew/bin/brew" ] && export BREW_HOME="/opt/homebrew" # mac


# Enable autocompletions of homebrew
[ -s "$BREW_HOME" ] \
&& [ -s "$BREW_HOME" ] \
&& export FPATH="$BREW_HOMEshare/zsh/site-functions:${FPATH}"

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi
export EDITOR="code --wait"

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

# clear
alias cls="clear"

# cd
alias cd..="cd .."

# code/cursor
[ -s "/Applications/Cursor.app" ] \
&& export PATH="$PATH:/Applications/Cursor.app/Contents/Resources/app/bin"

# git
if type "git" > /dev/null; then
  alias gc="git checkout"
  alias gcb="git checkout -b"
  alias gcm="git commit -m"
  alias gd="git diff"
  alias gds="git diff --staged" # equivalent to git diff --cached
  alias gdc="git diff --cached" # equivalent to git diff --staged
  alias gst="git status"
  alias gsw="git switch"
  alias gswc="git switch -c"
fi

# kubectl
alias k="kubectl"
alias kg="kubectl get"
alias kga="kubectl get -A"
alias kgar="kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found"

# kubectx
alias kctx="kubectx"

# kubens
alias kns="kubens"

# kubectl apply
alias kaf="kubectl apply -f"
alias kak="kubectl apply -k"

# kubectl delete
alias kdelf="kubectl delete -f"
alias kdelk="kubectl delete -k"

# flux
alias f="flux"
# alias fg="flux get" # `fg` is an existing command for putting a background job in the foreground
# alias fga="flux get -A" # This could be confusing, as `fg` is already not allowed

# go
[ -d "$HOME/go" ] \
&& export GOPATH=$HOME/go \
&& export PATH=$GOPATH/bin:$PATH

# granted / assume
alias assume=". assume"

# homebrew
[ -s "/home/linuxbrew/.linuxbrew/bin/brew" ] \
&& eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" # linux

[ -s "/opt/homebrew/bin/brew" ] \
&& eval "$(/opt/homebrew/bin/brew shellenv)" # mac

# kubectl
if type "kubectl" > /dev/null; then
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
if type "kubectx" > /dev/null; then
  alias kctx="kubectx"
fi

# kubens
if type "kubens" > /dev/null; then
  alias kns="kubens"
fi

# flux
if type "flux" > /dev/null; then
  . <(flux completion zsh)
  alias fg="flux get"
  alias fga="flux get -A"
fi

# enable iterm2 shell integration
[ -s "$HOME/.iterm2_shell_integration.zsh" ] \
&& source "$HOME/.iterm2_shell_integration.zsh"

# mysql-client
[ -d "/usr/local/opt/mysql-client/bin" ] \
&& export PATH="$PATH:/usr/local/opt/mysql-client/bin"

[ -d "/opt/homebrew/opt/mysql-client/bin" ] \
&& export PATH="$PATH:/opt/homebrew/opt/mysql-client/bin"

# nvm with nvmrc
[ -d "$HOME/.nvm" ] \
&& export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] \
&& \. "$NVM_DIR/nvm.sh"  # This loads nvm without brew

[ -s "$BREW_HOME" ] \
&& [ -s "$BREW_HOME/opt/nvm/nvm.sh" ] \
&& \. "$BREW_HOME/opt/nvm/nvm.sh"  # This loads nvm with brew

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

# powerlevel10k
[ -s "$HOME/.p10k.zsh" ] \
&& source $HOME/.p10k.zsh

# rancher desktop
[ -s "$HOME/.rd/bin" ] \
&& export PATH="$PATH:$HOME/.rd/bin"

# rust
[ -s "$HOME/.cargo/env" ] \
&& source "$HOME/.cargo/env"

# ruby (for some pre-commit hooks)
[ -s "$BREW_HOME" ] \
&& [ -s "$BREW_HOME/opt/ruby/bin" ] \
&& export PATH="$BREW_HOME/opt/ruby/bin:$PATH"

# opentofu / terraform
if type "terraform" > /dev/null; then
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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
