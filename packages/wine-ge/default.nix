{
  lib,
  fetchFromGitHub,
  python3,
  autoreconfHook,
  stdenv,
  perl,
  gccMultiStdenv,
  flex,
  bison,
  fontforge,
  makeWrapper,
  pkg-config,
  freetype,
  libunwind,
  wayland,
  wayland-scanner,
  wayland-protocols,
  libxkbcommon,
  libgbm,
  xorg,
  vulkan-loader,
  dbus,
  udev,
  libpulseaudio,
  libGLU,
  libGL,
  libdrm,
  gettext,
  SDL2,
  libkrb5,
  ncurses,
  unixODBC,
  samba4,
  libcap,
  libpcap,
  openssl,
  gnutls,
  gtk3,
  glib,
  libva,
  fontconfig,
  libgphoto2,
  libv4l,
  alsa-lib,
  ffmpeg_4,
  libgcrypt,
  # libinotify-kqueue,
  # is64 ? true,
  pkgsi686Linux,
  x11Support ? true,
}:
# let
# stagingPatches = fetchFromGitHub {
#   owner = "wine-staging";
#   repo = "wine-staging";
#   rev = "05bc4b822fdb1898777b08a8597639ad851f5601";
#   hash = "sha256-0mzKoaNaJ6ZDYQtJFU383W5nNe/FKtpBjeWDpiqkmp4=";
# };
# in
# TODO: Shared WoW64 https://gitlab.winehq.org/wine/wine/-/wikis/Building-Wine#Shared_WoW64
gccMultiStdenv.mkDerivation (finalAttrs: {
  meta.broken = true; # FIXME: don't use this, produces subtly fucked up wine yet to debug
  pname = "wineWow-valve";
  version = "unstable-202505";
  src = fetchFromGitHub {
    owner = "ValveSoftware";
    repo = "wine";
    rev = "7f5ec1eb8994ff4fe7a456dcb7bed69b0a3717bf";
    hash = "sha256-i5+Nkf5CZVNUmYIb0JOcFmCsskD+wx7vKztzYXwayzY=";
  };
  strictDeps = true;
  nativeBuildInputs = [
    python3
    autoreconfHook
    perl
    bison
    flex
    fontforge
    makeWrapper
    gettext
    pkg-config
  ];
  buildInputs =
    [
      gettext
      freetype
      perl
      libunwind
      wayland
      wayland-scanner
      libxkbcommon
      wayland-protocols
      wayland.dev
      libxkbcommon.dev
      libgbm
      vulkan-loader
      dbus
      libGLU
      libGL
      libdrm
      udev
      libpulseaudio
      SDL2
      libkrb5
      ncurses
      unixODBC
      samba4
      libcap
      libpcap
      openssl
      gnutls
      gtk3
      glib
      libva
      fontconfig
      libgphoto2
      libv4l
      alsa-lib
      ffmpeg_4
      libgcrypt
      # libinotify-kqueue
    ]
    # ++ (with gst_all_1; [
    #   gstreamer
    #   gst-plugins-base
    #   gst-plugins-good
    #   gst-plugins-ugly
    #   gst-libav
    #   gst-plugins-bad
    # ])
    # ++ (with pkgsi686Linux.gst_all_1; [
    #   gstreamer
    #   gst-plugins-base
    #   gst-plugins-good
    #   gst-plugins-ugly
    #   gst-libav
    #   gst-plugins-bad
    # ])
    ++ [
      pkgsi686Linux.gettext
      pkgsi686Linux.dbus
      pkgsi686Linux.freetype
      pkgsi686Linux.perl
      pkgsi686Linux.libunwind
      pkgsi686Linux.wayland
      pkgsi686Linux.wayland-scanner
      pkgsi686Linux.libxkbcommon
      pkgsi686Linux.wayland-protocols
      pkgsi686Linux.wayland.dev
      pkgsi686Linux.libxkbcommon.dev
      pkgsi686Linux.libgbm
      pkgsi686Linux.vulkan-loader
      pkgsi686Linux.libGLU
      pkgsi686Linux.libGL
      pkgsi686Linux.libdrm
      pkgsi686Linux.udev
      pkgsi686Linux.libpulseaudio
      pkgsi686Linux.SDL2
      pkgsi686Linux.samba4
      pkgsi686Linux.libkrb5
      pkgsi686Linux.ncurses
      pkgsi686Linux.unixODBC
      pkgsi686Linux.libcap
      pkgsi686Linux.libpcap
      pkgsi686Linux.openssl
      pkgsi686Linux.gnutls
      pkgsi686Linux.glib
      pkgsi686Linux.gtk3
      pkgsi686Linux.libva
      pkgsi686Linux.fontconfig
      pkgsi686Linux.libgphoto2
      pkgsi686Linux.libv4l
      pkgsi686Linux.alsa-lib
      pkgsi686Linux.ffmpeg_4
      pkgsi686Linux.libgcrypt
      # pkgsi686Linux.libinotify-kqueue
    ]
    ++ lib.optionals x11Support (
      with xorg;
      [
        libX11
        libXcomposite
        libXcursor
        libXext
        libXfixes
        libXi
        libXrandr
        libXrender
        libXxf86vm
      ]
      ++ (with pkgsi686Linux.xorg; [
        libX11
        libXcomposite
        libXcursor
        libXext
        libXfixes
        libXi
        libXrandr
        libXrender
        libXxf86vm
      ])
    );
  # env.LD_LIBRARY_PATH = lib.makeLibraryPath [
  #   stdenv.cc.cc.out
  #   stdenv.cc.cc.lib
  # ];
  enableParallelBuilding = true;
  hardeningDisable = [
    "bindnow"
    "stackclashprotection"
  ];
  postPatch = ''
    # CC=${stdenv.cc.cc}/bin/gcc
    # touch test.c
    # $CC test.c
    mkdir -p tmphome
    export HOME=$(realpath tmphome)
    patchShebangs ./tools ./dlls/winevulkan/make_vulkan ./autogen.sh
    bash ./autogen.sh
    # ./wine-staging/staging/patchinstall.py DESTDIR="$(realpath wine)" --all
    # cd wine
  '';

  NIX_LDFLAGS = toString (
    map (path: "-rpath " + path) (
      map (x: "${lib.getLib x}/lib") (
        [ stdenv.cc.cc ]
        # Avoid adding rpath references to non-existent framework `lib` paths.
        ++ finalAttrs.buildInputs
      )
      # libpulsecommon.so is linked but not found otherwise
      ++ (map (x: "${lib.getLib x}/lib/pulseaudio") [
        libpulseaudio
        pkgsi686Linux.libpulseaudio
      ])
      ++ (map (x: "${lib.getLib x}/share/wayland-protocols") [
        wayland-protocols
        pkgsi686Linux.wayland-protocols
      ])
    )
  );

  # Don't shrink the ELF RPATHs in order to keep the extra RPATH
  # elements specified above.
  dontPatchELF = true;

  builder = ./wine-wow-builder.sh;

  configureFlags = [
    "--without-wayland"
    "--without-osmesa"

    "--with-alsa"
    "--with-gcrypt"
    "--with-gettext"
    # "--with-gettextpo"
    "--with-gnutls"
    "--with-gssapi"
    "--without-gstreamer"
    "--with-krb5"
    "--with-netapi"
    "--with-pcap"
    "--with-pthread"
    "--with-pulse"
    "--with-sdl"
    "--with-v4l2"
    "--with-xcursor"
    "--with-xfixes"
    "--with-xinput"

    "--with-dbus"
    "--with-libcap"

    "--with-freetype"
    "--with-alsa"
    # "--with-capi"
    "--with-coreaudio"
    "--with-ffmpeg"
    "--with-opengl"
    "--with-vulkan"
    "--with-x"
    "--with-ssl"
    "--with-udev"
    "--with-unwind"
    "--with-v4l"
    "--with-sdl"
    "--with-pulseaudio"
    "--with-nls"
    "--with-tls"
    "--with-ssl"
    "--with-fontconfig"
    "--with-alsa"
    # "--with-xcomposite"
  ];
})
