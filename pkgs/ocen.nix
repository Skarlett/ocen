{ stdenv
  , lib
  , cc
  , ocen
  , bash
  , makeWrapper
}:
  stdenv.mkDerivation {
    inherit cc;
    name = "ocen";
    src = ocen;
    nativeBuildInputs = [ makeWrapper bash ];
    buildPhase = ''
      mkdir -p $out/bin
      ${bash}/bin/bash $src/meta/bootstrap.sh
      cp ./bootstrap/ocen $out/bin/ocen
      cp -r . $out
    '';

    fixupPhase = ''
      wrapProgram $out/bin/ocen \
        --prefix PATH : ${lib.makeBinPath [ bash cc ]} \
        --prefix OCEN_ROOT : $out
    '';
  }
