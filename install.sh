#!/bin/bash

# Script de instalação para configuração do Hyprland
# Detecta automaticamente o sistema operacional e instala as dependências

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de utilidade
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detectar o sistema operacional
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        OS_ID=$ID
        VERSION=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    elif [ -f /etc/redhat-release ]; then
        OS="Red Hat Enterprise Linux"
    else
        OS=$(uname -s)
    fi
}

# Verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Instalação para Arch Linux
install_arch() {
    print_info "Detectado sistema Arch Linux"
    
    # Atualizar sistema
    print_info "Atualizando sistema..."
    sudo pacman -Syu --noconfirm
    
    # Instalar dependências principais
    print_info "Instalando dependências principais..."
    sudo pacman -S --needed --noconfirm \
        hyprland \
        hyprpaper \
        waybar \
        kitty \
        thunar \
        rofi \
        pavucontrol \
        playerctl \
        brightnessctl \
        wireplumber \
        pipewire \
        pipewire-pulse \
        pipewire-jack \
        font-awesome \
        ttf-font-awesome \
        noto-fonts \
        noto-fonts-emoji \
        ttf-dejavu \
        grim \
        slurp \
        wl-clipboard \
        xdg-desktop-portal-hyprland
    
    # Instalar AUR helper se não existir
    if ! command_exists yay && ! command_exists paru; then
        print_info "Instalando yay (AUR helper)..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
    fi
    
    # Usar yay ou paru para pacotes AUR
    AUR_HELPER=""
    if command_exists yay; then
        AUR_HELPER="yay"
    elif command_exists paru; then
        AUR_HELPER="paru"
    fi
    
    if [ -n "$AUR_HELPER" ]; then
        print_info "Instalando pacotes do AUR..."
        $AUR_HELPER -S --noconfirm \
            brave-bin \
            discord \
            spotify \
            steam \
            visual-studio-code-bin
    else
        print_warning "Nenhum AUR helper encontrado. Instale manualmente: brave, discord, spotify, steam, vscode"
    fi
}

# Instalação para Ubuntu/Debian
install_ubuntu() {
    print_info "Detectado sistema Ubuntu/Debian"
    
    # Atualizar sistema
    print_info "Atualizando sistema..."
    sudo apt update && sudo apt upgrade -y
    
    # Instalar dependências básicas
    print_info "Instalando dependências básicas..."
    sudo apt install -y \
        wget \
        curl \
        git \
        build-essential \
        cmake \
        ninja-build \
        pkg-config \
        libwayland-dev \
        libxkbcommon-dev \
        wayland-protocols \
        libinput-dev \
        libxcb1-dev \
        libxcb-composite0-dev \
        libxcb-icccm4-dev \
        libxcb-image0-dev \
        libxcb-keysyms1-dev \
        libxcb-randr0-dev \
        libxcb-render-util0-dev \
        libxcb-shape0-dev \
        libxcb-util-dev \
        libxcb-xfixes0-dev \
        libxcb-xinerama0-dev \
        libxcb-xkb-dev \
        libxcb-xrm-dev \
        kitty \
        thunar \
        rofi \
        pavucontrol \
        playerctl \
        pipewire \
        wireplumber \
        pipewire-pulse \
        fonts-font-awesome \
        fonts-noto \
        fonts-noto-color-emoji \
        grim \
        slurp \
        wl-clipboard
    
    # Verificar se já tem versão do Ubuntu que suporta Hyprland nos repos
    UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "20.04")
    UBUNTU_MAJOR=$(echo $UBUNTU_VERSION | cut -d. -f1)
    
    if [ "$UBUNTU_MAJOR" -ge 23 ]; then
        print_info "Tentando instalar Hyprland e Waybar dos repositórios..."
        sudo apt install -y hyprland waybar || {
            print_warning "Falha ao instalar dos repositórios, compilando do código fonte..."
            compile_hyprland_waybar
        }
    else
        print_info "Ubuntu $UBUNTU_VERSION detectado, compilando Hyprland e Waybar do código fonte..."
        compile_hyprland_waybar
    fi
    
    # Instalar aplicações
    install_apps_ubuntu
}

