{
  description = "Hexaly Optimizer";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }: let
    version = "15.0.20260721";
    soname = "libhexaly150.so";

    srcs = {
      x86_64-linux = {
        url = "https://www.hexaly.com/downloads/15_0_20260721/Hexaly_15_0_20260721_Linux64.run";
        sha256 = "sha256-W+9ttpKD3zcSyq3w5IshBxCPefLqL8drmKWJMsq9Az4=";
      };
      aarch64-linux = {
        url = "https://www.hexaly.com/downloads/15_0_20260721/Hexaly_15_0_20260721_LinuxA64.run";
        sha256 = "sha256-aDvLzZw80s/59YQfeKBK7qJy5rjARwLvCScKT5Dgy84=";
      };
    };
  in
    flake-utils.lib.eachSystem (builtins.attrNames srcs) (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      hexaly = pkgs.stdenv.mkDerivation {
        pname = "hexaly";
        inherit version;

        src = pkgs.fetchurl srcs.${system};

        outputs = ["out" "lib" "dev" "doc" "python"];

        dontUnpack = true;
        dontBuild = true;

        nativeBuildInputs = [pkgs.autoPatchelfHook];
        buildInputs = [(pkgs.lib.getLib pkgs.stdenv.cc.cc)];

        appendRunpaths = ["${placeholder "lib"}/lib"];

        propagatedBuildOutputs = ["lib"];

        installPhase = ''
          runHook preInstall

          mkdir -p "$out" "$lib" "$dev" "$doc" "$python"

          hx="$NIX_BUILD_TOP/hexaly"
          bash "$src" --noroot --target "$hx"

          # out
          mkdir -p "$out/bin"
          cp "$hx/bin/hexaly" "$out/bin"

          # lib
          install -Dm755 "$hx/bin/${soname}" "$lib/lib/${soname}"

          # dev
          cp -r "$hx/include" "$dev/include"

          # doc
          mkdir -p "$doc/share/doc" "$doc/share/examples"
          cp -r "$hx/docs" "$doc/share/doc/hexaly"
          cp -r "$hx/examples" "$doc/share/examples/hexaly"

          # python
          mkdir -p "$python/lib"
          cp -r "$hx/bin/python" "$python/lib/python"
          ln -s "$lib/lib/${soname}" "$python/lib/python/hexaly/${soname}"
          printf 'from . import optimizer, modeler\n__all__ = ["optimizer", "modeler"]\n' > "$python/lib/python/hexaly/__init__.py"

          runHook postInstall
        '';

        meta = {
          description = "Hexaly Optimizer";
          homepage = "https://www.hexaly.com/";
          mainProgram = "hexaly";
          license = pkgs.lib.licenses.unfree;
          sourceProvenance = with pkgs.lib.sourceTypes; [
            binaryNativeCode
            # binaryBytecode
          ];
          platforms = builtins.attrNames srcs;
        };
      };

      mkHexalyPython = python:
        python.pkgs.buildPythonPackage {
          pname = "hexaly";
          inherit version;

          pyproject = false;
          dontUnpack = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            mkdir -p "$out/${python.sitePackages}"
            ln -s ${hexaly.python}/lib/python/hexaly "$out/${python.sitePackages}/hexaly"
            runHook postInstall
          '';

          meta = hexaly.meta // {description = "Python bindings for Hexaly Optimizer";};
        };
    in {
      packages = {
        inherit hexaly;
        default = hexaly;
      };

      checks.python-import = mkHexalyPython pkgs.python3;

      devShells.default = pkgs.mkShell {
        packages = [
          hexaly
          (pkgs.python3.withPackages (ps: [(mkHexalyPython pkgs.python3)]))
        ];
      };
    });
}
