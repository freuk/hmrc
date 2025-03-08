#!/usr/bin/env bash 

nix-env -iA \
nixpkgs.stow \
nixpkgs.kakoune \
nixpkgs.tig \
nixpkgs.nnn \
nixpkgs.htop \
nixpkgs.zellij \
nixpkgs.fzf 

stow tig
stow zellij
stow kak
stow bash
stow git
