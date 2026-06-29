{ lib, stdenv, fetchurl }:
let
  version = "0.7.0";
in
stdenv.mkDerivation {
  pname = "kakehashi";
  inherit version;

  src = fetchurl {
    url = "https://github.com/atusy/kakehashi/releases/download/v${version}/kakehashi-v${version}-aarch64-apple-darwin.tar.gz";
    hash = "sha256-0uQk+PcVEuea2xUz/Xwb0u+7O7BjcAfmCCOK08kLlY8=";
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
