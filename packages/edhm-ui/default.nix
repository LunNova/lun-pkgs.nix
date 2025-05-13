{
  stdenv,
  lib,
  fetchurl,
  unzip,
  makeBinaryWrapper,
  autoPatchelfHook,
  makeDesktopItem,
  copyDesktopItems,
  electron,
  asar,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "edhm-ui";
  version = "3.0.13";
  src = fetchurl {
    url = "https://github.com/BlueMystical/EDHM_UI/releases/download/v${finalAttrs.version}/edhm-ui-v3-linux-x64.zip";
    sha256 = "1z0zg6bfhancq2a8s5s0f2cvxwbgi25iy94hifnxg2yapdljv0qg";
  };

  nativeBuildInputs = [
    unzip
    makeBinaryWrapper
    autoPatchelfHook
    copyDesktopItems
    asar
  ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc) # Often needed for electron apps
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "EDHM UI";
      exec = "edhm-ui";
      icon = "edhm-ui"; # You might need to find or create an icon
      comment = finalAttrs.meta.description;
      desktopName = "EDHM UI";
      categories = [ "Game" ]; # Adjust if a more specific category exists
    })
  ];

  installPhase = ''
    runHook preInstall
    # mkdir -p "$out/bin"
    mkdir -p "$out/share/edhm-ui"
    # mkdir -p "$out/share/icons/hicolor/512x512/apps"

    cp -r ./* "$out/share/edhm-ui/"
    rm "$out/share/edhm-ui/"{*.so*,edhm-ui-v3,chrome_crashpad_handler,chrome-sandbox} 

    # Handle resources, similar to Trilium
    tmp=$(mktemp -d)
    asar extract "$out/share/edhm-ui/resources/app.asar" "$tmp"
    rm "$out/share/edhm-ui/resources/app.asar"

    # You might need to patch paths within the asar archive if it relies on
    # absolute paths. This is a common issue with electron apps.
    # Example (adjust based on EDHM_UI's structure):
    # for f in $(find "$tmp" -name "*.js" -o -name "*.html" -o -name "*.css"); do
    #   substituteInPlace "$tmp/$f" --replace "/path/to/resources" "$out/share/edhm-ui/resources"
    # done
    substituteInPlace "$tmp/.vite/build/main.js" \
      --replace-fail "process.resourcesPath" "'$out/share/edhm-ui/resources/'"
    autoPatchelf "$tmp"
    # Assuming an icon exists within the resources
    find "$tmp" -name "*.png" -o -name "*.svg" -print -quit | xargs -r cp {} "$out/share/icons/hicolor/512x512/apps/edhm-ui.$(echo {} | sed -e 's/.*\.\(.*\)/\1/')"

    asar pack "$tmp/" "$out/share/edhm-ui/resources/app.asar"
    rm -rf "$tmp"

    # Wrap the electron executable
    makeWrapper "${lib.getExe electron}" "$out/bin/edhm-ui" \
      --add-flags "$out/share/edhm-ui/resources/app.asar"

    runHook postInstall
  '';

  meta = {
    description = "User Interface for Elite Dangerous HUD Mod (EDHM)";
    homepage = "https://github.com/BlueMystical/EDHM_UI";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [
      LunNova
    ];
    mainProgram = "edhm-ui";
    platforms = [ "x86_64-linux" ]; # Only x64 Linux for this release
  };
})
