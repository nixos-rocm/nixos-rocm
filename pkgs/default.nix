# Instantiation of the 30_rocm overlay packages directly on top
# of <nixpkgs>
#
# This is primarily intended for testing out packages in the package
# set while they are being developed.

let
  pkgs = import <nixpkgs> {};
  self = (import ./all-packages.nix) (pkgs // self) pkgs;
in
  self
