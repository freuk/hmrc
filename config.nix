{
  allowUnfree = true;
  allowBroken = true;
  permittedInsecurePackages = [ "openssl-1.0.2u" ];
  packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball
      "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
      };
  };
}
