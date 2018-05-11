{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

let
  ver = "4.13.0";
  revision = "kfd-roc-1.7.2";
in

buildLinux (args // rec {
  version = "${ver}-${revision}";
  modDirVersion = "${ver}";
  extraMeta.branch = "4.13";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCK-Kernel-Driver";
    rev = "roc-1.7.2";
    sha256 = "1gv3g3hbq4fsw72bicm17v6nk956qgmblfvwmcylw263jcbphpan";
  };
} // (args.argsOverride or {}))
