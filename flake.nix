{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-pkgset.url = "github:szlend/nix-pkgset";
    nix-pkgset.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-pkgset,
      flake-utils,
      pre-commit-hooks,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # selfPkgs = self.legacyPackages.${system};
        selfChecks = self.checks.${system};
        inherit (pkgs) lib;
      in
      {
        legacyPackages = pkgs.callPackage ./packages { inherit nix-pkgset; };

        lib = lib.filterAttrs (_: lib.isFunction) self.legacyPackages.${system};

        # Only include top level non-broken derivations because nix flake check gets mad
        packages = lib.filterAttrs (
          _: pkg: (lib.isDerivation pkg) && (!(pkg.meta.broken or false))
        ) self.legacyPackages.${system};

        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # nix
              statix.enable = true;
              deadnix.enable = true;
              nil.enable = true;
              nixfmt-rfc-style.enable = true;
              # shell
              # FIXME: not sure I want this, nix hooks are not fun to write with it
              # shellcheck = {
              #   enable = true;
              #   files = "\\.sh$";
              #   types_or = lib.mkForce [ ];
              # };
              # bats.enable = true; # FIXME: fails .envrc
              beautysh = {
                enable = true;
                files = "\\.sh$";
                # entry = lib.mkForce "${lib.getExe perSystemSelf.pkgs.beautysh} -t";
              };
            };
          };
        };

        devShells = {
          default = pkgs.mkShell {
            inherit (selfChecks.pre-commit-check) shellHook;
            buildInputs = selfChecks.pre-commit-check.enabledPackages;
          };
        };
      }
    )
    // {
      # Instantiate pkgset for this flake against an arbitrary nixpkgs base
      mkPkgset = pkgs: pkgs.callPackage ./packages { inherit nix-pkgset; };
    };
}
