# Makefile para configuração do Hyprland
# Detecta automaticamente o sistema operacional e instala as dependências

.PHONY: all install install-arch install-ubuntu install-fedora setup-configs clean help

# Detectar sistema operacional
OS_ID := $(shell grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
OS_NAME := $(shell grep -oP '(?<=^NAME=).+' /etc/os-release | tr -d '"')

# Diretórios
CONFIG_DIR := $(HOME)/.config
HYPR_DIR := $(CONFIG_DIR)/hypr
WAYBAR_DIR := $(CONFIG_DIR)/waybar

# Cores para output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m

define print_info
	@echo -e "$(BLUE)[INFO]$(NC) $(1)"
endef

define print_success
	@echo -e "$(GREEN)[SUCCESS]$(NC) $(1)"
endef

define print_warning
	@echo -e "$(YELLOW)[WARNING]$(NC) $(1)"
endef

define print_error
	@echo -e "$(RED)[ERROR]$(NC) $(1)"
endef

# Target principal
all: install setup-configs

# Detectar e instalar para o sistema correto
install:
	$(call print_info,"Detectado sistema: $(OS_NAME)")
	@case "$(OS_ID)" in \
		arch|manjaro|endeavouros|garuda) \
			$(MAKE) install-arch ;; \
		ubuntu|debian|linuxmint|pop|elementary) \
			$(MAKE) install-ubuntu ;; \
		fedora|centos|rhel|rocky|alma) \
			$(MAKE) install-fedora ;; \
		*) \
			$(call print_error,"Sistema não suportado: $(OS_NAME)") ; \
			$(MAKE) show-manual-install ; \
			exit 1 ;; \
	esac

# Instalação para Arch Linux
install-arch:
	$(call print_info,"Instalando dependências para Arch Linux...")
	sudo pacman -Syu --noconfirm
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
	@if ! command -v yay >/dev/null 2>&1 && ! command -v paru >/dev/null 2>&1; then \
		$(call print_info,"Instalando yay (AUR helper)...") ; \
		git clone https://aur.archlinux.org/yay.git /tmp/yay ; \
		cd /tmp/yay && makepkg -si --noconfirm ; \
	fi
	@if command -v yay >/dev/null 2>&1; then \
		yay -S --noconfirm brave-bin discord spotify steam visual-studio-code-bin ; \
	elif command -v paru >/dev/null 2>&1; then \
		paru -S --noconfirm brave-bin discord spotify steam visual-studio-code-bin ; \
	else \
		$(call print_warning,"AUR helper não encontrado. Instale manualmente: brave, discord, spotify, steam, vscode") ; \
	fi

# Instalação para Ubuntu/Debian
install-ubuntu:
	$(call print_info,"Instalando dependências para Ubuntu/Debian...")
	sudo apt update && sudo apt upgrade -y
	sudo apt install -y \
		wget curl git build-essential cmake ninja-build pkg-config \
		libwayland-dev libxkbcommon-dev wayland-protocols libinput-dev \
		kitty thunar rofi pavucontrol playerctl pipewire wireplumber \
		pipewire-pulse fonts-font-awesome fonts-noto fonts-noto-color-emoji \
		grim slurp wl-clipboard meson
	@UBUNTU_VERSION=$$(lsb_release -rs 2>/dev/null || echo "20.04"); \
	UBUNTU_MAJOR=$$(echo $$UBUNTU_VERSION | cut -d. -f1); \
	if [ "$$UBUNTU_MAJOR" -ge 23 ]; then \
		$(call print_info,"Tentando instalar Hyprland e Waybar dos repositórios...") ; \
		sudo apt install -y hyprland waybar || $(MAKE) compile-hyprland-waybar ; \
	else \
		$(call print_info,"Ubuntu $$UBUNTU_VERSION detectado, compilando do código fonte...") ; \
		$(MAKE) compile-hyprland-waybar ; \
	fi
	$(MAKE) install-apps-ubuntu

