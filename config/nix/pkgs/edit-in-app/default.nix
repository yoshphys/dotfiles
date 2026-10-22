{ lib, stdenvNoCC, neovim }:
stdenvNoCC.mkDerivation {
  pname = "edit-in-app";
  version = "0.1.0";

  src = ./.;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    install -Dm755 edit-in-app      $out/bin/edit-in-app
    install -Dm755 edit-in-app-edit $out/bin/edit-in-app-edit

    substituteInPlace $out/bin/edit-in-app \
      --replace-fail @out@ "$out"
    substituteInPlace $out/bin/edit-in-app-edit \
      --replace-fail @nvim@ "${neovim}/bin/nvim"
  '';

  meta = {
    description = "Edit any macOS text field in Ghostty + nvim";
    platforms = lib.platforms.darwin;
    mainProgram = "edit-in-app";
  };
}
