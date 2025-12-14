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
          url = "https://www.hexaly.com/downloads/14_0_20251211/Hexaly_14_0_20251211_LinuxA64.run";
          sha256 = "1lq765vd192dmv15g9z43yfrd29wz6qkxdcqgr57ya7i23pxz4ms";
        }
        else {
          url = "https://www.hexaly.com/downloads/14_0_20251211/Hexaly_14_0_20251211_Linux64.run";
          sha256 = "0shy3d5fm8ziihysa5r2f4vpx47h4v68di46s2lgcqy1q9gi86q3";
        };

      hexaly = pkgs.stdenv.mkDerivation {
        name = "hexaly";
        version = "14.0.20251211";

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
          rm $out/bin/localsolver.jar
          rm $out/bin/localsolvernet.dll
          rm -rf $out/bin/python/localsolver
          mkdir -p $out/lib
          mv $out/bin/libhexaly140.so $out/lib
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
