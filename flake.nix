{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.ocen = {
    url = "github:ocen-lang/ocen";
    flake = false;
  };

  outputs = {self, ocen, nixpkgs, ... }:
  let
    withSystem = f:
      (with nixpkgs; lib.foldAttrs lib.mergeAttrs {}
        (map (s: lib.mapAttrs (_: v: {${s} = v;}) (f s))
          ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"]));
  in
  rec {
    lib = pkgs: { buildPackage = pkgs.callPackage ./pkgs/buildPkg.nix; };
    inherit (withSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      rec {
        packages.default = packages.ocen;
        packages.ocen = pkgs.callPackage ./pkgs/ocen.nix {
          ocen = ./.;
          cc=pkgs.gcc;
        };

        packages.sdl-raytrace = (lib pkgs).buildPackage {
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
      })) packages;
  };
}
