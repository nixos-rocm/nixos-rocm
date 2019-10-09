# 30_rocm overlay packages modifications
#
# The modifications to the package set are split into two parts,
# changes to the existing package set, which are included in the
# attribute set defined in this file, and new packages expected to be
# non-conflicting or to completely replace underlying packages, which
# are merged in from ./pkgs/all-packages.nix.

defaultTargets: self: super:

{ # Overrides of existing packages go here
} // (import ./pkgs/all-packages.nix defaultTargets self super)
