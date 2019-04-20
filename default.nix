with (import <nixpkgs> {});

stdenv.mkDerivation {
  name = "hellod";
  nativeBuildInputs = [ dmd ];
  src = ./.;
  buildPhase = ''
    dmd -of=hello hello.d
  '';
  installPhase = ''
    mkdir -p $out
    mv hello $out/
  '';
}
