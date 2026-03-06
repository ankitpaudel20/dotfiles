

# History — immediate + shared across ALL sessions (this is what you asked for)
HISTFILE=$HOME/.histfile
HISTSIZE=1000000
SAVEHIST=1000000000

setopt extendedhistory
setopt appendhistory
setopt SHARE_HISTORY          # ← THIS makes history instant + visible in every terminal
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

setopt autocd extendedglob

# this is autocomplete for zsh
autoload -Uz compinit
compinit

#
# Ctrl + V will show key codes zsh receives
# key bindings fixes
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey  "^[[3~"  delete-char
# this requires kitty config to send this char for ctrl backspace `map ctrl+backspace send_text all "\e[127;5u"`
bindkey "\e[127;5u" backward-kill-word

#set default editor
export VISUAL=nvim
export EDITOR=nvim
export SUDO_EDITOR=/usr/bin/vim

# For ssh-agent to work
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/fzf/completion.zsh
source /usr/share/fzf/key-bindings.zsh


generate_python_index_url () {
        gcloud auth login
        access_token=$(gcloud auth print-access-token)
        python_index_url="https://oauth2accesstoken:$access_token@us-python.pkg.dev/cloud-run-testing-272918/packages/simple/"
        export PYTHON_INDEX_URL="$python_index_url"
}

#sane aliases
alias svim="sudo vim"
alias tam='tmux attach -t main || tmux new -s main'
alias la='eza -a --icons=always'
alias ll='eza -al --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'



#
#add gcloud to path
export PATH="/opt/google-cloud-cli/bin:$PATH"
source <(kubectl completion zsh)

#This is required for krew
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

#Start starship
eval "$(starship init zsh)"

# for direnv to work
eval "$(direnv hook zsh)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/smloy/google-cloud-sdk/path.zsh.inc' ]; then . '/home/smloy/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/smloy/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/smloy/google-cloud-sdk/completion.zsh.inc'; fi
