{
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
  , ...
} @ args:
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

  remainArgs = builtins.removeAttrs
    args xArgs;

  makeIncludePath = pkgs: builtins.concatStringsSep ":"
    (map (c: "${c.outPath}/include") pkgs);

  includes = (builtins.concatStringsSep ":"
    (includePaths ++ [(makeIncludePath buildInputs)] ));

    headerEnv = builtins.foldl' (acc: x: acc // { ${x} = includes; })
      {} ["CPATH" "C_INCLUDE_PATH" "CPLUS_INCLUDE_PATH"];

  in stdenv.mkDerivation (headerEnv // {
    inherit name src;
    buildInputs = buildInputs ++ [ ocen ];
    buildPhase = "
      mkdir -p $out/bin
      ${ocen}/bin/ocen $src -o $out/bin/$name
      ${extraBuildPhase}
    ";
  } // remainArgs)
