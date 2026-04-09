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
          url = "https://www.hexaly.com/downloads/14_5_20260326/Hexaly_14_5_20260326_LinuxA64.run";
          sha256 = "sha256-sG4rYnWCLNAkx9RBDyo4K8xgNDjW/hfPye7/QdcDs4I=";
        }
        else {
          url = "https://www.hexaly.com/downloads/14_5_20260326/Hexaly_14_5_20260326_Linux64.run";
          sha256 = "sha256-5q3/mLOkMMXWQ4IAje/WPrkgopF3Dxzdn9q0hT6f0yc=";
        };

      hexaly = pkgs.stdenv.mkDerivation {
        name = "hexaly";
        version = "14.5.20260326";

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
          mv $out/bin/libhexaly145.so $out/lib
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
