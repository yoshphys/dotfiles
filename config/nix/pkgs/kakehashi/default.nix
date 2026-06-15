{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:
let
  pname = "kakehashi";
  version = "0.6.0";
in
rustPlatform.buildRustPackage {
  inherit pname version;
  src = fetchFromGitHub {
    owner = "atusy";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-DxTEKrG1eWtjFJYlwuSsLkeowjuATxpRABQgExb4bW4=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Tree-sitter based language server bridge";
    homepage = "https://github.com/atusy/kakehashi";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
