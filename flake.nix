{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      hexalyPlatforms =
        if pkgs.stdenv.isAarch64
        then {
          url = "https://www.hexaly.com/downloads/15_0_20260721/Hexaly_15_0_20260721_LinuxA64.run";
          sha256 = "sha256-aDvLzZw80s/59YQfeKBK7qJy5rjARwLvCScKT5Dgy84=";
        }
        else {
          url = "https://www.hexaly.com/downloads/15_0_20260721/Hexaly_15_0_20260721_Linux64.run";
          sha256 = "sha256-W+9ttpKD3zcSyq3w5IshBxCPefLqL8drmKWJMsq9Az4=";
        };

      hexaly = pkgs.stdenv.mkDerivation {
        name = "hexaly";
        version = "15.0.20260721";

        hexalyInstaller = pkgs.fetchurl {
          url = hexalyPlatforms.url;
          sha256 = hexalyPlatforms.sha256;
        };

        dontUnpack = true;

        nativeBuildInputs = [
          pkgs.autoPatchelfHook
        ];

        buildInputs = [
          pkgs.stdenv.cc.cc.lib
        ];

        installPhase = ''
          bash $hexalyInstaller --noroot --target $out
          rm $out/uninstall.sh
          mkdir -p $out/lib
          mv $out/bin/libhexaly150.so $out/lib
          mv $out/bin/hexaly.jar $out/lib
          mv $out/bin/Hexaly.NET.dll $out/lib
          mv $out/bin/python $out/lib
        '';

        meta = {
          homepage = "https://www.hexaly.com/";
          license = pkgs.lib.licenses.unfree;
          platforms = pkgs.lib.platforms.linux;
        };
      };
    in {
      packages = {
        inherit hexaly;
        default = hexaly;
      };
    });
}