# Compilar Hyprland e Waybar do código fonte
compile-hyprland-waybar:
	$(call print_info,"Compilando Hyprland e Waybar do código fonte...")
	sudo apt install -y \
		meson libwayland-dev libxkbcommon-dev libegl1-mesa-dev \
		libgles2-mesa-dev libdrm-dev libtomlplusplus-dev libzip-dev \
		libgtkmm-3.0-dev libpulse-dev libnl-3-dev libnl-genl-3-dev \
		libappindicator3-dev libjsoncpp-dev libfmt-dev libspdlog-dev
	@if ! command -v Hyprland >/dev/null 2>&1; then \
		cd /tmp && git clone --recursive https://github.com/hyprwm/Hyprland.git && \
		cd Hyprland && make all && sudo make install ; \
	fi
	@if ! command -v waybar >/dev/null 2>&1; then \
		cd /tmp && git clone https://github.com/Alexays/Waybar.git && \
		cd Waybar && meson build && ninja -C build && sudo ninja -C build install ; \
	fi
	@if ! command -v hyprpaper >/dev/null 2>&1; then \
		cd /tmp && git clone https://github.com/hyprwm/hyprpaper.git && \
		cd hyprpaper && make all && sudo make install ; \
	fi

# Instalar aplicações no Ubuntu
install-apps-ubuntu:
	$(call print_info,"Instalando aplicações...")
	@if ! command -v brave-browser >/dev/null 2>&1; then \
		sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
			https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg ; \
		echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
			sudo tee /etc/apt/sources.list.d/brave-browser-release.list ; \
		sudo apt update && sudo apt install -y brave-browser ; \
	fi
	@if ! command -v discord >/dev/null 2>&1; then \
		wget -O /tmp/discord.deb "https://discordapp.com/api/download?platform=linux&format=deb" ; \
		sudo dpkg -i /tmp/discord.deb ; sudo apt-get install -f -y ; \
	fi
	@if ! command -v spotify >/dev/null 2>&1; then \
		curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | \
			sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg ; \
		echo "deb http://repository.spotify.com stable non-free" | \
			sudo tee /etc/apt/sources.list.d/spotify.list ; \
		sudo apt update && sudo apt install -y spotify-client ; \
	fi
	@sudo apt install -y steam || true
	@if ! command -v code >/dev/null 2>&1; then \
		wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg ; \
		sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/ ; \
		sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' ; \
		sudo apt update && sudo apt install -y code ; \
	fi

# Instalação para Fedora
install-fedora:
	$(call print_info,"Instalando dependências para Fedora...")
	sudo dnf update -y
	sudo dnf install -y \
		https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$$(rpm -E %fedora).noarch.rpm \
		https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$$(rpm -E %fedora).noarch.rpm || true
	sudo dnf install -y \
		hyprland waybar kitty thunar rofi pavucontrol playerctl \
		brightnessctl pipewire wireplumber pipewire-pulseaudio \
		pipewire-jack-audio-connection-kit fontawesome-fonts \
		google-noto-fonts google-noto-emoji-fonts grim slurp \
		wl-clipboard xdg-desktop-portal-hyprland
	$(MAKE) install-apps-fedora

# Instalar aplicações no Fedora
install-apps-fedora:
	@if ! command -v brave-browser >/dev/null 2>&1; then \
		sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo ; \
		sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc ; \
		sudo dnf install -y brave-browser ; \
	fi
	@if ! command -v discord >/dev/null 2>&1; then \
		wget -O /tmp/discord.rpm "https://discord.com/api/download?platform=linux&format=rpm" ; \
		sudo dnf install -y /tmp/discord.rpm ; \
	fi
	@sudo dnf install -y steam spotify-client || true
	@if ! command -v code >/dev/null 2>&1; then \
		sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc ; \
		sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' ; \
		sudo dnf install -y code ; \
	fi
	@if ! command -v hyprpaper >/dev/null 2>&1; then \
		sudo dnf groupinstall -y "Development Tools" ; \
		sudo dnf install -y cmake meson ninja-build wayland-devel cairo-devel pango-devel ; \
		cd /tmp && git clone https://github.com/hyprwm/hyprpaper.git && \
		cd hyprpaper && make all && sudo make install ; \
	fi

