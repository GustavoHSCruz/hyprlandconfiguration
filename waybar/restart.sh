#!/usr/bin/env bash

# Caminhos para configs e estilos
TOP_CONF="$HOME/.config/waybar/config-top.jsonc"
TOP_STYLE="$HOME/.config/waybar/style-top.css"
BOT_CONF="$HOME/.config/waybar/config-bottom.jsonc"
BOT_STYLE="$HOME/.config/waybar/style-bottom.css"

# Mata todas as instâncias anteriores
pkill waybar

# Reabre as duas barras
waybar -c "$TOP_CONF" -s "$TOP_STYLE" &
waybar -c "$BOT_CONF" -s "$BOT_STYLE" &
