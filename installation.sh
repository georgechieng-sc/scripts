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
	brew tap datawire/blackbird 
	brew tap gromgit/fuse 
	brew tap johanhaleby/kubetail 
	brew tap safetyculture/tap
	brew tap kardolus/chatgpt-cli
	brew install --cask macfuse	session-manager-plugin sublime-text	wombat
	brew install awscli cairo chatgpt-cli clang-format expect ffmpeg fzf fzy gh giflib gifsicle git-delta go imagemagick jira-cli jpeg jq kcat libpng md5sha1sum mkcert mockery nvm pango pkg-config pwgen python@3.11 scli staticcheck terraform vips zsh-autosuggestions zsh-syntax-highlighting
}

set-kubeconf() {
	aws eks update-kubeconfig --name "eks01-ap-southeast-2-development" --alias "eks01-ap-southeast-2-development" --profile "sc-development" --region "ap-southeast-2"
}

# =============================================================================
# NODE VERSION MANAGER FUNCTIONS
# =============================================================================

load-nvm() {
	export NVM_DIR="$HOME/.nvm"
	[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
}

nvm() {
	unset -f nvm
	load-nvm
	nvm "$@"
}

yarn() {
	unset -f yarn
	load-nvm
	yarn "$@"
}

npm() {
	unset -f npm
	load-nvm
	npm "$@"
}
