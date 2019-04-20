with (import <nixpkgs> {});

stdenv.mkDerivation {
  name = "hellod";
  nativeBuildInputs = [ dmd ];
  src = ./.;
  buildPhase = ''
    dmd -of=hellod hello.d
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv hellod $out/bin/
  '';
}
