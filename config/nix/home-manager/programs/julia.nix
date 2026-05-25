{ pkgs, lib, ... }: {
  home.packages = [
    (pkgs.julia-bin.withPackages [
      "LinearAlgebra"
      "CairoMakie"
    ])
  ];

  home.shellAliases.julia = "julia --banner=no";

  home.activation.installJETLS = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.julia-bin}/bin/julia -q << 'EOF'
    using Pkg
    Pkg.Apps.add(; url="https://github.com/aviatesk/JETLS.jl", rev="release")
    Pkg.Apps.add("Runic")
    EOF
  '';
}
