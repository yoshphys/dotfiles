{ lib, stdenv, fetchurl }:
let
  version = "0.5.3";
in
stdenv.mkDerivation {
  pname = "zk-lsp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/pxwg/zk-lsp.typ/releases/download/v${version}/zk-lsp-aarch64-apple-darwin.tar.gz";
    hash = "sha256-JYiI9r9AtN2d9EazDS3glsb8C1a7M8OEOe9Pjmpk2Tg=";
  };
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    tar -xf $src zk-lsp
    install -Dm755 zk-lsp $out/bin/zk-lsp
  '';

  meta = {
    description = "Zettelkasten language server for Typst";
    homepage = "https://github.com/pxwg/zk-lsp.typ";
    license = lib.licenses.unfree;
    platforms = [ "aarch64-darwin" "x86_64-darwin" ];
    mainProgram = "zk-lsp";
  };
}
