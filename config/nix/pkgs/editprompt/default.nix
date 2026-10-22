{
  lib,
  buildNpmPackage,
  fetchNpmDeps,
  fetchurl,
  nodejs,
}:
let
  pname = "editprompt";
  version = "1.6.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-XqYgC17wemQ5x+T6zOKndZe946j8nVAa+4UATaF+H/M=";
  };

  sourceRoot = "package";

  # The published tarball ships no lockfile, so one is vendored next to this
  # file; without it npm re-resolves the semver ranges on every build and the
  # dependency hash drifts whenever a transitive dependency is republished.
  #
  # The lockfile is generated from a package.json with devDependencies and
  # peerDependencies dropped: the former conflict on peer deps and are not
  # needed at runtime, the latter only asks for typescript, which the prebuilt
  # dist/index.js never imports. postPatch repeats that removal so `npm ci`
  # sees a package.json in sync with the lockfile.
  #
  # To regenerate after a version bump:
  #   tar xzf editprompt-<version>.tgz && cd package
  #   node -e 'const p=require("./package.json");delete p.devDependencies;delete p.peerDependencies;require("fs").writeFileSync("package.json",JSON.stringify(p))'
  #   npm install --package-lock-only --ignore-scripts --no-audit --no-fund
  postPatch = ''
    node -e 'const p=require("./package.json");delete p.devDependencies;delete p.peerDependencies;require("fs").writeFileSync("package.json",JSON.stringify(p))'
    cp ${./package-lock.json} package-lock.json
  '';
in
buildNpmPackage {
  inherit
    pname
    version
    src
    sourceRoot
    postPatch
    ;

  # fetchNpmDeps replays postPatch to pick up the vendored lockfile, but it does
  # not pull in nodejs on its own, so npmDeps is spelled out instead of relying
  # on the npmDepsHash shorthand.
  npmDeps = fetchNpmDeps {
    inherit src sourceRoot postPatch;
    name = "${pname}-${version}-npm-deps";
    hash = "sha256-ZKrVKOJCn1OczT6WLzmdw5wH93bkasRrsVd1w/Ou3HY=";
    nativeBuildInputs = [ nodejs ];
  };

  # dist/ is already built in the published tarball.
  dontNpmBuild = true;

  meta = {
    description = "Write prompts for CLI tools in your favorite editor";
    homepage = "https://github.com/eetann/editprompt";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
