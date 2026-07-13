{ lib, stdenv, fetchurl }:
let
  version = "0.8.0";
in
stdenv.mkDerivation {
  pname = "kakehashi";
  inherit version;

  src = fetchurl {
    url = "https://github.com/atusy/kakehashi/releases/download/v${version}/kakehashi-v${version}-aarch64-apple-darwin.tar.gz";
    hash = "sha256-cAPjYbt5pICSUQceKroyGRsBMWMSCz8SF5/4ujFy114=";
  };
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    tar -xf $src
    install -Dm755 kakehashi $out/bin/kakehashi
  '';

  meta = {
    description = "Tree-sitter based language server bridge";
    homepage = "https://github.com/atusy/kakehashi";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    mainProgram = "kakehashi";
  };
}