# Configurar arquivos de configuração
setup-configs:
	$(call print_info,"Configurando arquivos de configuração...")
	@mkdir -p $(HYPR_DIR) $(WAYBAR_DIR)
	@if [ ! -f $(HYPR_DIR)/hyprland.conf ]; then \
		cp hyprland/hyprland.conf $(HYPR_DIR)/ ; \
		cp hyprland/hyprpaper.conf $(HYPR_DIR)/ ; \
		if [ -d "hyprland/wallpapers" ]; then \
			cp -r hyprland/wallpapers $(HYPR_DIR)/ ; \
		fi ; \
		$(call print_success,"Configurações do Hyprland copiadas") ; \
	else \
		$(call print_warning,"Configurações do Hyprland já existem, pulando...") ; \
	fi
	@if [ ! -f $(WAYBAR_DIR)/config-top.jsonc ]; then \
		cp waybar/* $(WAYBAR_DIR)/ ; \
		$(call print_success,"Configurações do Waybar copiadas") ; \
	else \
		$(call print_warning,"Configurações do Waybar já existem, pulando...") ; \
	fi

# Mostrar instruções de instalação manual
show-manual-install:
	$(call print_error,"Sistema operacional não suportado automaticamente")
	@echo -e "\n$(BLUE)Dependências principais:$(NC)"
	@echo "  - hyprland, hyprpaper, waybar"
	@echo "  - kitty, thunar, rofi"
	@echo "  - pavucontrol, playerctl, brightnessctl"
	@echo "  - pipewire + wireplumber"
	@echo "  - grim + slurp + wl-clipboard"
	@echo "  - xdg-desktop-portal-hyprland"
	@echo -e "\n$(BLUE)Aplicações:$(NC)"
	@echo "  - brave-browser, discord, spotify"
	@echo "  - steam, visual-studio-code"
	@echo -e "\n$(BLUE)Fontes:$(NC)"
	@echo "  - font-awesome, noto-fonts, noto-emoji"

# Limpar arquivos temporários
clean:
	$(call print_info,"Limpando arquivos temporários...")
	@rm -rf /tmp/yay /tmp/Hyprland /tmp/Waybar /tmp/hyprpaper
	@rm -f /tmp/discord.deb /tmp/discord.rpm /tmp/packages.microsoft.gpg

# Desinstalar configurações
uninstall:
	$(call print_warning,"Removendo configurações...")
	@read -p "Tem certeza que deseja remover as configurações? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		rm -rf $(HYPR_DIR) $(WAYBAR_DIR); \
		$(call print_success,"Configurações removidas"); \
	else \
		$(call print_info,"Operação cancelada"); \
	fi

# Mostrar ajuda
help:
	@echo -e "$(GREEN)Makefile para configuração do Hyprland$(NC)"
	@echo ""
	@echo -e "$(YELLOW)Targets disponíveis:$(NC)"
	@echo "  all              - Instalar dependências e configurar (padrão)"
	@echo "  install          - Detectar sistema e instalar dependências"
	@echo "  install-arch     - Instalar para Arch Linux"
	@echo "  install-ubuntu   - Instalar para Ubuntu/Debian"
	@echo "  install-fedora   - Instalar para Fedora"
	@echo "  setup-configs    - Copiar arquivos de configuração"
	@echo "  clean            - Limpar arquivos temporários"
	@echo "  uninstall        - Remover configurações"
	@echo "  help             - Mostrar esta ajuda"
	@echo ""
	@echo -e "$(YELLOW)Exemplos de uso:$(NC)"
	@echo "  make             # Instalação completa automática"
	@echo "  make install     # Apenas instalar dependências"
	@echo "  make setup-configs # Apenas configurar arquivos"
	@echo ""
	@echo -e "$(BLUE)Sistema detectado: $(OS_NAME)$(NC)"
