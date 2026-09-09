{ pkgs, lib, ... }: {
  home.packages = [
    (pkgs.julia-bin.withPackages [
      "LinearAlgebra"
      "CairoMakie"
    ])
  ];

  home.shellAliases.julia = "julia --banner=no";

  home.activation.installJuliaApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.julia-bin}/bin/julia -q << 'EOF'
    using Pkg, TOML

    function app_installed(name::AbstractString)
        manifest = Pkg.Apps.app_manifest_file()
        isfile(manifest) || return false
        return haskey(get(TOML.parsefile(manifest), "deps", Dict{String, Any}()), name)
    end

    # `Pkg.Apps.update` errors out when the package is not in the app manifest,
    # so fall back to `Pkg.Apps.add` for the initial installation.
    function ensure_app(name::AbstractString)
        app_installed(name) ? Pkg.Apps.update(name) : Pkg.Apps.add(name)
    end

    # Keep `add` here: `update` would reuse the url/rev recorded in the app
    # manifest and silently ignore the ones declared below.
    Pkg.Apps.add(; url="https://github.com/aviatesk/JETLS.jl", rev="release")
    ensure_app("Runic")
    EOF
  '';
}
