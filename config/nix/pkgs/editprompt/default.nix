{
  lib,
  stdenvNoCC,
  fetchurl,
  cacert,
  nodejs,
  makeWrapper,
}:
let
  pname = "editprompt";
  version = "1.6.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/${pname}/-/${pname}-${version}.tgz";
    hash = "sha256-XqYgC17wemQ5x+T6zOKndZe946j8nVAa+4UATaF+H/M=";
  };

  # The published dist/index.js leaves its dependencies external,
  # so they are installed in a fixed-output derivation.
  nodeModules = stdenvNoCC.mkDerivation {
    name = "${pname}-node-modules-${version}";
    inherit src;
    nativeBuildInputs = [ nodejs cacert ];
    sourceRoot = "package";
    dontConfigure = true;
    buildPhase = ''
      export HOME=$TMPDIR
      # devDependencies conflict on peer deps and are not needed at runtime
      node -e 'const p=require("./package.json");delete p.devDependencies;require("fs").writeFileSync("package.json",JSON.stringify(p))'
      npm install --omit=dev --ignore-scripts --no-audit --no-fund --no-package-lock
    '';
    installPhase = ''
      cp -r node_modules $out
    '';
    dontFixup = true;
    outputHashMode = "recursive";
    outputHash = "sha256-bjiz1PFOIZJD+6eTzyOTvq1CgErJszF5kTbmqHUkIok=";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;
  sourceRoot = "package";
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/lib/${pname} $out/bin
    cp -r dist package.json $out/lib/${pname}/
    cp -r ${nodeModules} $out/lib/${pname}/node_modules
    makeWrapper ${nodejs}/bin/node $out/bin/${pname} \
      --add-flags $out/lib/${pname}/dist/index.js
  '';

  meta = {
    description = "Write prompts for CLI tools in your favorite editor";
    homepage = "https://github.com/eetann/editprompt";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
