{ config, pkgs, ... }: {
  home.stateVersion = "22.05";
  home.username = "fre";
  home.homeDirectory = "/home/fre";

  home = {
    packages = with pkgs; [
      aspell
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      exa
      fasd
      fzf
      git
      htop
      hwloc
      jq
      kak-lsp

      (kakoune.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "mawww";
          repo = "kakoune";
          rev = "019fbc5";
          sha256 = "9TDijny02CSPjTXmqNDHp9gXRtj0pmXZO+wbBhy2tDQ=";
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
    home-manager.enable = true;
    bash = {
      enable = true;
      shellAliases = {
        s = "nix-shell";
        t = "tig";
        tb = "nc termbin.com 9999";
        ls = "exa";
        j = "just";
        ll = "exa -l";
        l = "exa -la";
        gst = "git status";
        gc = "git commit";
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
