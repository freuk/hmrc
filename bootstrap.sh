#!/usr/bin/env bash 

nix-env -iA \
nixos.stow \
nixos.kakoune \
nixos.tig \
nixos.nnn \
nixos.htop \
nixos.zellij \
nixos.git \
nixos.icdiff \
nixos.fzf 

stow tig
stow zellij
stow kak
stow bash
stow git
