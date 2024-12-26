{ config, pkgs, ... }: {
  home.stateVersion = "23.05";
  home.username = "ubuntu";
  home.homeDirectory = "/home/ubuntu";

  home = {
    packages = with pkgs; [
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      cached-nix-shell
      exa
      fasd
      fzf
      git
      git-interactive-rebase-tool
      htop
      hwloc
      jq
      kak-lsp

      (kakoune.overrideAttrs (old: {
        src = builtins.fetchTarball {
          url =
            "https://github.com/mawww/kakoune/archive/refs/tags/v2023.08.05.tar.gz";
          sha256 = "0siqlp8hx6hjp2rmrbz5c5qdwbfs1akn6257zch3n4kggz1y87a5";
        };

      }))

      nixfmt
      nnn
      pinentry-curses
      ripgrep
      tig
      tomb
      tree
      zellij

      (pkgs.writeScriptBin "screens.sh" (builtins.readFile ./screens.sh))
      (pkgs.writeScriptBin "print_lines.py"
        (builtins.readFile ./print_lines.py))

    ];
  };

  services.lorri.enable = true;

  programs = {
    direnv.enable = true;
    home-manager.enable = true;
    bash = {
      enable = true;
      shellAliases = {
        t = "tig";
        tb = "nc termbin.com 9999";
        ls = "exa";
        j = "just";
        ll = "exa -l";
        l = "exa -la";
        gst = "git status";
        gc = "git commit";
        groot = "git rev-parse --show-toplevel";
        cg = "cd $(groot)";
        g = "git";
        ga = "git add";
        gps = "git push";
        k = "kak";
        z = "zellij";
        gpu = "git pull";
      };
      bashrcExtra = (builtins.readFile ./bashrc.sh) + ''
        . ~/.nix-profile/etc/profile.d/hm-session-vars.sh
      '';
    };
  };

  home.file = {
    ".inputrc".source = ./inputrc;
    ".ghc/ghci.conf".source = ./ghci.conf;
    ".config/nixpkgs/config.nix".source = ./config.nix;
  };

  xdg = {
    configFile = {
      "git/config".source = ./gitconfig;
      "kak/autoload".source = ./kak/autoload;
      "kak/colors".source = ./kak/colors;
      "kak/kakrc".source = ./kak/kakrc;
      "kitty/kitty.conf".source = ./kitty.conf;
      "nnn/nuke.sh".source = ./nuke.sh;
      "tig/config".source = ./tig.cfg;
      "zellij/config.kdl".source = ./zellij.kdl;
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/plain" = [ "code.desktop" "code-url-handler.desktop" ];
        "text/x-uri" = [ "code-url-handler.desktop" ];
      };
    };
  };

}