# Compilar Hyprland e Waybar do código fonte
compile_hyprland_waybar() {
    print_info "Compilando Hyprland..."
    
    # Instalar dependências de compilação
    sudo apt install -y \
        meson \
        libwayland-dev \
        libxkbcommon-dev \
        libegl1-mesa-dev \
        libgles2-mesa-dev \
        libdrm-dev \
        libxcb-dri3-dev \
        libxcb-present-dev \
        libxcb-composite0-dev \
        libxcb-ewmh-dev \
        libxcb-res0-dev \
        libxcb-xinput-dev \
        libpixman-1-dev \
        libudev-dev \
        libseat-dev \
        libinput-dev \
        libxcb-icccm4-dev \
        libtomlplusplus-dev \
        libzip-dev \
        librsvg2-dev \
        libgtk-3-dev \
        libgtkmm-3.0-dev \
        libpulse-dev \
        libnl-3-dev \
        libnl-genl-3-dev \
        libappindicator3-dev \
        libjsoncpp-dev \
        libfmt-dev \
        libspdlog-dev
    
    # Hyprland
    if ! command_exists Hyprland; then
        cd /tmp
        git clone --recursive https://github.com/hyprwm/Hyprland.git
        cd Hyprland
        make all
        sudo make install
        cd /
    fi
    
    # Waybar
    if ! command_exists waybar; then
        cd /tmp
        git clone https://github.com/Alexays/Waybar.git
        cd Waybar
        meson build
        ninja -C build
        sudo ninja -C build install
        cd /
    fi
    
    # Hyprpaper
    if ! command_exists hyprpaper; then
        cd /tmp
        git clone https://github.com/hyprwm/hyprpaper.git
        cd hyprpaper
        make all
        sudo make install
        cd /
    fi
}

# Instalar aplicações no Ubuntu
install_apps_ubuntu() {
    print_info "Instalando aplicações..."
    
    # Brave Browser
    if ! command_exists brave-browser; then
        print_info "Instalando Brave Browser..."
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        sudo apt update
        sudo apt install -y brave-browser
    fi
    
    # Discord
    if ! command_exists discord; then
        print_info "Instalando Discord..."
        wget -O /tmp/discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
        sudo dpkg -i /tmp/discord.deb
        sudo apt-get install -f -y
    fi
    
    # Spotify
    if ! command_exists spotify; then
        print_info "Instalando Spotify..."
        curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
        echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
        sudo apt update
        sudo apt install -y spotify-client
    fi
    
    # Steam
    if ! command_exists steam; then
        print_info "Instalando Steam..."
        sudo apt install -y steam
    fi
    
    # Visual Studio Code
    if ! command_exists code; then
        print_info "Instalando Visual Studio Code..."
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        sudo apt update
        sudo apt install -y code
    fi
}

# Instalação para Fedora
install_fedora() {
    print_info "Detectado sistema Fedora"
    
    # Atualizar sistema
    print_info "Atualizando sistema..."
    sudo dnf update -y
    
    # Habilitar RPM Fusion
    sudo dnf install -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    
    # Instalar dependências principais
    print_info "Instalando dependências principais..."
    sudo dnf install -y \
        hyprland \
        waybar \
        kitty \
        thunar \
        rofi \
        pavucontrol \
        playerctl \
        brightnessctl \
        pipewire \
        wireplumber \
        pipewire-pulseaudio \
        pipewire-jack-audio-connection-kit \
        fontawesome-fonts \
        google-noto-fonts \
        google-noto-emoji-fonts \
        grim \
        slurp \
        wl-clipboard \
        xdg-desktop-portal-hyprland
    
    # Instalar aplicações
    print_info "Instalando aplicações..."
    
    # Brave Browser
    if ! command_exists brave-browser; then
        print_info "Instalando Brave Browser..."
        sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
        sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
        sudo dnf install -y brave-browser
    fi
    
    # Discord
    if ! command_exists discord; then
        print_info "Instalando Discord..."
        wget -O /tmp/discord.rpm "https://discord.com/api/download?platform=linux&format=rpm"
        sudo dnf install -y /tmp/discord.rpm
    fi
    
    # Spotify
    if ! command_exists spotify; then
        print_info "Instalando Spotify..."
        sudo dnf config-manager --add-repo https://negativo17.org/repos/fedora-spotify.repo
        sudo dnf install -y spotify-client
    fi
    
    # Steam
    sudo dnf install -y steam
    
    # Visual Studio Code
    if ! command_exists code; then
        print_info "Instalando Visual Studio Code..."
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        sudo dnf install -y code
    fi
    
    # Hyprpaper (pode não estar nos repos, compilar se necessário)
    if ! command_exists hyprpaper; then
        print_info "Compilando hyprpaper..."
        sudo dnf groupinstall -y "Development Tools"
        sudo dnf install -y cmake meson ninja-build wayland-devel cairo-devel pango-devel
        cd /tmp
        git clone https://github.com/hyprwm/hyprpaper.git
        cd hyprpaper
        make all
        sudo make install
        cd /
    fi
}

