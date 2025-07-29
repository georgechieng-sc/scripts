#!/bin/sh

# =============================================================================
# ALIASES - GENERAL
# =============================================================================

alias reload="exec zsh"
alias hammer="reload && reset"
alias pf="subl ~/.zshrc"
alias gconf="subl ~/.gitconfig"
alias hostfile="subl /etc/hosts"
alias mysh="code -n ~/Desktop/safetyculture/scripts"

alias ll="ls -la"
alias dk="cd ~/Desktop"
alias sc="cd ~/Desktop/safetyculture"
alias fr="nvmcurr && cd ~/Desktop/safetyculture/frontend-reactor"

alias nvmcurr='nvm use 22'
alias yb="fr && yarn b"
alias yt="DEBUG_PRINT_LIMIT=100000 yarn test"

alias lernaup="yarn global upgrade lerna"
alias npmup="npm --global upgrade"

alias gga="go get -u ./..."
alias gmt="go mod tidy"
alias stc="staticcheck ./..."

alias show="defaults write com.apple.Finder AppleShowAllFiles true && killall Finder"
alias hide="defaults write com.apple.Finder AppleShowAllFiles false && killall Finder"

alias sc-ns="echo $GETNAMESPACE"
alias sc-auth="aws sso login --profile sc-development"
alias sc-change="kubectl config set-context --current --namespace "
alias tp="scli dev intercept "
alias tidepods="kubectl get pods"

alias brewdep="brew deps --tree --installed"
alias portcheck="lsof -i"
alias hack="code -n ."
alias cleanslate="_ sudo rm -rf /private/var/log/asl/*.asl"

# =============================================================================
# ALIASES - DOCKER
# =============================================================================

alias docking="open -a Docker"
alias dkc='docker ps -a -q'
alias dki='docker image list -q'
alias breakmirror='docker rmi $(dki)'
alias sinkship='docker rm $(dkc)'

# =============================================================================
# ALIASES - GIT
# =============================================================================

alias gpod='git push origin --delete'
alias gplink='git push --set-upstream origin $(git_current_branch)'
alias gblink='git branch --set-upstream-to=origin/$(git_current_branch)'
alias gmm='gm $(git_main_branch)'
alias gfm='git fetch origin $(git_main_branch):$(git_main_branch)'
alias gpe='git commit --allow-empty --allow-empty-message && git push'
alias gbi='git checkout $(git branch | fzf | xargs)'
alias gver='git checkout --theirs -- VERSION.txt'
