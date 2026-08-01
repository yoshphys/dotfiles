{
  lib,
  fetchFromGitHub,
  ffmpeg,
  pkg-config,
  rustPlatform,
}:
let
  pname = "tanim-cli";
  version = "0.14.2";
in
rustPlatform.buildRustPackage {
  inherit pname version;
  src = fetchFromGitHub {
    owner = "liquidhelium";
    repo = "tanim";
    tag = "v${version}";
    hash = "sha256-h7Wjqt82en/nktMuSM4LMIwwsaSJUIX6EceVHGhf7xA=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config rustPlatform.bindgenHook ];
  buildInputs = [ ffmpeg ];

  buildAndTestSubdir = "tanim-cli";

  doCheck = false;

  meta = {
    description = "Render typst files to video in command line";
    homepage = "https://github.com/liquidhelium/tanim";
    license = with lib.licenses; [ mit asl20 ];
    mainProgram = "tanim-cli";
  };
}
