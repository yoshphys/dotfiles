{
  lib,
  fetchFromGitHub,
  openssl,
  pkg-config,
  rustPlatform,
}:
let
  pname = "yaskkserv2";
  version = "0.1.7";
in
rustPlatform.buildRustPackage {
  inherit pname version;
  src = fetchFromGitHub {
    owner = "wachikun";
    repo = pname;
    rev = version;
    sha256 = "sha256-bF8OHP6nvGhxXNvvnVCuOVFarK/n7WhGRktRN4X5ZjE=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];
  doCheck = false;

  patchPhase = ''
    substituteInPlace src/skk/mod.rs \
      --replace-fail /etc/yaskkserv2.conf $out/etc/yaskkserv2.conf
  '';

  buildPhase = ''
    cargo build --release
  '';

  installPhase = ''
    mkdir -p $out/{etc,bin}
    cp -av etc/yaskkserv2.conf $out/etc
    cp -av target/release/yaskkserv2 $out/bin
    cp -av target/release/yaskkserv2_make_dictionary $out/bin
  '';

  meta = {
    description = "SKK server written in Rust";
    homepage = "https://github.com/wachikun/yaskkserv2";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
}
