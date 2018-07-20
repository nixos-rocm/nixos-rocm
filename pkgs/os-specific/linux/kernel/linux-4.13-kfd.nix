{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

let
  ver = "4.13.0";
  revision = "kfd-roc-1.8.2";
in

buildLinux (args // rec {
  version = "${ver}-${revision}";
  modDirVersion = "${ver}";
  extraMeta.branch = "4.13";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCK-Kernel-Driver";
    rev = "roc-1.8.2";
    sha256 = "1shdci50fjz5s6ygfj85n5fz2pj6wfipl5qxbf0xy7j4gxil86xd";
  };
} // (args.argsOverride or {}))
