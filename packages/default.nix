{ nix-pkgset, pkgs }:
nix-pkgset.lib.makePackageSet "lun-pkgs" pkgs.newScope (self: {
  rmc = pkgs.python3Packages.callPackage ./rmc { };
  wowup = self.callPackage ./wowup { };
  wally = self.callPackage ./wally { };
  vkpeak = self.callPackage ./vkpeak { };
  sillytavern = self.callPackage ./sillytavern { };
  switchtec-user = self.callPackage ./switchtec-user { };
  samrewritten = self.callPackage ./samrewritten { };
  edhm-ui = self.callPackage ./edhm-ui { };
})
