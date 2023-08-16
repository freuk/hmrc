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
      src = builtins.fetchTarball {
       url="https://github.com/mawww/kakoune/archive/refs/tags/v2023.08.05.tar.gz";
      sha256="0siqlp8hx6hjp2rmrbz5c5qdwbfs1akn6257zch3n4kggz1y87a5";};

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
