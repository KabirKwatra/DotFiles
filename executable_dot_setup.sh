#!/bin/sh

# OS Detection
OS=$(uname)

FISH_RPM_URL="https://download.opensuse.org/repositories/shells:fish:release:3/openSUSE_Leap_15.2/shells:fish:release:3.repo"

# If linux distro is not detected or darwin
brew_install() {
    echo "Installing Brew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    
    brew install chezmoi fish starship tmux neovim starship 
}

starship_install() {
    echo "Installing Starship"
    curl -fsSL https://starship.rs/install.sh | bash -s -- -y
}

chezmoi_install() {
    mkdir -p $HOME/.config
    cd $HOME/.config
    curl -sfL https://git.io/chezmoi | sh
    PATH="$(pwd)/bin:$PATH"; export PATH
    cd $HOME
}

if [ "$OS" = "Linux" ]
then
    echo "Linux Detected"

    # Distro Detection
    . /etc/os-release
    ID=${ID_LIKE:-$ID}

    echo "ID: $ID"
    case "$ID" in
        *debian*)
            echo "Debian Distro detected"
            sudo apt-get update
            sudo apt-get install -y curl
            sudo apt-get install -y fish tmux ripgrep fd-find git
            if [ "$CODESPACES" = true ]
            then
                echo "Codespaces detected"
                # Emacs not required for Codespaces
            else
                sudo apt-get install -y emacs
            fi
            chezmoi_install
            starship_install
            ;;
        fedora)
            echo "RPM Distro Detected"
            sudo yum install -y curl
            curl --silent --location "$FISH_RPM_URL" | \
                sudo tee /etc/yum.repos.d/fish.repo
            sudo yum install -y fish tmux bash emacs ripgrep fd-find git
            chezmoi_install
            starship_install
            ;;
        *suse*)
            echo "SUSE Distro Detected"
            sudo zypper addrepo "$FISH_RPM_URL"
            sudo zyppper refresh
            sudo zypper install fish tmux bash emacs ripgrep fd git
            chezmoi_install
            starship_install
            ;;
        arch)
            echo "Arch Distro Detected"
            sudo pacman -Syu --noconfirm chezmoi fish tmux emacs ripgrep fd git
            starship_install
            ;;
        alpine)
            echo "Alpine Distro Detected"
            sudo apk update
            sudo apk add --no-cache chezmoi fish tmux emacs ripgrep fd git curl bash
            starship_install
            ;;
        *)
            echo "Distro Not Detected (/bin/bash is required)"
            brew_install
            
    esac
elif [ "$OS" = "Darwin" ]
then
    brew_install
else
    echo "$OS Not Supported"
    exit
fi

if [ "$CI" = "True" ]
then
    chezmoi apply
else
    chezmoi init https://dotfiles.kwatra.me/git
    chezmoi apply
fi

if [ "$CODESPACES" = true ]
then
    echo "Skipping Doom Emacs Installation"
else
    echo "Installing Doom Emacs"
    git clone --depth 1 https://github.com/hlissner/doom-emacs ~/.emacs.d
    $HOME/.emacs.d/bin/doom --yes install
    $HOME/.emacs.d/bin/doom --yes sync
fi

echo "Change Shell to Fish Manually"
