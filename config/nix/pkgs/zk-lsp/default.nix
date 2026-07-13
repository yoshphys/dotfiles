{ lib, stdenv, fetchurl }:
let
  version = "0.5.4";
in
stdenv.mkDerivation {
  pname = "zk-lsp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/pxwg/zk-lsp.typ/releases/download/v${version}/zk-lsp-aarch64-apple-darwin.tar.gz";
    hash = "sha256-F1B7+P9qXp0X98W23MRZGZ0TCqQrBIVfRWOs3Cxn6cs=";
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
