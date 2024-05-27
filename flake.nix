{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      });
    in
    {
      overlay = (final: prev: {
        ghcid = final.haskellPackages.callCabal2nix "ghcid" ./. { };
      });
      packages = forAllSystems (system: {
        ghcid = nixpkgsFor.${system}.ghcid;
      });
      defaultPackage = forAllSystems (system: self.packages.${system}.ghcid);
      checks = self.packages;
      devShell = forAllSystems (system:
        let haskellPackages = nixpkgsFor.${system}.haskellPackages;
        in
        haskellPackages.shellFor {
          packages = p: [ self.packages.${system}.ghcid ];
          withHoogle = true;
          buildInputs = with haskellPackages; [
            haskell-language-server
            ghcid
            cabal-install
          ];
        });
    };
}
