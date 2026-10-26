#!/bin/sh

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

install-hb() {
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install-omzsh() {
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install-deps() {
	brew tap ankitpokhrel/jira-cli 
	brew tap johanhaleby/kubetail
	brew tap safetyculture/tap
	brew install --cask macfuse	session-manager-plugin sublime-text	wombat
	brew install awscli colima delve docker docker-buildx docker-compose ffmpeg fzf gh gifsicle git-delta glow go jira-cli jq mkcert nvm pwgen python@3.11 scli staticcheck zsh-autosuggestions zsh-syntax-highlighting
}

set-kubeconf() {
	aws eks update-kubeconfig --name "eks01-ap-southeast-2-development-sc001" --alias "eks01-ap-southeast-2-development-sc001" --profile "sc-development" --region "ap-southeast-2"
}