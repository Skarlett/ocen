{
  inputs.skarlett-nix.url = "github:skarlett/nixos-config";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.ocen = {
    url = "github:ocen-lang/ocen";
    flake = false;
  };


  outputs = {self, ocen, nixpkgs, skarlett-nix, ... }:
    let
      lib = nixpkgs.lib;

      withSystem = f:
        lib.foldAttrs lib.mergeAttrs {}
          (map (s: lib.mapAttrs (_: v: {${s} = v;}) (f s))
            ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"]);


    in
  {
    inherit (withSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in

      rec {

        packages.mkci = skarlett-nix.packages.${system}.mkci.override {
          inherit self;
        };

        packages.sdl-raytrace = self.outputs.lib.buildPackage {
          name = "sdl-raytrace";
          src = "${ocen}/examples/sdl_raytrace.oc";
          ocen = packages.default;
          phases = "buildPhase";
          includePaths = [ "${pkgs.SDL2.dev}/include/SDL2" ];
          buildInputs = with pkgs; [
            SDL2 SDL2.dev
            SDL2_image SDL2_ttf
            SDL2_mixer SDL2_gfx
          ];
        };

        packages.default = pkgs.stdenv.mkDerivation {
          name = "ocen";
          src = ocen;
          nativeBuildInputs = [ pkgs.makeWrapper pkgs.gcc pkgs.bash ];
          buildPhase = ''
            mkdir -p $out/bin
            ${pkgs.bash}/bin/bash $src/meta/bootstrap.sh
            cp ./bootstrap/ocen $out/bin/ocen
            cp -r . $out
          '';

          fixupPhase = ''
            wrapProgram $out/bin/ocen \
              --prefix PATH : ${lib.makeBinPath [ pkgs.bash pkgs.gcc ]} \
              --prefix OCEN_ROOT : $out
          '';
        };
      })) packages;

      lib.buildPackage = {
        stdenv
        , src
        , name
        , buildInputs
        , ocen
        , includePaths ? []
        , extraBuildPhase ? ""
        , emitDebug ? true
        , useHints ? true
        , outputC ? false
        , minimalErrors ? false
        , ... } @ args:

        let
          xArgs = [
            "name"
            "src"
            "ocen"
            "stdenv"
            "buildInputs"
            "nativeBuildInputs"
            "extraBuildPhase"
            "emitDebug"
            "useHints"
            "outputC"
            "minimalErrors"
          ];

          makeIncludePath = pkgs: lib.strings.concatStringsSep ":" (map (c: "${c.outPath}/include") pkgs);

          includes = (lib.strings.concatStringsSep ":" ( includePaths ++ [  (makeIncludePath buildInputs)]));
          envInclude = ["CPATH" "C_INCLUDE_PATH" "CPLUS_INCLUDE_PATH"];

          headerEnv = builtins.foldl' (acc: x: acc // { ${x} = includes; })
            {} envInclude;

          remainArgs = builtins.removeAttrs
            args xArgs;
        in
          stdenv.mkDerivation (headerEnv // {
            inherit name src;
            buildInputs = buildInputs ++ [ ocen ];
            buildPhase = "
              mkdir -p $out/bin
              ${ocen}/bin/ocen $src -o $out/bin/$name
              ${extraBuildPhase}
            ";
          } // remainArgs);
  };
}
