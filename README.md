```
curl -L https://nixos.org/nix/install | sh
. /home/cc/.nix-profile/etc/profile.d/nix.sh

nix-channel --remove nixpkgs
nix-channel --add https://nixos.org/channels/nixos-<version> nixpkgs
nix-channel --add https://github.com/rycee/home-manager/archive/release-<version>.tar.gz home-manager
nix-channel --update

rm -rf ~/.config/nixpkgs
git clone https://github.com/freuk/homerc.git ~/.config/nixpkgs

rm ~/.bash_profile
rm ~/.bashrc

export TERM=tmux-256color
nix-shell '<home-manager>' -A install
```
