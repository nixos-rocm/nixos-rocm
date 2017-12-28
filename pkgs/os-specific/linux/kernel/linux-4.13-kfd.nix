{ stdenv, hostPlatform, path, fetchFromGitHub, perl, buildLinux, ... } @ args:

let
  ver = "4.13.0";
  revision = "kfd-roc-1.7.0";
in

import "${path}/pkgs/os-specific/linux/kernel/generic.nix" (args // rec {
  version = "${ver}-${revision}";
  modDirVersion = "${ver}";
  extraMeta.branch = "4.13";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCK-Kernel-Driver";
    rev = "roc-1.7.0";
    sha256 = "1xqcb5q0s7bcncvh4913hbbp2r9p619s1dc2ppkmihzc512k8lzk";
  };
} // (args.argsOverride or {}))
