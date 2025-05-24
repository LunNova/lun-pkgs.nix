## Configuration:
# Control you default wine config in nixpkgs-config:
# wine = {
#   release = "stable"; # "stable", "unstable", "staging", "wayland"
#   build = "wineWow"; # "wine32", "wine64", "wineWow"
# };
# Make additional configurations on demand:
# wine.override { wineBuild = "wine32"; wineRelease = "staging"; };
{
  lib,
  callPackage,
  wineRelease ? "staging",
  wineBuild ? "wineWow64",
  gettextSupport ? false,
  fontconfigSupport ? false,
  alsaSupport ? false,
  gtkSupport ? false,
  openglSupport ? false,
  tlsSupport ? true,
  gstreamerSupport ? false,
  cupsSupport ? false,
  dbusSupport ? false,
  openclSupport ? false,
  cairoSupport ? false,
  odbcSupport ? false,
  netapiSupport ? false,
  cursesSupport ? false,
  vaSupport ? false,
  pcapSupport ? false,
  v4lSupport ? false,
  saneSupport ? false,
  gphoto2Support ? false,
  krb5Support ? false,
  pulseaudioSupport ? true,
  udevSupport ? true,
  ffmpegSupport ? true,
  xineramaSupport ? false,
  vulkanSupport ? true,
  sdlSupport ? false,
  usbSupport ? false,
  mingwSupport ? true,
  waylandSupport ? false,
  x11Support ? true,
  embedInstallers ? true, # The Mono and Gecko MSI installers
  moltenvk, # Allow users to override MoltenVK easily
}:

let
  wine-build =
    build: release:
    lib.getAttr build (
      callPackage ./packages.nix {
        wineRelease = release;
        supportFlags = {
          inherit
            alsaSupport
            cairoSupport
            cupsSupport
            cursesSupport
            dbusSupport
            embedInstallers
            fontconfigSupport
            gettextSupport
            gphoto2Support
            gstreamerSupport
            gtkSupport
            krb5Support
            mingwSupport
            netapiSupport
            odbcSupport
            openclSupport
            openglSupport
            pcapSupport
            pulseaudioSupport
            saneSupport
            sdlSupport
            tlsSupport
            udevSupport
            usbSupport
            v4lSupport
            vaSupport
            vulkanSupport
            ffmpegSupport
            waylandSupport
            x11Support
            xineramaSupport
            ;
        };
        inherit moltenvk;
      }
    );

  baseRelease =
    {
      staging = "unstable";
      yabridge = "yabridge";
    }
    .${wineRelease} or null;
in
if baseRelease != null then
  callPackage ./staging.nix {
    wineUnstable = (wine-build wineBuild baseRelease).override {
      inherit wineRelease;
    };
  }
else
  wine-build wineBuild wineRelease
