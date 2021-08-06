{
  description = ''
    Radeon Open Compute (ROCm) packages for NixOS.
    GPU compute support for AMD GPUs.
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let overlay = import ./default.nix;
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config = {
            rocmTargets = ["gfx803" "gfx900" "gfx906"];
          };
        };
        rocm = import ./pkgs/all-packages.nix self.packages.x86_64-linux pkgs;
    in {
      overlay = final: prev: overlay final prev;
      packages.x86_64-linux = rocm;
    };
}