# Instalar para outros sistemas
install_other() {
    print_error "Sistema operacional não suportado automaticamente: $OS"
    print_info "Por favor, instale manualmente as seguintes dependências:"
    echo ""
    echo "Dependências principais:"
    echo "  - hyprland"
    echo "  - hyprpaper"  
    echo "  - waybar"
    echo "  - kitty"
    echo "  - thunar"
    echo "  - rofi"
    echo "  - pavucontrol"
    echo "  - playerctl"
    echo "  - brightnessctl"
    echo "  - pipewire + wireplumber"
    echo "  - grim + slurp"
    echo "  - wl-clipboard"
    echo "  - xdg-desktop-portal-hyprland"
    echo ""
    echo "Aplicações:"
    echo "  - brave-browser"
    echo "  - discord"
    echo "  - spotify"
    echo "  - steam"
    echo "  - visual-studio-code"
    echo ""
    echo "Fontes:"
    echo "  - font-awesome"
    echo "  - noto-fonts"
    echo "  - noto-emoji"
    exit 1
}

# Configurar arquivos de configuração
setup_configs() {
    print_info "Configurando arquivos de configuração..."
    
    # Criar diretórios necessários
    mkdir -p ~/.config/hypr
    mkdir -p ~/.config/waybar
    
    # Copiar configurações se não existirem
    if [ ! -f ~/.config/hypr/hyprland.conf ]; then
        print_info "Copiando configuração do Hyprland..."
        cp hyprland/hyprland.conf ~/.config/hypr/
        cp hyprland/hyprpaper.conf ~/.config/hypr/
        
        # Copiar wallpapers se existirem
        if [ -d "hyprland/wallpapers" ]; then
            cp -r hyprland/wallpapers ~/.config/hypr/
        fi
    fi
    
    if [ ! -f ~/.config/waybar/config-top.jsonc ]; then
        print_info "Copiando configurações do Waybar..."
        cp waybar/* ~/.config/waybar/
    fi
    
    print_success "Configurações copiadas para ~/.config/"
}

# Função principal
main() {
    print_info "=== Script de Instalação - Configuração Hyprland ==="
    print_info "Este script irá detectar seu sistema e instalar todas as dependências necessárias"
    echo ""
    
    # Detectar sistema operacional
    detect_os
    print_info "Sistema detectado: $OS"
    
    case "$OS_ID" in
        "arch"|"manjaro"|"endeavouros"|"garuda")
            install_arch
            ;;
        "ubuntu"|"debian"|"linuxmint"|"pop"|"elementary")
            install_ubuntu
            ;;
        "fedora"|"centos"|"rhel"|"rocky"|"alma")
            install_fedora
            ;;
        *)
            install_other
            ;;
    esac
    
    # Configurar arquivos
    setup_configs
    
    print_success "=== Instalação concluída! ==="
    print_info "Para aplicar as configurações:"
    print_info "1. Faça logout do seu desktop atual"
    print_info "2. Selecione 'Hyprland' na tela de login"
    print_info "3. Faça login normalmente"
    echo ""
    print_warning "Nota: Algumas aplicações podem precisar ser configuradas manualmente"
    print_warning "Verifique os caminhos no arquivo de configuração se alguma aplicação não funcionar"
}

# Verificar se está sendo executado no diretório correto
if [ ! -f "hyprland/hyprland.conf" ] || [ ! -f "waybar/config-top.jsonc" ]; then
    print_error "Execute este script no diretório raiz do projeto (onde estão as pastas hyprland/ e waybar/)"
    exit 1
fi

# Executar função principal
main "$@"
